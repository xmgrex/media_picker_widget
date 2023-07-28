part of media_picker_widget;

///[HeaderBuilder] is used to build custom header for picker
///[context] is the BuildContext of picker header
///[albumSelector] is the widget that will show the album selector, you can use it to show album selector in your custom header. Use [PickerDecoration] to customize it.
///[completeSelection] is called when selection is done. If you want a button for user to confirm selection, you can use it. It will trigger [MediaPicker.onPicked] callback. Note: If MediaPicker's media count is [MediaCount.single], It won't ask for confirmation.
///[onBack] is the callback when user press back button. It will close album selector if it is open. Else your [MediaPicker.onCancel] callback will be called.
typedef HeaderBuilder = Function(BuildContext context, Widget albumSelector, VoidCallback completeSelection, VoidCallback onBack);

///The MediaPicker widget that will select media files form storage
class MediaPicker extends StatefulWidget {
  ///The MediaPicker constructor that will select media files form storage
  MediaPicker({
    required this.onPicked,
    required this.mediaList,
    this.onCancel,
    this.mediaCount = MediaCount.multiple,
    this.mediaType = MediaType.all,
    this.decoration,
    this.scrollController,
    this.onPicking,
    this.headerBuilder,
    this.maxMediaCount,
    this.maxVideoDuration,
  });

  ///CallBack on image pick is done
  final ValueChanged<List<Media>> onPicked;

  ///Previously selected list of media in your app
  final List<Media> mediaList;

  ///Callback on cancel the picking action
  final VoidCallback? onCancel;

  ///make picker to select multiple or single media file
  final MediaCount mediaCount;

  ///Make picker to select specific type of media, video or image
  final MediaType mediaType;

  ///decorate the UI of picker
  final PickerDecoration? decoration;

  ///assign a scroll controller to Media GridView of Picker
  final ScrollController? scrollController;

  ///CallBack on image picking
  final ValueChanged<List<Media>>? onPicking;

  ///Custom Header Builder
  final HeaderBuilder? headerBuilder;

  final int? maxMediaCount; 

  final Duration? maxVideoDuration;

  @override
  _MediaPickerState createState() => _MediaPickerState();
}

class _MediaPickerState extends State<MediaPicker> {
  late final _decoration = widget.decoration ?? PickerDecoration();

  final _albumController = PanelController();
  final _headerController = GlobalKey<HeaderState>();

  AssetPathEntity? _selectedAlbum;
  late List<MediaViewModel> _selectedMedias = [...MediaConversionService.toMediaViewList(widget.mediaList)];

///_fetchAlbums() is used to fetch all the albums from device storage
  Future<List<AssetPathEntity>> _fetchAlbums() async {
    var type = RequestType.common;
    if (widget.mediaType == MediaType.all) {
      type = RequestType.common;
    } else if (widget.mediaType == MediaType.video) {
      type = RequestType.video;
    } else if (widget.mediaType == MediaType.image) {
      type = RequestType.image;
    }

    final result = await PhotoManager.requestPermissionExtend();
    if (result == PermissionState.authorized ||
        result == PermissionState.limited) {
      return await PhotoManager.getAssetPathList(type: type);
    } else {
      PhotoManager.openSetting();

      return [];
    }
  }

  Future _onMediaTilePressed(MediaViewModel media, List<MediaViewModel> selectedMedias) async {
    _headerController.currentState?.updateSelection(selectedMedias);

    setState(() {
      _selectedMedias = selectedMedias;
    });

    var results = await MediaConversionService.toMediaList(selectedMedias);
    widget.onPicking?.call(results);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: FutureBuilder(
        future: _fetchAlbums(),
        builder: _builder,
      ),
    );
  }

  void handleBackPress() {
    if (_albumController.isPanelOpen) {
      _albumController.close();
    } else {
      widget.onCancel?.call();
    }
  }

  void _onAlbumSelected(AssetPathEntity album) {
    _headerController.currentState?.closeAlbumDrawer();
    setState(() => _selectedAlbum = album);
  }

///_builder() is used to build the UI of picker
  Widget _builder(
    BuildContext context,
    AsyncSnapshot<List<AssetPathEntity>> snapshot,
  ) {
    if (snapshot.hasData) {
      final albums = snapshot.data!;

      if (albums.isEmpty) {
        return NoMedia(text: _decoration.noMedia);
      } else {
        final defaultSelectedAlbum = albums.first;

        Widget header = Header(
          key: _headerController,
          onBack: handleBackPress,
          onDone: (data) async {
            var result = await MediaConversionService.toMediaList(data);
            widget.onPicked(result);
          },
          albumController: _albumController,
          selectedAlbum: _selectedAlbum ?? defaultSelectedAlbum,
          mediaCount: widget.mediaCount,
          decoration: _decoration,
          selectedMedias: _selectedMedias,
          headerBuilder: widget.headerBuilder,
        );

        return Column(
          children: [
            if (_decoration.actionBarPosition == ActionBarPosition.top) header,
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: MediaList(
                      album: _selectedAlbum ?? defaultSelectedAlbum,
                      previousList: _selectedMedias,
                      mediaCount: widget.mediaCount,
                      decoration: _decoration,
                      scrollController: widget.scrollController,
                      onMediaTilePressed: _onMediaTilePressed,
                      maxMediaCount: widget.maxMediaCount,
                      maxVideDuration: widget.maxVideoDuration,
                    ),
                  ),
                  AlbumSelector(
                    panelController: _albumController,
                    albums: albums,
                    decoration: _decoration,
                    onSelect: _onAlbumSelected,
                  ),
                ],
              ),
            ),
            if (_decoration.actionBarPosition == ActionBarPosition.bottom) header,
          ],
        );
      }
    } else {
      return Center(
        child: LoadingWidget(
          decoration: _decoration,
        ),
      );
    }
  }
}

///call this function to capture and get media from camera
void openCamera({
  ///callback when capturing is done
  required ValueChanged<Media> onCapture,
}) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.camera);

  if (pickedFile != null) {
    final converted = Media(
      id: UniqueKey().toString(),
      thumbnail: await pickedFile.readAsBytes(),
      creationTime: DateTime.now(),
      mediaByte: await pickedFile.readAsBytes(),
      title: 'capturedImage',
    );

    onCapture(converted);
  }
}
