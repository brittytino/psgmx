import 'dart:convert';

import 'package:http/http.dart' as http;

/// A user-safe error returned by the PSGMX trusted backend client.
class TrustedApiException implements Exception {
  final String message;
  final int? statusCode;

  const TrustedApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Decodes an object response without ever exposing HTML or parser internals
/// in the student interface.
Map<String, dynamic> decodeTrustedJson(
  http.Response response, {
  String fallbackMessage = 'This service is temporarily unavailable.',
}) {
  final body = response.body.trim();
  final contentType = response.headers['content-type']?.toLowerCase() ?? '';
  final looksLikeHtml = contentType.contains('text/html') ||
      body.startsWith('<!DOCTYPE') ||
      body.startsWith('<html');

  if (looksLikeHtml) {
    throw TrustedApiException(
      'This app is connected to an outdated service address. Update the app or try again shortly.',
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic>? decoded;
  try {
    final value = jsonDecode(body);
    if (value is Map) decoded = Map<String, dynamic>.from(value);
  } on FormatException {
    decoded = null;
  }

  if (decoded == null) {
    throw TrustedApiException(
      fallbackMessage,
      statusCode: response.statusCode,
    );
  }

  if (response.statusCode < 200 || response.statusCode >= 300) {
    final serverMessage = decoded['error']?.toString().trim();
    throw TrustedApiException(
      _statusMessage(response.statusCode, serverMessage, fallbackMessage),
      statusCode: response.statusCode,
    );
  }

  return decoded;
}

String trustedApiErrorMessage(
  Object error, {
  String fallbackMessage = 'This service is temporarily unavailable.',
}) {
  if (error is TrustedApiException) return error.message;
  return fallbackMessage;
}

String _statusMessage(int status, String? serverMessage, String fallback) {
  switch (status) {
    case 401:
      return 'Your session has expired. Sign in again to continue.';
    case 403:
      return serverMessage?.isNotEmpty == true
          ? serverMessage!
          : 'This feature is not available for your account.';
    case 404:
      return 'This feature needs the latest PSGMX app. Please update and try again.';
    case 413:
      return 'That upload is too large. Record a shorter answer and try again.';
    case 429:
      return 'The service is busy right now. Wait a moment and retry.';
    default:
      if (status >= 500) {
        return 'The PSGMX service is recovering. Please try again shortly.';
      }
      return serverMessage?.isNotEmpty == true ? serverMessage! : fallback;
  }
}
