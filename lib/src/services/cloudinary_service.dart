
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:file_picker/file_picker.dart';

class CloudinaryService {
  static const String _cloudName = 'doxmvuss9';
  static const String _uploadPreset = 'presentsir';

  final CloudinaryPublic _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);

  Future<String?> uploadFile({required PlatformFile file, String folder = 'assignments'}) async {
    try {
        CloudinaryResponse response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(file.path!, folder: folder, resourceType: CloudinaryResourceType.Auto),
        );
        return response.secureUrl;
    } catch (e) {
      print('Cloudinary Upload Error: $e');
      return null;
    }
  }
}

final cloudinaryServiceProvider = CloudinaryService();
