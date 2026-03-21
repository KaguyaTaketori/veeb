import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MlKitOcrService {
  final _recognizer = TextRecognizer(
    script: TextRecognitionScript.japanese,
  );

  Future<String> recognizeFromFile(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(inputImage);
    return result.text;
  }

  Future<String> recognizeFromBytes(File file) async {
    final inputImage = InputImage.fromFile(file);
    final result = await _recognizer.processImage(inputImage);
    return result.text;
  }

  void dispose() => _recognizer.close();
}