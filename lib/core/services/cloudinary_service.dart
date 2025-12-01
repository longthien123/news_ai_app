import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  final CloudinaryPublic cloudinary;

  CloudinaryService({
    required String cloudName,
    required String uploadPreset,
  }) : cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);

  Future<String> uploadImage(XFile file) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image to Cloudinary: $e');
    }
  }
}
