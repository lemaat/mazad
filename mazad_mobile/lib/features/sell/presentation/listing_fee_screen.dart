import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../data/sell_repository.dart';
import 'listing_photos_screen.dart';

class ListingFeeScreen extends StatefulWidget {
  const ListingFeeScreen({
    super.key,
    required this.listing,
    required this.repository,
  });
  final CreatedListing listing;
  final SellRepository repository;

  @override
  State<ListingFeeScreen> createState() => _ListingFeeScreenState();
}

class _ListingFeeScreenState extends State<ListingFeeScreen> {
  bool _paying = false;
  bool _paid = false;
  String? _error;

  Future<void> _pay() async {
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      await widget.repository.payListingFee(widget.listing.id);
      if (mounted) setState(() => _paid = true);
    } on SellException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on SocketException {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.couldNotReachServer);
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.listingFeeTitle,
            style: AppTypography.body.copyWith(color: AppColors.neutralDark)),
        leading: _paid ? null : const CloseButton(),
        automaticallyImplyLeading: !_paid,
      ),
      body: _paid ? _buildSuccess() : _buildPayment(),
    );
  }

  Widget _buildSuccess() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppColors.surfaceWhite, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.listingPublished,
              style: AppTypography.title.copyWith(color: AppColors.neutralDark),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.listingPublishedBody(widget.listing.title),
              style: AppTypography.body.copyWith(color: AppColors.neutralGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListingPhotosScreen(
                      listingId: widget.listing.id,
                      repository: widget.repository,
                    ),
                  ),
                ),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(l10n.addPhotos),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.skipPhotos),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayment() {
    final l10n = AppLocalizations.of(context)!;
    final fee = widget.listing.category.listingFee;
    final feeStr = _fmtFee(fee);

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.warning.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.science_outlined,
                  size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.testModeBanner,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.listingSummaryLabel,
                          style: AppTypography.label
                              .copyWith(color: AppColors.neutralGray, letterSpacing: 0.6)),
                      const SizedBox(height: 12),
                      Text(widget.listing.title,
                          style: AppTypography.body.copyWith(
                              color: AppColors.neutralDark, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(widget.listing.category.name,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.neutralGray)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.platformListingFee,
                          style: AppTypography.body
                              .copyWith(color: AppColors.neutralDark)),
                      Text(feeStr,
                          style: AppTypography.title.copyWith(
                            color: AppColors.primaryBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.neutralGray),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.sedadProductionNote,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.neutralGray),
                    ),
                  ),
                ]),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.error)),
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _paying ? null : _pay,
                icon: _paying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.payment_outlined),
                label: Text(_paying ? l10n.processing : l10n.confirmStub(feeStr)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _fmtFee(double fee) {
    final s = fee.toStringAsFixed(0);
    return 'MRU ${s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
  }
}
