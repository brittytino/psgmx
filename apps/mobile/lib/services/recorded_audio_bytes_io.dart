import 'dart:io';

Future<List<int>> readRecordedAudio(String path) => File(path).readAsBytes();

Future<void> deleteRecordedAudio(String? path) async {
  if (path == null || path.isEmpty) return;
  final file = File(path);
  if (await file.exists()) await file.delete();
}
