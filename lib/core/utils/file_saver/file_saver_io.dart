import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<void> saveFileContent(String content, String fileName) async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Save Backup',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(content);
    }
  } else {
    // Mobile fallback (Android/iOS)
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(content);
  }
}
