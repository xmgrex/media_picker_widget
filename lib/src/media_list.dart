import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:photo_manager/photo_manager.dart';

import '../media_picker_widget.dart';
import 'media_view_model.dart';
import 'widgets/media_tile.dart';

class MediaList extends StatefulWidget {
  MediaList({
    required this.album,
    required this.previousList,
    this.mediaCount,
    required this.decoration,
    this.scrollController,
    required this.onMediaTilePressed,
    this.maxMediaCount,
    this.maxVideDuration,
  });

  final AssetPathEntity album;
  final List<MediaViewModel> previousList;
  final MediaCount? mediaCount;
  final PickerDecoration decoration;
  final ScrollController? scrollController;
  final Function(MediaViewModel media, List<MediaViewModel> selectedMedias)
      onMediaTilePressed;
  final int? maxMediaCount;
  final Duration? maxVideDuration;

  @override
  _MediaListState createState() => _MediaListState();
}

class _MediaListState extends State<MediaList> {
  final List<MediaViewModel> _mediaList = [];
  var _currentPage = 0;
  late var _lastPage = _currentPage;
  late AssetPathEntity _album = widget.album;
  List<MediaViewModel> _selectedMedias = [];

  @override
  void initState() {
    _selectedMedias = [...widget.previousList];
    _fetchNewMedia(refresh: true);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MediaList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _album = widget.album;
    final isRefresh = oldWidget.album.id != _album.id;
    if (isRefresh) {
      _fetchNewMedia(
        refresh: isRefresh,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scroll) {
        _handleScrollEvent(scroll);
        return true;
      },
      child: GridView.builder(
        controller: widget.scrollController,
        itemCount: _mediaList.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.decoration.columnCount,
        ),
        itemBuilder: (_, index) => MediaTile(
          media: _mediaList[index],
          onThumbnailLoad: (thumb) {
            _mediaList[index].thumbnail = thumb;
            setState(() {});
          },
          onSelected: _onMediaTileSelected,
          isSelected: _isPreviouslySelected(_mediaList[index]),
          selectionIndex: _getSelectionIndex(_mediaList[index]),
          decoration: widget.decoration,
          isDisable: widget.maxMediaCount != null &&
              _selectedMedias.length >= widget.maxMediaCount!,
        ),
      ),
    );
  }

  ///_handleScrollEvent handles the scroll event of the media list
  void _handleScrollEvent(ScrollNotification scroll) {
    if (scroll.metrics.pixels / scroll.metrics.maxScrollExtent > 0.33) {
      if (_currentPage != _lastPage) {
        _fetchNewMedia(
          refresh: false,
        );
      }
    }
  }

  ///_fetchNewMedia fetches new media from the album
  void _fetchNewMedia({required bool refresh}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _mediaList.clear();
      });
    }
    _lastPage = _currentPage;
    final result = await PhotoManager.requestPermissionExtend();
    if (result == PermissionState.authorized ||
        result == PermissionState.limited) {
      final newAssets = await _album.getAssetListPaged(
        page: _currentPage,
        size: 60,
      );
      if (newAssets.isEmpty) {
        return;
      }
      List<MediaViewModel> newMedias = [];

      // var tasks = <Future>[];
      for (var asset in newAssets) {
        // Future<dynamic> task = Future(() async {
        // });
        // tasks.add(task);
        var media = _toMediaViewModel(asset);
        newMedias.add(media);
      }
      // await Future.wait(tasks);

      setState(() {
        _mediaList.addAll(newMedias);
        _currentPage++;
      });
    } else {
      PhotoManager.openSetting();
    }
  }

  ///_isPreviouslySelected returns true if the media is already selected
  bool _isPreviouslySelected(MediaViewModel media) {
    return _selectedMedias.any((element) => element.id == media.id);
  }

  ///_getSelectionIndex returns the index of the media in the selectedMedias list
  int? _getSelectionIndex(MediaViewModel media) {
    var index = _selectedMedias.indexWhere((element) => element.id == media.id);
    if (index == -1) return null;
    return index + 1;
  }

  ///* onMediaTileSelected is called when a media tile is selected
  void _onMediaTileSelected(bool isSelected, MediaViewModel mediaModel) async {
    if (widget.mediaCount == MediaCount.single) {
      _selectedMedias = [mediaModel];
    } else {
      if (isSelected) {
        ///* maxMediaCount is the maximum number of media that can be selected
        if (widget.maxMediaCount != null &&
            _selectedMedias.length >= widget.maxMediaCount!) {
          return;
        }

        ///* maxVideDuration is the maximum duration of video that can be selected
        if (mediaModel.videoDuration != null &&
            widget.maxVideDuration != null &&
            mediaModel.videoDuration! > widget.maxVideDuration!) {
          Fluttertoast.showToast(
              msg: '動画は${widget.maxVideDuration!.inSeconds}秒以下のみ選択可能です。',
              gravity: ToastGravity.BOTTOM);
          return;
        }
        setState(() => _selectedMedias.add(mediaModel));
      } else {
        setState(() => _selectedMedias
            .removeWhere((_media) => _media.id == mediaModel.id));
      }
    }
    widget.onMediaTilePressed(mediaModel, _selectedMedias);
  }

  ///_toMediaViewModel converts an AssetEntity to MediaViewModel
  static MediaViewModel _toMediaViewModel(AssetEntity entity) {
    var mediaType = MediaType.all;
    if (entity.type == AssetType.video) mediaType = MediaType.video;
    if (entity.type == AssetType.image) mediaType = MediaType.image;
    return MediaViewModel(
      id: entity.id,
      thumbnailAsync: entity.thumbnailDataWithSize(ThumbnailSize(200, 200)),
      type: mediaType,
      thumbnail: null,
      videoDuration:
          entity.type == AssetType.video ? entity.videoDuration : null,
    );
  }
}
