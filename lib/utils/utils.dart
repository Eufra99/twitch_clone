import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String content) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(content),
  ));
}

Future<Uint8List?> pickImage() async {
  FilePickerResult? pickImage =
      await FilePicker.platform.pickFiles(type: FileType.image);
  if (pickImage != null) {
    if (kIsWeb) {
      return pickImage.files.single.bytes;
    }

    return await File(pickImage.files.single.path!).readAsBytes();
  }
  return null;
}
