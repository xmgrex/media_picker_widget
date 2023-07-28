import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../media_picker_widget.dart';

class AlbumSelector extends StatelessWidget {
  AlbumSelector({
    required this.onSelect,
    required this.albums,
    required this.panelController,
    required this.decoration,
  });

  final ValueChanged<AssetPathEntity> onSelect;
  final List<AssetPathEntity> albums;
  final PanelController panelController;
  final PickerDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      final albumTiles = albums
          .map((album) => AlbumTile(
                album: album,
                onSelect: () => onSelect(album),
                decoration: decoration,
              ))
          .toList(growable: false);

      return SlidingUpPanel(
        controller: panelController,
        minHeight: 0,
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [],
        maxHeight: constrains.maxHeight,
        panelBuilder: (sc) {
          return ListView.builder(
            controller: sc,
            itemBuilder: (_, index) => albumTiles[index],
            itemCount: albumTiles.length,
          );
        },
      );
    });
  }
}

class AlbumTile extends StatefulWidget {
  AlbumTile({
    required this.album,
    required this.onSelect,
    required this.decoration,
  });

  final AssetPathEntity album;
  final VoidCallback onSelect;
  final PickerDecoration decoration;

  @override
  State<AlbumTile> createState() => _AlbumTileState();
}

class _AlbumTileState extends State<AlbumTile>
    with AutomaticKeepAliveClientMixin {
  Future<Uint8List?> _getAlbumThumb(AssetPathEntity album) async {
    final media = await album.getAssetListPaged(page: 0, size: 1);

    if (media.isNotEmpty) {
      return media[0].thumbnailDataWithSize(ThumbnailSize(80, 80));
    }
    return null;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Uint8List?>(
      future: _getAlbumThumb(widget.album),
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox.shrink(); // or a loading indicator
        } else {
          if (snapshot.data == null) {
            return SizedBox
                .shrink(); // No widget is displayed if media is empty
          } else {
            return _buildAlbumTile(context, snapshot.data!);
          }
        }
      },
    );
  }

  Widget _buildAlbumTile(BuildContext context, Uint8List albumThumb) {
    return Container(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onSelect,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                width: 80,
                height: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    albumThumb,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                widget.album.name,
                style: widget.decoration.albumTextStyle ??
                    TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),
              ),
              SizedBox(
                width: 5,
              ),
              FutureBuilder(
                future: widget.album.assetCountAsync,
                builder: _assetCountBuilder,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _assetCountBuilder(
    BuildContext context,
    AsyncSnapshot<int> snapshot,
  ) {
    return Text(
      '${snapshot.data ?? 0}',
      style: widget.decoration.albumCountTextStyle ??
          TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
    );
  }
}
