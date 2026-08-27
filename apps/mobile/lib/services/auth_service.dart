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

  /// STEP 1: VALIDATE EMAIL & SEND OTP
  Future<bool> sendOtpToEmail(String email) async {
    try {
      email = email.trim().toLowerCase();
      if (!_looksLikeEmail(email)) {
        throw Exception('Enter a valid email address.');
      }
      debugPrint('[AuthService] Sending OTP to: $email');

      final response = await http
          .post(
            Uri.parse('${SupabaseConfig.appApiUrl}/api/auth/request-otp'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 20));

      final payload = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(payload['error'] ?? 'The code could not be sent.');
      }

      debugPrint('[AuthService] OTP request accepted');
      return true;
    } on FormatException {
      throw Exception('The login service returned an invalid response.');
    } on AuthException catch (e) {
      if (e.message.contains('rate limit')) {
        throw Exception('Too many requests. Please wait a moment.');
      }
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[AuthService] OTP request error: $e');
      if (e is Exception) rethrow;
      throw Exception('Could not reach the login service. Try again.');
    }
  }

  bool _looksLikeEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) &&
        email.length <= 254;
  }

  /// STEP 2: VERIFY OTP (Magic Link Token)
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      email = email.trim().toLowerCase();

      if (otp.length != 6) {
        throw 'OTP must be 6 digits';
      }

      debugPrint('[AuthService] Verifying OTP');

      final response = await _supabaseService.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (response.session == null) {
        throw 'Verification failed. Please try again.';
      }

      final user = response.user;
      if (user == null) {
        throw 'User data not available.';
      }

      debugPrint('[AuthService] ✅ OTP verified successfully');
      debugPrint('[AuthService] User authenticated');
    } on AuthException catch (e) {
      debugPrint('[AuthService] Auth error: ${e.message}');
      if (e.message.contains('Invalid') || e.message.contains('expired')) {
        throw 'Invalid or expired OTP. Please request a new one.';
      }
      throw e.message;
    } catch (e) {
      debugPrint('[AuthService] Unexpected error: $e');
      throw e.toString();
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
