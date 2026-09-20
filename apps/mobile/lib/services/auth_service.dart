import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import 'supabase_service.dart';
import '../models/app_user.dart';
import '../core/logical_identity.dart';

/// AuthService: Secure OTP-based authentication using Supabase Auth
///
/// FLOW:
/// 1. User enters an approved personal or college email
/// 2. Trusted backend checks the private roster and sends the OTP
/// 3. OTP sent to email via Supabase
/// 4. User enters OTP -> Session created
/// 5. If new user, profile created from whitelist automatically
class AuthService {
  final SupabaseService _supabaseService;

  AuthService(this._supabaseService);

  /// Get current authenticated user
  User? get currentUser => _supabaseService.currentUser;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabaseService.authStateChanges;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get current session
  Session? get currentSession => _supabaseService.auth.currentSession;

  /// STEP 1: VALIDATE EMAIL & SEND OTP (Resend Broker Only)
  Future<bool> sendOtpToEmail(String email) async {
    try {
      email = email.trim().toLowerCase();
      if (!_looksLikeEmail(email)) {
        throw Exception('Enter a valid email address.');
      }
      debugPrint('[AuthService] Requesting Resend OTP for: $email');

      var targetUrl =
          Uri.parse('${SupabaseConfig.appApiUrl}/api/auth/request-otp');
      var response = await http
          .post(
            targetUrl,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));

      // Handle HTTP Redirects (301, 302, 307, 308)
      if (response.statusCode >= 300 &&
          response.statusCode < 400 &&
          response.headers['location'] != null) {
        final redirectUrl = Uri.parse(response.headers['location']!);
        debugPrint('[AuthService] Following redirect to: $redirectUrl');
        response = await http
            .post(
              redirectUrl,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({'email': email}),
            )
            .timeout(const Duration(seconds: 15));
      }

      final bodyStr = response.body;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint(
            '[AuthService] ✅ OTP issued via Resend API (notifications@psgmx.tech)');
        return true;
      }

      if (bodyStr.isNotEmpty) {
        try {
          final payload = jsonDecode(bodyStr) as Map<String, dynamic>;
          if (payload['error'] != null) {
            throw Exception(payload['error']);
          }
        } on FormatException {
          // HTML or unexpected non-JSON response from server
        }
      }

      throw Exception(
          'Could not reach the Resend login service (${response.statusCode}). Please try again.');
    } on AuthException catch (e) {
      if (e.message.contains('rate limit')) {
        throw Exception('Too many requests. Please wait a moment.');
      }
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[AuthService] Resend OTP error: $e');
      if (e is Exception) rethrow;
      throw Exception(
          'Could not send verification code via Resend. Please try again.');
    }
  }

  bool _looksLikeEmail(String email) {
    return RegExp(
          r"^[A-Za-z0-9.!#$%&'*+/=?^_{}|~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$",
        ).hasMatch(email) &&
        email.length <= 254;
  }

  /// STEP 2: VERIFY OTP through the trusted backend so lockout policy is
  /// shared across devices and cannot be bypassed by restarting the app.
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      email = email.trim().toLowerCase();

      if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
        throw 'OTP must be 6 digits';
      }

      debugPrint('[AuthService] Verifying OTP');

      final response = await http
          .post(
            Uri.parse('${SupabaseConfig.appApiUrl}/api/auth/verify'),
            headers: const {
              'Content-Type': 'application/json',
              'x-psgmx-client': 'mobile',
            },
            body: jsonEncode({'email': email, 'token': otp}),
          )
          .timeout(const Duration(seconds: 20));
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            payload['error'] ?? 'Verification failed. Please try again.');
      }
      final session = payload['session'];
      if (session is! Map ||
          session['refresh_token'] is! String ||
          session['access_token'] is! String) {
        throw Exception(
            'The secure session could not be established. Please try again.');
      }
      final authResponse = await _supabaseService.auth.setSession(
        session['refresh_token'] as String,
        accessToken: session['access_token'] as String,
      );
      if (authResponse.session == null || authResponse.user == null) {
        throw Exception('Verification failed. Please try again.');
      }

      debugPrint('[AuthService] ✅ OTP verified successfully');
      debugPrint('[AuthService] User authenticated');
    } catch (e) {
      debugPrint('[AuthService] Unexpected error: $e');
      throw e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Fetch user profile
  Future<AppUser?> getUserProfile(String userId) async {
    try {
      // `userId` is the auth identity. The RPC resolves it to the one logical
      // student profile shared by personal and college email identities.
      final rows = await _supabaseService.client.rpc('get_my_profile');
      final raw = rows is List && rows.isNotEmpty ? rows.first : null;
      Map<String, dynamic>? response =
          raw is Map ? Map<String, dynamic>.from(raw) : null;

      // Compatibility fallback during the staged migration window.
      response ??= await _supabaseService.client
          .from('users')
          .select('*, batches(status)')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint(
            '[AuthService] ❌ Profile could not be found or created for user ID: $userId');
        return null;
      }

      if (response['batch_id'] != null && response['batches'] == null) {
        final batch = await _supabaseService.client
            .from('batches')
            .select('status')
            .eq('id', response['batch_id'])
            .maybeSingle();
        response['batches'] = batch;
      }
      debugPrint('[AuthService] Profile loaded');
      return AppUser.fromJson(response);
    } catch (e) {
      debugPrint('[AuthService] ❌ Error fetching profile: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    LogicalIdentity.clear();
    await _supabaseService.auth.signOut();
  }
}
