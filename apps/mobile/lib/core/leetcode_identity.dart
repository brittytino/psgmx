class LeetCodeIdentity {
  static final RegExp _usernamePattern = RegExp(r'^[A-Za-z0-9_-]{1,32}$');

  static String normalize(String input) {
    var value = input.trim();
    final uri = Uri.tryParse(value);
    if (uri != null &&
        (uri.host == 'leetcode.com' || uri.host == 'www.leetcode.com')) {
      final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
      if (segments.length >= 2 && segments.first == 'u') {
        value = segments[1];
      } else if (segments.isNotEmpty) {
        value = segments.first;
      }
    }
    return value.trim();
  }

  static bool isValid(String input) => _usernamePattern.hasMatch(normalize(input));

  static String requireValid(String input) {
    final username = normalize(input);
    if (!_usernamePattern.hasMatch(username)) {
      throw const FormatException(
        'Enter a valid LeetCode username or profile URL.',
      );
    }
    return username;
  }
}
