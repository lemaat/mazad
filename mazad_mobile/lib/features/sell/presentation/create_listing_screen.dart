import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../kyc/presentation/kyc_screen.dart';
import '../../listings/data/listing_repository.dart';
import '../data/sell_repository.dart';
import 'listing_fee_screen.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({
    super.key,
    required this.repository,
    required this.listingRepository,
    required this.controller,
  });
  final SellRepository repository;
  final ListingRepository listingRepository;
  final AuthController controller;

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _pageController = PageController();
  int _page = 0;

  // Step 1 — category
  List<ListingCategory>? _categories;
  bool _categoriesLoading = true;
  String? _categoriesError;
  ListingCategory? _selectedCategory;

  // Step 2 — details
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Step 3 — pricing & schedule
  final _startingPriceCtrl = TextEditingController();
  final _reservePriceCtrl = TextEditingController();
  final _minIncrementCtrl = TextEditingController(text: '1000');
  DateTime _auctionStart = DateTime.now().add(const Duration(hours: 1));
  DateTime _auctionEnd = DateTime.now().add(const Duration(hours: 25));

  // Submission
  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _startingPriceCtrl.dispose();
    _reservePriceCtrl.dispose();
    _minIncrementCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });
    try {
      final cats = await widget.listingRepository.fetchCategories();
      if (mounted) setState(() => _categories = cats);
    } on ListingException catch (e) {
      if (mounted) setState(() => _categoriesError = e.message);
    } on SocketException {
      if (mounted) setState(() => _categoriesError = AppLocalizations.of(context)!.couldNotReachServer);
    } catch (_) {
      if (mounted) setState(() => _categoriesError = AppLocalizations.of(context)!.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _page = page);
  }

  void _onCategoryNext() {
    final cat = _selectedCategory;
    if (cat != null &&
        cat.requiresIdVerification &&
        widget.controller.verificationTier != 'id_verified') {
      showDialog<void>(
        context: context,
        builder: (ctx) {
          final dl10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            title: Text(dl10n.idVerificationRequired),
            content: Text(dl10n.idVerificationRequiredMessage(cat.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(dl10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KycScreen(controller: widget.controller),
                    ),
                  );
                },
                child: Text(dl10n.verifyNow),
              ),
            ],
          );
        },
      );
      return;
    }
    _goTo(1);
  }

  bool get _step1Valid => _selectedCategory != null;
  bool get _step2Valid =>
      _titleCtrl.text.trim().isNotEmpty && _descCtrl.text.trim().isNotEmpty;
  bool get _step3Valid {
    final sp = int.tryParse(_startingPriceCtrl.text.trim());
    final rp = int.tryParse(_reservePriceCtrl.text.trim());
    final mi = int.tryParse(_minIncrementCtrl.text.trim());
    if (sp == null || rp == null || mi == null) return false;
    if (sp <= 0 || rp <= 0 || mi <= 0) return false;
    return _auctionEnd.isAfter(_auctionStart);
  }

  Future<void> _submit() async {
    if (!_step3Valid) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final listing = await widget.repository.createListing(
        categoryId: _selectedCategory!.id,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        startingPrice: int.parse(_startingPriceCtrl.text.trim()),
        reservePrice: int.parse(_reservePriceCtrl.text.trim()),
        minIncrement: int.parse(_minIncrementCtrl.text.trim()),
        auctionStart: _auctionStart,
        auctionEnd: _auctionEnd,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ListingFeeScreen(
            listing: listing,
            repository: widget.repository,
          ),
        ),
      );
      if (mounted) Navigator.pop(context);
    } on SellException catch (e) {
      if (mounted) setState(() => _submitError = e.message);
    } on SocketException {
      if (mounted) setState(() => _submitError = AppLocalizations.of(context)!.couldNotReachServer);
    } catch (_) {
      if (mounted) setState(() => _submitError = AppLocalizations.of(context)!.somethingWentWrong);
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
        title: Text(
          [l10n.createListingStepCategory, l10n.createListingStepDetails, l10n.createListingStepPricing][_page.clamp(0, 2)],
          style: AppTypography.body.copyWith(color: AppColors.neutralDark),
        ),
        leading: _page == 0
            ? const CloseButton()
            : BackButton(onPressed: () => _goTo(_page - 1)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _StepBar(step: _page, total: 3),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _CategoryStep(
            loading: _categoriesLoading,
            error: _categoriesError,
            categories: _categories ?? [],
            selected: _selectedCategory,
            onSelect: (c) => setState(() => _selectedCategory = c),
            onRetry: _loadCategories,
            onNext: _step1Valid ? _onCategoryNext : null,
          ),
          _DetailsStep(
            titleCtrl: _titleCtrl,
            descCtrl: _descCtrl,
            onNext: () {
              if (_step2Valid) _goTo(2);
            },
          ),
          _PricingStep(
            startingPriceCtrl: _startingPriceCtrl,
            reservePriceCtrl: _reservePriceCtrl,
            minIncrementCtrl: _minIncrementCtrl,
            auctionStart: _auctionStart,
            auctionEnd: _auctionEnd,
            onStartChanged: (dt) => setState(() => _auctionStart = dt),
            onEndChanged: (dt) => setState(() => _auctionEnd = dt),
            submitting: _submitting,
            error: _submitError,
            onSubmit: _step3Valid && !_submitting ? _submit : null,
          ),
        ],
      ),
    );
  }
}

// ── Step bar ──────────────────────────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Container(
            height: 4,
            color: i <= step ? AppColors.primaryBlue : AppColors.borderLight,
          ),
        );
      }),
    );
  }
}

