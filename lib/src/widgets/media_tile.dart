import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../media_picker_widget.dart';
import '../media_view_model.dart';
import 'loading_widget.dart';

class MediaTile extends StatelessWidget {
  MediaTile({
    Key? key,
    required this.media,
    required this.onSelected,
    this.onThumbnailLoad,
    this.isSelected = false,
    this.selectionIndex,
    required this.decoration,
    this.isDisable = false,
  }) : super(key: key);

  final MediaViewModel media;
  final Function(bool isSelected, MediaViewModel media) onSelected;
  final bool isSelected;
  final PickerDecoration decoration;
  final ValueChanged<Uint8List?>? onThumbnailLoad;
  final int? selectionIndex;
  final bool isDisable;

  final Duration _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    var loadThumb = Future<Uint8List?>(() async {
      var thumb = await media.thumbnailAsync;
      onThumbnailLoad?.call(thumb);
      return thumb;
    });

    return FutureBuilder<Uint8List?>(
        future: loadThumb,
        builder: (context, snapshot) {
          if (snapshot.hasError) return SizedBox();
          if (!snapshot.hasData)
            return LoadingWidget(
              decoration: decoration,
            );
          return Padding(
            padding: const EdgeInsets.all(0.5),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? decoration.selectedColor
                      : Colors.transparent,
                  width: isSelected ? 2 : 0,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: media.thumbnail != null
                        ? GestureDetector(
                            onTap: () => onSelected(!isSelected, media),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRect(
                                    child: ImageFiltered(
                                      imageFilter: ImageFilter.blur(
                                        sigmaX: isSelected
                                            ? decoration.blurStrength
                                            : 0,
                                        sigmaY: isSelected
                                            ? decoration.blurStrength
                                            : 0,
                                      ),
                                      child: AnimatedScale(
                                        duration: _duration,
                                        scale: isSelected
                                            ? decoration.scaleAmount
                                            : 1,
                                        child: Image.memory(
                                          media.thumbnail!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: AnimatedOpacity(
                                    opacity: isSelected || isDisable ? 1 : 0,
                                    curve: Curves.easeOut,
                                    duration: _duration,
                                    child: ClipRect(
                                      child: Container(
                                        color: isSelected || isDisable
                                            ? decoration.disableColor
                                            : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                                if (media.type == MediaType.video)
                                  if (decoration.videoDurationBuilder == null)
                                    Align(
                                        alignment: Alignment.bottomRight,
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Text(
                                            _printDuration(media.videoDuration),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ))
                                  else
                                    decoration.videoDurationBuilder!(
                                      context,
                                      _printDuration(media.videoDuration),
                                    ),
                              ],
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.grey.shade400,
                              size: 40,
                            ),
                          ),
                  ),
                  if (isSelected)
                    decoration.counterBuilder?.call(context, selectionIndex) ??
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(5),
                                child: selectionIndex == null
                                    ? Icon(
                                        Icons.done,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : Text(
                                        selectionIndex.toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )),
                          ),
                        ),
                ],
              ),
            ),
          );
        });
  }

  String _printDuration(Duration? duration) {
    if (duration == null) return "";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours == 0) return "$twoDigitMinutes:$twoDigitSeconds";
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
