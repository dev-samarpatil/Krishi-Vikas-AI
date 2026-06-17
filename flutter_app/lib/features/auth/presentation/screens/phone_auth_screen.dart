import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:krishi_vikas_ai/l10n/app_localizations.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/supabase_client.dart';

/// Phone auth screen — OTP-based login via Supabase Auth.
/// Flow: Enter phone → Get OTP → Verify → JWT stored → proceed.
class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  Timer? _resendTimer;
  int _resendSeconds = 60;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendSeconds = 60;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _errorMessage = l10n.somethingWentWrong); // Or generic invalid phone msg
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseClientService.instance.client.auth.signInWithOtp(
        phone: '+91$phone',
      );
      
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
      _startResendTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.somethingWentWrong;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    final phone = _phoneController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (otp.length != 6) {
      setState(() => _errorMessage = l10n.invalidOtp);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await SupabaseClientService.instance.client.auth.verifyOTP(
        type: OtpType.sms,
        token: otp,
        phone: '+91$phone',
      );

      if (res.session != null) {
        final box = Hive.box(AppConstants.settingsBox);
        await box.put(AppConstants.jwtTokenKey, res.session!.accessToken);
      }

      if (!mounted) return;
      context.go(AppRoutes.farmSetup);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.invalidOtp;
      });
    }
  }

  void _skipAuth() {
    context.go(AppRoutes.farmSetup);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.login),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacingXl),

              Text(
                _otpSent ? l10n.verifyOtp : l10n.enterPhoneNumber,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: AppTheme.spacingSm),

              Text(
                _otpSent
                    ? l10n.otpSent(_phoneController.text)
                    : l10n.weWillSendOtp,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              if (!_otpSent) ...[
                // Phone input
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumber,
                    prefixText: '+91 ',
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
              ] else ...[
                // OTP input
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.enterOtp,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppTheme.errorRed,
                    fontSize: 14,
                  ),
                ),
              ],

              const SizedBox(height: AppTheme.spacingLg),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_otpSent ? _verifyOtp : _sendOtp),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_otpSent ? l10n.verifyOtp : l10n.getOtp),
                ),
              ),

              if (_otpSent) ...[
                const SizedBox(height: AppTheme.spacingMd),
                Center(
                  child: TextButton(
                    onPressed: _resendSeconds == 0 && !_isLoading ? _sendOtp : null,
                    child: Text(
                      _resendSeconds > 0
                          ? '${l10n.resendOtp} ($_resendSeconds s)'
                          : l10n.resendOtp,
                    ),
                  ),
                ),
              ],

              if (!_otpSent && !_isLoading) ...[
                const SizedBox(height: AppTheme.spacingXl),
                Center(
                  child: TextButton(
                    onPressed: _skipAuth,
                    child: Text(
                      l10n.continueWithoutAccount,
                      style: const TextStyle(color: AppTheme.primaryGreen),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

