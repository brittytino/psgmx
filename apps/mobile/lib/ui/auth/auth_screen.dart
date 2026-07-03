import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/user_provider.dart';
import '../../core/theme/app_theme.dart';


import 'package:pinput/pinput.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  bool _isOtpSent = false;
  bool _isLoading = false;

  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      final email = _emailController.text.trim();
      setState(() {
        _isEmailValid = email.isNotEmpty && email.endsWith('@psgtech.ac.in');
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSubmit() async {
    final email = _emailController.text.trim();
    if (!_isEmailValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid @psgtech.ac.in email')));
      return;
    }
    
    setState(() {
      _isLoading = true;

    });

    try {
      final success = await context.read<UserProvider>().requestOtp(email: email);
      if (success) {
        setState(() {
          _isOtpSent = true;
          _isLoading = false;
        });
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _otpFocusNode.requestFocus();
        });
      }
    } catch (e) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception:', '').trim())));
        _isLoading = false;
      });
    }
  }

  Future<void> _handleOtpSubmit() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid 6-digit OTP')));
      return;
    }

    setState(() {
      _isLoading = true;

    });

    try {
      await context.read<UserProvider>().verifyOtp(
        email: _emailController.text.trim(),
        otp: otp,
      );
      // Navigation handled by router
    } catch (e) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception:', '').trim())));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
                    onPressed: () {
                      if (_isOtpSent) {
                        setState(() => _isOtpSent = false);
                      } else {
                        context.go('/onboarding');
                      }
                    },
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      4,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 24,
                        height: 4,
                        decoration: BoxDecoration(
                          color: index == 0 ? AppTheme.accentCoral : theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
              const SizedBox(height: 24),
              
              Text(
                'Verify it\'s you',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: !_isOtpSent ? 'We\'ll send a 6-digit code to your\n' : 'We\'ve sent a 6-digit code to your\n'),
                    const TextSpan(text: 'PSG Tech', style: TextStyle(color: AppTheme.accentCoral, fontWeight: FontWeight.w600)),
                    const TextSpan(text: ' email address.'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Illustration
              Center(
                child: Image.asset(
                  'assets/images/onboarding/envelope.png',
                  width: 200,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              
              // Dynamic Input Area
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: !_isOtpSent
                    ? Column(
                        key: const ValueKey('email_input'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Your PSG Tech Email',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.inter(fontSize: 11),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(LucideIcons.mail, color: Colors.grey),
                              suffixIcon: _isEmailValid ? const Icon(LucideIcons.checkCircle2, color: Colors.green) : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.dividerColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.accentCoral, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onSubmitted: (_) {
                              if (!_isOtpSent && _isEmailValid) {
                                _handleEmailSubmit();
                              }
                            },
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('otp_input'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Enter 6-digit code',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Pinput(
                            length: 6,
                            controller: _otpController,
                            focusNode: _otpFocusNode,
                            autofocus: true,
                            defaultPinTheme: PinTheme(
                              width: 48,
                              height: 56,
                              textStyle: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.dividerColor),
                              ),
                            ),
                            focusedPinTheme: PinTheme(
                              width: 48,
                              height: 56,
                              textStyle: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.accentCoral, width: 2),
                              ),
                            ),
                            onCompleted: (val) {
                              if (!_isLoading) {
                                _handleOtpSubmit();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Code sent to ${_emailController.text}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.clock, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Resend code in ',
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                '00:45',
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.accentCoral, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 48),
              
              // Mascot & Shield
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.asset(
                    'assets/images/onboarding/SmilingMascot.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.illusGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.illusGold.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.shieldCheck, color: AppTheme.illusGold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'We keep your account secure and private.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: theme.textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : (_isOtpSent ? _handleOtpSubmit : _handleEmailSubmit),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentCoral,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isOtpSent ? 'Verify & Continue' : 'Get Code',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.arrowRight, size: 16),
                        ],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
