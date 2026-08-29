import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../features/bidding/presentation/live_auction_screen.dart';
import '../../listings/data/listing_repository.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.controller,
    this.onAuthenticated,
  });

  final AuthController controller;
  /// If provided, called instead of the default post-login navigation.
  /// Use this when LoginScreen is pushed from another screen that handles
  /// navigation itself (e.g. ListingDetailScreen).
  final VoidCallback? onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AppLocalizations _l10n;

  bool _checking = true;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

  @override
  void initState() {
    super.initState();
    _checkStoredToken();
  }

  Future<void> _checkStoredToken() async {
    // When pushed from another screen (onAuthenticated != null), don't
    // auto-navigate on an existing session — the caller manages that flow.
    if (widget.onAuthenticated != null) {
      setState(() => _checking = false);
      return;
    }
    final alreadyLoggedIn = await widget.controller.initialize();
    if (!mounted) return;
    if (alreadyLoggedIn) {
      _goToAuction();
      return;
    }
    setState(() => _checking = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.controller.login(
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!();
      } else {
        _goToAuction();
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } on SocketException {
      setState(() => _error = _l10n.couldNotReachServer);
    } catch (_) {
      setState(() => _error = _l10n.somethingWentWrongTryAgain);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _demoListingId = '5252fa11-0e99-4863-a926-b15b530dadff';

  Future<void> _goToAuction() async {
    // This is a dev/QA shortcut that jumps straight into a fixed demo
    // listing's auction room after login, bypassing normal browse ->
    // detail navigation. It used to hand LiveAuctionScreen a hardcoded
    // placeholder title/photo; now it fetches the real listing so this
    // shortcut shows genuine data too, same as the normal flow.
    String? title;
    String? categoryName;
    String? imageUrl;
    try {
      final detail = await ListingRepository(host: AppConfig.host).fetchDetail(
        _demoListingId,
        token: widget.controller.token,
      );
      title = detail.title;
      categoryName = detail.category.name;
      imageUrl = detail.imageUrls.isNotEmpty ? detail.imageUrls.first : null;
    } catch (_) {
      // Listing may not exist (e.g. fresh DB before seeding) — fall back
      // to a generic label rather than crashing this dev shortcut.
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LiveAuctionScreen(
          listingId: _demoListingId,
          authToken: widget.controller.token!,
          myBidderLabel:
              widget.controller.username ?? widget.controller.bidderNumber!,
          myBidderNumber: widget.controller.bidderNumber!,
          listingTitle: title ?? 'Live Auction',
          categoryName: categoryName ?? '',
          listingImageUrl: imageUrl,
          host: AppConfig.host,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 48),
                  _buildField(
                    controller: _phoneController,
                    label: _l10n.phoneNumber,
                    hint: '12345678',
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? _l10n.required : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _passwordController,
                    label: _l10n.password,
                    obscure: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.neutralGray,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? _l10n.required : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBanner(message: _error!),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.textLight,
                              ),
                            )
                          : Text(_l10n.signIn),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Text(
          'مزاد',
          style: AppTypography.title.copyWith(
            fontSize: 42,
            color: AppColors.primaryBlue,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'MAZAD',
          style: AppTypography.label.copyWith(
            fontSize: 13,
            color: AppColors.neutralGray,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: AppTypography.body.copyWith(color: AppColors.neutralDark),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        labelStyle: AppTypography.caption.copyWith(color: AppColors.neutralGray),
        hintStyle: AppTypography.caption.copyWith(color: AppColors.neutralGray),
        filled: true,
        fillColor: AppColors.surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _l10n.dontHaveAccount,
          style: AppTypography.caption.copyWith(color: AppColors.neutralGray),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegisterScreen(
                controller: widget.controller,
                onAuthenticated: widget.onAuthenticated,
              ),
            ),
          ),
          child: Text(
            _l10n.register,
            style: AppTypography.caption.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
