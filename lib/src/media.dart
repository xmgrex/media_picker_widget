part of media_picker_widget;

///This class will contain the necessary data of selected media
class Media {
  ///File saved on local storage
  final File? file;

  ///Unique id to identify
  final String id;

  ///A low resolution image to show as preview
  final Uint8List? thumbnail;

  ///The image file in bytes format
  final Uint8List? mediaByte;

  ///Image Dimensions
  final Size? size;

  ///Creation time of the media file on local storage
  final DateTime? creationTime;

  ///Last modified time of the media file on local storage
  final DateTime? modifiedTime;

  ///media name or title
  final String? title;

  ///latitude of the media file
  final double? latitude;

  ///longitude of the media file
  final double? longitude;

  ///Type of the media, Image/Video
  final MediaType? mediaType;

  ///Duration of the video
  final Duration? videoDuration;

  ///Index of selected image
  final int? index;

  Media({
    required this.id,
    this.file,
    this.thumbnail,
    this.mediaByte,
    this.size,
    this.creationTime,
    this.title,
    this.mediaType,
    this.videoDuration,
    this.modifiedTime,
    this.latitude,
    this.longitude,
    this.index,
  });

  // copyWith
  Media copyWith({
    String? id,
    File? file,
    Uint8List? thumbnail,
    Uint8List? mediaByte,
    Size? size,
    DateTime? creationTime,
    DateTime? modifiedTime,
    String? title,
    double? latitude,
    double? longitude,
    MediaType? mediaType,
    Duration? videoDuration,
    int? index,
  }) {
    return Media(
      id: id ?? this.id,
      file: file ?? this.file,
      thumbnail: thumbnail ?? this.thumbnail,
      mediaByte: mediaByte ?? this.mediaByte,
      size: size ?? this.size,
      creationTime: creationTime ?? this.creationTime,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      title: title ?? this.title,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mediaType: mediaType ?? this.mediaType,
      videoDuration: videoDuration ?? this.videoDuration,
      index: index ?? this.index,
    );
  }
}