// ── Step 1: Category ──────────────────────────────────────────────────────────

class _CategoryStep extends StatelessWidget {
  const _CategoryStep({
    required this.loading,
    required this.error,
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.onRetry,
    required this.onNext,
  });
  final bool loading;
  final String? error;
  final List<ListingCategory> categories;
  final ListingCategory? selected;
  final ValueChanged<ListingCategory> onSelect;
  final VoidCallback onRetry;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, style: AppTypography.body.copyWith(color: AppColors.neutralGray)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final c = categories[i];
              final isSelected = selected?.id == c.id;
              return GestureDetector(
                onTap: () => onSelect(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlue.withValues(alpha: 0.07)
                        : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryBlue : AppColors.borderLight,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name,
                                style: AppTypography.body.copyWith(
                                  color: AppColors.neutralDark,
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 4),
                            Text(
                              l10n.listingFeeDisplay(_fmtFee(c.listingFee)),
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.neutralGray),
                            ),
                            if (c.requiresIdVerification) ...[
                              const SizedBox(height: 4),
                              Text(
                                l10n.requiresIdVerification,
                                style: AppTypography.caption
                                    .copyWith(color: AppColors.warning),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: AppColors.primaryBlue, size: 22),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _NextButton(label: l10n.nextDetails, onPressed: onNext),
      ],
    );
  }

  String _fmtFee(double fee) {
    final s = fee.toStringAsFixed(0);
    return 'MRU ${s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
  }
}

// ── Step 2: Details ───────────────────────────────────────────────────────────

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.titleCtrl,
    required this.descCtrl,
    required this.onNext,
  });
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.titleLabel,
                    style: AppTypography.label.copyWith(color: AppColors.neutralGray)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  maxLength: 140,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDeco(l10n.titleHint),
                ),
                const SizedBox(height: 16),
                Text(l10n.descriptionLabel,
                    style: AppTypography.label.copyWith(color: AppColors.neutralGray)),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDeco(l10n.descriptionHint),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.photo_camera_outlined,
                      size: 18, color: AppColors.neutralGray),
                  const SizedBox(width: 6),
                  Text(l10n.photosAddedAfterPublishing,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.neutralGray)),
                ]),
              ],
            ),
          ),
        ),
        ListenableBuilder(
          listenable: Listenable.merge([titleCtrl, descCtrl]),
          builder: (ctx, _) {
            final bl10n = AppLocalizations.of(ctx)!;
            return _NextButton(
              label: bl10n.nextPricing,
              onPressed: titleCtrl.text.trim().isNotEmpty &&
                      descCtrl.text.trim().isNotEmpty
                  ? onNext
                  : null,
            );
          },
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.neutralGray),
        filled: true,
        fillColor: AppColors.surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ── Step 3: Pricing & Schedule ────────────────────────────────────────────────

class _PricingStep extends StatelessWidget {
  const _PricingStep({
    required this.startingPriceCtrl,
    required this.reservePriceCtrl,
    required this.minIncrementCtrl,
    required this.auctionStart,
    required this.auctionEnd,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.submitting,
    required this.error,
    required this.onSubmit,
  });
  final TextEditingController startingPriceCtrl;
  final TextEditingController reservePriceCtrl;
  final TextEditingController minIncrementCtrl;
  final DateTime auctionStart;
  final DateTime auctionEnd;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime> onEndChanged;
  final bool submitting;
  final String? error;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(l10n.startingPriceMru),
                const SizedBox(height: 6),
                _numField(startingPriceCtrl, 'e.g. 50000'),
                const SizedBox(height: 16),
                _label(l10n.reservePriceMru),
                const SizedBox(height: 4),
                Text(
                  l10n.reservePriceNote,
                  style: AppTypography.caption.copyWith(color: AppColors.neutralGray),
                ),
                const SizedBox(height: 6),
                _numField(reservePriceCtrl, 'e.g. 80000'),
                const SizedBox(height: 16),
                _label(l10n.minBidIncrementMru),
                const SizedBox(height: 6),
                _numField(minIncrementCtrl, '1000'),
                const SizedBox(height: 24),
                _label(l10n.auctionStartLabel),
                const SizedBox(height: 6),
                _DateTimePicker(
                  value: auctionStart,
                  onChanged: onStartChanged,
                ),
                const SizedBox(height: 16),
                _label(l10n.auctionEndLabel),
                const SizedBox(height: 6),
                _DateTimePicker(
                  value: auctionEnd,
                  onChanged: onEndChanged,
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(error!,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.error)),
                  ),
                ],
              ],
            ),
          ),
        ),
        _NextButton(
          label: submitting ? l10n.creatingListing : l10n.reviewAndPay,
          onPressed: submitting ? null : onSubmit,
          loading: submitting,
        ),
      ],
    );
  }

  Widget _label(String text) =>
      Text(text, style: AppTypography.label.copyWith(color: AppColors.neutralGray));

  Widget _numField(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.neutralGray),
          filled: true,
          fillColor: AppColors.surfaceWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
}

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker({required this.value, required this.onChanged});
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.primaryBlue),
            const SizedBox(width: 10),
            Text(_fmt(value),
                style: AppTypography.body.copyWith(color: AppColors.neutralDark)),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (time == null) return;
    onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  String _fmt(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)}  ${pad(dt.hour)}:${pad(dt.minute)}';
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onPressed, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onPressed,
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(label),
          ),
        ),
      ),
    );
  }
}
