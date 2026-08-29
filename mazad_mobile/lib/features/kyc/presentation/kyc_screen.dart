import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/kyc_repository.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key, required this.controller});
  final AuthController controller;

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  bool _loadingStatus = true;
  String _status = 'none'; // none | pending | approved | rejected
  String _rejectionReason = '';

  File? _idFront;
  File? _idBack;
  File? _selfie;
  bool _submitting = false;
  String? _submitError;

  late final KycRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = KycRepository(host: AppConfig.host, token: widget.controller.token!);
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loadingStatus = true);
    try {
      final data = await _repo.fetchStatus();
      if (mounted) {
        setState(() {
          _status = data['status'] as String? ?? 'none';
          _rejectionReason = data['rejection_reason'] as String? ?? '';
        });
      }
    } catch (_) {
      // Leave status as 'none' so the user can still attempt a submission.
    } finally {
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  Future<void> _pickImage(String field) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(l10n.camera),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.gallery),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() {
      final file = File(picked.path);
      if (field == 'id_front') {
        _idFront = file;
      } else if (field == 'id_back') {
        _idBack = file;
      } else {
        _selfie = file;
      }
    });
  }

  Future<void> _submit() async {
    if (_idFront == null || _idBack == null || _selfie == null) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await _repo.submit(idFront: _idFront!, idBack: _idBack!, selfie: _selfie!);
      if (!mounted) return;
      setState(() {
        _status = 'pending';
        _idFront = null;
        _idBack = null;
        _selfie = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _submitError = e.message);
    } catch (_) {
      if (mounted) setState(() => _submitError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.kycTitle,
            style: AppTypography.body.copyWith(color: AppColors.neutralDark)),
      ),
      body: _loadingStatus
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _StatusBanner(status: _status, rejectionReason: _rejectionReason),
                if (_status != 'approved' && _status != 'pending') ...[
                  const SizedBox(height: 24),
                  _ImageTile(
                    label: l10n.idFrontLabel,
                    hint: l10n.idFrontHint,
                    file: _idFront,
                    onTap: () => _pickImage('id_front'),
                  ),
                  const SizedBox(height: 12),
                  _ImageTile(
                    label: l10n.idBackLabel,
                    hint: l10n.idBackHint,
                    file: _idBack,
                    onTap: () => _pickImage('id_back'),
                  ),
                  const SizedBox(height: 12),
                  _ImageTile(
                    label: l10n.selfieLabel,
                    hint: l10n.selfieHint,
                    file: _selfie,
                    onTap: () => _pickImage('selfie'),
                  ),
                  if (_submitError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_submitError!,
                          style: AppTypography.caption.copyWith(color: AppColors.error)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _idFront != null &&
                              _idBack != null &&
                              _selfie != null &&
                              !_submitting
                          ? _submit
                          : null,
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l10n.submitForReview),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, required this.rejectionReason});
  final String status;
  final String rejectionReason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, title, subtitle, bg, fg) = switch (status) {
      'pending' => (
          Icons.hourglass_top_rounded,
          l10n.kycPendingTitle,
          l10n.kycPendingSubtitle,
          AppColors.warning.withValues(alpha: 0.12),
          AppColors.warning,
        ),
      'approved' => (
          Icons.verified_user_outlined,
          l10n.kycApprovedTitle,
          l10n.kycApprovedSubtitle,
          AppColors.success.withValues(alpha: 0.12),
          AppColors.success,
        ),
      'rejected' => (
          Icons.cancel_outlined,
          l10n.kycRejectedTitle,
          rejectionReason.isNotEmpty
              ? rejectionReason
              : l10n.kycRejectedDefaultReason,
          AppColors.error.withValues(alpha: 0.08),
          AppColors.error,
        ),
      _ => (
          Icons.badge_outlined,
          l10n.kycNoneTitle,
          l10n.kycNoneSubtitle,
          AppColors.borderLight,
          AppColors.neutralGray,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.body
                        .copyWith(color: fg, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTypography.caption.copyWith(color: fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Image upload tile ─────────────────────────────────────────────────────────

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.label,
    required this.hint,
    required this.file,
    required this.onTap,
  });
  final String label;
  final String hint;
  final File? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null ? AppColors.primaryBlue : AppColors.borderLight,
            width: file != null ? 2 : 1,
          ),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(file!, fit: BoxFit.cover),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(label,
                            style: AppTypography.caption
                                .copyWith(color: AppColors.textLight)),
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined,
                        color: AppColors.primaryBlue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: AppTypography.body.copyWith(
                              color: AppColors.neutralDark,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 2),
                        Text(hint,
                            style: AppTypography.caption
                                .copyWith(color: AppColors.neutralGray)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.neutralGray),
                  const SizedBox(width: 8),
                ],
              ),
      ),
    );
  }
}
