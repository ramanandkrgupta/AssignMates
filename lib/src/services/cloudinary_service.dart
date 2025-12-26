import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:file_picker/file_picker.dart';

class CloudinaryService {
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    dotenv.env['CLOUDINARY_CLOUD_NAME']!,
    dotenv.env['CLOUDINARY_UPLOAD_PRESET']!,
    cache: false
  );

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


