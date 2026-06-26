import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class MediaPickerHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick an image from Camera or Gallery
  static Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick a document (PDF, DOC, DOCX, Images)
  static Future<File?> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error picking document: $e');
      return null;
    }
  }
}
