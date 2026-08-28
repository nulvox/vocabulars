import 'dart:io';

Future<String> readTextFile(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw Exception('File not found: $path');
  }
  return file.readAsString();
}
