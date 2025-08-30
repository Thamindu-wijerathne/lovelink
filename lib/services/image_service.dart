import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final cloudinary = CloudinaryPublic('dbleqzcp4', 'my_present', cache: false);

  Future<XFile?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    print("Image Selceted");
    return pickedFile;
  }

  Future<String?> uploadImage(XFile? pickedFile) async {
    if (pickedFile != null) {
      try {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            pickedFile.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        return response.secureUrl; // The URL you can store in your chat message
      } on CloudinaryException catch (e) {
        print(e.message);
        return null;
      }
    }
    return null;
  }
}
