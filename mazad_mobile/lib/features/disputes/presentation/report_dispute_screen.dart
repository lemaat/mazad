import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/dispute_repository.dart';

List<(String, String)> _kCategories(AppLocalizations l10n) => [
  ('item_not_as_described', l10n.disputeCategoryItemNotAsDescribed),
  ('item_not_received', l10n.disputeCategoryItemNotReceived),
  ('payment_issue', l10n.disputeCategoryPaymentIssue),
  ('seller_unresponsive', l10n.disputeCategorySellerUnresponsive),
  ('other', l10n.disputeCategoryOther),
];

class ReportDisputeScreen extends StatefulWidget {
  const ReportDisputeScreen({
    super.key,
    required this.listingId,
    required this.controller,
  });

  final String listingId;
  final AuthController controller;

  @override
  State<ReportDisputeScreen> createState() => _ReportDisputeScreenState();
}

class _ReportDisputeScreenState extends State<ReportDisputeScreen> {
  String? _category;
  final _descCtrl = TextEditingController();
  File? _evidence;
  bool _submitting = false;
  String? _error;

  late final DisputeRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = DisputeRepository(
      host: AppConfig.host,
      token: widget.controller.token!,
    );
    _descCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
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
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _evidence = File(picked.path));
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final description = _descCtrl.text.trim();
    if (description.isEmpty) {
      setState(() => _error = l10n.pleaseDescribeIssue);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repo.reportDispute(
        listingId: widget.listingId,
        category: _category!,
        description: description,
        evidence: _evidence,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.disputeSubmittedSnackbar),
        ),
      );
    } on DisputeException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on SocketException {
      if (mounted) setState(() => _error = 'Could not reach the server.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSubmit =
        _category != null && _descCtrl.text.trim().isNotEmpty && !_submitting;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          l10n.reportDisputeTitle,
          style: AppTypography.body.copyWith(color: AppColors.neutralDark),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.disputeCategoryLabel,
              style:
                  AppTypography.label.copyWith(color: AppColors.neutralGray)),
          const SizedBox(height: 8),
          _CategoryPicker(
            value: _category,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 20),
          Text(l10n.disputeDescriptionLabel,
              style:
                  AppTypography.label.copyWith(color: AppColors.neutralGray)),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.disputeDescriptionHint,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.primaryBlue, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.disputeEvidenceLabel,
              style:
                  AppTypography.label.copyWith(color: AppColors.neutralGray)),
          const SizedBox(height: 8),
          _EvidenceTile(
            file: _evidence,
            onTap: _pickEvidence,
            onRemove: () => setState(() => _evidence = null),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style:
                    AppTypography.caption.copyWith(color: AppColors.error),
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: canSubmit ? _submit : null,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.submitDisputeButton),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category picker ───────────────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.value, required this.onChanged});
  final String? value;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              value != null ? AppColors.primaryBlue : AppColors.borderLight,
          width: value != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(
          l10n.selectCategoryHint,
          style: AppTypography.body.copyWith(color: AppColors.neutralGray),
        ),
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.expand_more, color: AppColors.neutralGray),
        items: _kCategories(l10n)
            .map(
              (c) => DropdownMenuItem(
                value: c.$1,
                child: Text(
                  c.$2,
                  style: AppTypography.body
                      .copyWith(color: AppColors.neutralDark),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ── Evidence tile ─────────────────────────────────────────────────────────────

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({
    required this.file,
    required this.onTap,
    required this.onRemove,
  });
  final File? file;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (file != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              file!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined,
                color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text(
              l10n.attachPhoto,
              style:
                  AppTypography.body.copyWith(color: AppColors.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }
}
