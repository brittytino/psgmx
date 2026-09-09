import 'package:http/http.dart' as http;

Future<List<int>> readRecordedAudio(String path) async {
  final response = await http.get(Uri.parse(path));
  if (response.statusCode != 200) {
    throw Exception('The browser recording could not be read.');
  }
  return response.bodyBytes;
}

Future<void> deleteRecordedAudio(String? path) async {}
