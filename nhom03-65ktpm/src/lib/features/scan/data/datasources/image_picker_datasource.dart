import 'package:image_picker/image_picker.dart';

/// Nguồn cấp dữ liệu hình ảnh từ phần cứng thiết bị.
abstract interface class ImagePickerDataSource {
  /// Lấy ảnh từ nguồn chỉ định ([ImageSource.camera] hoặc [ImageSource.gallery]).
  Future<XFile?> pickImage(ImageSource source);
}

/// Hiện thực sử dụng package `image_picker`.
class ImagePickerDataSourceImpl implements ImagePickerDataSource {
  ImagePickerDataSourceImpl([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<XFile?> pickImage(ImageSource source) {
    return _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2048,
      maxHeight: 2048,
    );
  }
}
