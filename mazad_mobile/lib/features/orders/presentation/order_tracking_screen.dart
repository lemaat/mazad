import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../disputes/presentation/report_dispute_screen.dart';
import '../../listings/data/listing_repository.dart';
import '../data/order_repository.dart';

String _fmtCurrency(int amount) =>
    'MRU ${amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    )}';

String _fmtDateTime(DateTime dt) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} '
      '${pad(dt.hour)}:${pad(dt.minute)}';
}

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({
    super.key,
    required this.listingId,
    required this.listingTitle,
    required this.isBuyerView,
    required this.controller,
    required this.repository,
  });

  final String listingId;
  final String listingTitle;
  final bool isBuyerView;
  final AuthController controller;
  final ListingRepository repository;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  ListingDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _acting = false;

  OrderRepository get _orderRepo => OrderRepository(
        host: AppConfig.host,
        token: widget.controller.token!,
      );

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await widget.repository.fetchDetail(widget.listingId);
      if (mounted) setState(() => _detail = detail);
    } on ListingException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on SocketException {
      if (mounted) setState(() => _error = 'Could not reach the server.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmPayment() async {
    setState(() => _acting = true);
    try {
      await _orderRepo.confirmPayment(widget.listingId);
      if (mounted) await _loadDetail();
    } on OrderException catch (e) {
      if (mounted) _showError(e.message);
    } on SocketException {
      if (mounted) _showError('Could not reach the server.');
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _markShipped({String? trackingNote}) async {
    setState(() => _acting = true);
    try {
      await _orderRepo.markShipped(widget.listingId, trackingNote: trackingNote);
      if (mounted) await _loadDetail();
    } on OrderException catch (e) {
      if (mounted) _showError(e.message);
    } on SocketException {
      if (mounted) _showError('Could not reach the server.');
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _confirmReceived() async {
    setState(() => _acting = true);
    try {
      await _orderRepo.confirmReceived(widget.listingId);
      if (mounted) await _loadDetail();
    } on OrderException catch (e) {
      if (mounted) _showError(e.message);
    } on SocketException {
      if (mounted) _showError('Could not reach the server.');
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.listingTitle,
          style: AppTypography.body.copyWith(color: AppColors.neutralDark),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: const BackButton(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.neutralGray),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTypography.body.copyWith(color: AppColors.neutralGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loadDetail, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final d = _detail!;
    final sale = d.saleInfo!;
    final isShipped = sale.shippedAt != null;
    final isDelivered = sale.deliveredAt != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepper(sale.saleStatus, isShipped, isDelivered),
          const SizedBox(height: 24),
          _buildSaleCard(d, sale),
          const SizedBox(height: 20),
          if (sale.deliveryAddress != null) ...[
            _buildAddressCard(sale.deliveryAddress!),
            const SizedBox(height: 20),
          ],
          if (sale.trackingNote != null) ...[
            _buildTrackingNote(sale.trackingNote!),
            const SizedBox(height: 20),
          ],
          _buildActionArea(d, sale),
          const SizedBox(height: 16),
          _buildReportProblemButton(),
        ],
      ),
    );
  }

  Widget _buildStepper(String saleStatus, bool isShipped, bool isDelivered) {
    final l10n = AppLocalizations.of(context)!;
    final paid = saleStatus != 'awaiting_payment';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          _stepNode(l10n.stepPaid, paid, active: !paid),
          _stepConnector(paid),
          _stepNode(l10n.stepShipped, isShipped, active: paid && !isShipped),
          _stepConnector(isShipped),
          _stepNode(l10n.stepDelivered, isDelivered, active: isShipped && !isDelivered),
        ],
      ),
    );
  }

  Widget _stepNode(String label, bool done, {bool active = false}) {
    final color = done
        ? AppColors.success
        : active
            ? AppColors.primaryBlue
            : AppColors.borderLight;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.success : AppColors.surfaceWhite,
            border: Border.all(color: color, width: 2),
          ),
          child: done
              ? const Icon(Icons.check, size: 16, color: AppColors.surfaceWhite)
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: active || done ? FontWeight.w600 : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _stepConnector(bool done) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: done ? AppColors.success : AppColors.borderLight,
      ),
    );
  }

  Widget _buildSaleCard(ListingDetail d, SaleInfo sale) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _infoRow(l10n.orderItemLabel, d.title),
          const SizedBox(height: 8),
          _infoRow(l10n.orderFinalPrice, _fmtCurrency(sale.finalPrice)),
          if (widget.isBuyerView) ...[
            const SizedBox(height: 8),
            _infoRow(l10n.orderSellerLabel, '#${d.sellerBidderNumber}'),
          ] else ...[
            const SizedBox(height: 8),
            _infoRow(l10n.orderBuyerLabel, '#${sale.buyerBidderNumber}'),
          ],
          if (sale.shippedAt != null) ...[
            const SizedBox(height: 8),
            _infoRow(l10n.orderShippedLabel, _fmtDateTime(sale.shippedAt!)),
          ],
          if (sale.deliveredAt != null) ...[
            const SizedBox(height: 8),
            _infoRow(l10n.orderDeliveredLabel, _fmtDateTime(sale.deliveredAt!)),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressCard(SaleAddress addr) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 6),
              Text(
                l10n.deliveryAddress,
                style: AppTypography.label.copyWith(color: AppColors.neutralGray),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            addr.fullName,
            style: AppTypography.body.copyWith(
              color: AppColors.neutralDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(addr.street, style: AppTypography.body.copyWith(color: AppColors.neutralGray)),
          Text(
            '${addr.city}, ${addr.country}',
            style: AppTypography.body.copyWith(color: AppColors.neutralGray),
          ),
          Text(addr.phone, style: AppTypography.caption.copyWith(color: AppColors.neutralGray)),
        ],
      ),
    );
  }

  Widget _buildTrackingNote(String note) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              style: AppTypography.body.copyWith(color: AppColors.neutralGray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportProblemButton() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: TextButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDisputeScreen(
              listingId: widget.listingId,
              controller: widget.controller,
            ),
          ),
        ),
        icon: const Icon(Icons.flag_outlined, size: 16),
        label: Text(l10n.reportAProblem),
        style: TextButton.styleFrom(foregroundColor: AppColors.neutralGray),
      ),
    );
  }

  Widget _buildActionArea(ListingDetail d, SaleInfo sale) {
    return widget.isBuyerView
        ? _buildBuyerActions(sale)
        : _buildSellerActions(sale);
  }

  Widget _buildBuyerActions(SaleInfo sale) {
    final l10n = AppLocalizations.of(context)!;
    if (sale.saleStatus == 'awaiting_payment') {
      return _actionButton(
        label: l10n.confirmPayment,
        onPressed: _acting ? null : _confirmPayment,
        loading: _acting,
      );
    }
    if (sale.saleStatus == 'paid' && sale.deliveryAddress == null) {
      return _actionButton(
        label: l10n.addDeliveryAddress,
        onPressed: _acting ? null : _showAddressSheet,
      );
    }
    if (sale.saleStatus == 'paid' && sale.deliveryAddress != null) {
      return _statusNote(l10n.waitingForSellerToShip);
    }
    if (sale.shippedAt != null && sale.deliveredAt == null) {
      return _actionButton(
        label: l10n.confirmReceived,
        onPressed: _acting ? null : _confirmReceived,
        loading: _acting,
      );
    }
    if (sale.deliveredAt != null) {
      return _statusNote(l10n.orderCompleteEnjoy, success: true);
    }
    return const SizedBox.shrink();
  }

  Widget _buildSellerActions(SaleInfo sale) {
    final l10n = AppLocalizations.of(context)!;
    if (sale.saleStatus == 'awaiting_payment') {
      return _statusNote(l10n.waitingForBuyerPayment);
    }
    if (sale.saleStatus == 'paid' && sale.deliveryAddress == null) {
      return _statusNote(l10n.waitingForBuyerAddress);
    }
    if (sale.saleStatus == 'paid' &&
        sale.deliveryAddress != null &&
        sale.shippedAt == null) {
      return _actionButton(
        label: l10n.markAsShippedButton,
        onPressed: _acting ? null : _showMarkShippedSheet,
        loading: _acting,
      );
    }
    if (sale.shippedAt != null && sale.deliveredAt == null) {
      return _statusNote(l10n.waitingForBuyerDelivery);
    }
    if (sale.deliveredAt != null) {
      return _statusNote(l10n.orderCompleteFundsReleased, success: true);
    }
    return const SizedBox.shrink();
  }

  Future<void> _showAddressSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddressSheet(
        repository: _orderRepo,
        listingId: widget.listingId,
        onSelected: () {
          Navigator.pop(context);
          _loadDetail();
        },
      ),
    );
  }

  Future<void> _showMarkShippedSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MarkShippedSheet(
        onSubmit: (note) {
          Navigator.pop(context);
          _markShipped(trackingNote: note);
        },
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.textLight,
                ),
              )
            : Text(label),
      ),
    );
  }

  Widget _statusNote(String message, {bool success = false}) {
    final color = success ? AppColors.success : AppColors.primaryBlue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.hourglass_bottom_rounded,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(color: AppColors.neutralGray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.neutralGray)),
        Flexible(
          child: Text(
            value,
            style: AppTypography.body.copyWith(color: AppColors.neutralDark),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Address bottom sheet
// ---------------------------------------------------------------------------

class _AddressSheet extends StatefulWidget {
  const _AddressSheet({
    required this.repository,
    required this.listingId,
    required this.onSelected,
  });
  final OrderRepository repository;
  final String listingId;
  final VoidCallback onSelected;

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  List<OrderAddress>? _addresses;
  bool _loading = true;
  bool _showForm = false;
  bool _submitting = false;
  String? _error;

  final _labelCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _nameCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    try {
      final list = await widget.repository.fetchAddresses();
      if (mounted) setState(() => _addresses = list);
    } catch (_) {
      if (mounted) setState(() => _addresses = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectAddress(int addressId) async {
    setState(() { _submitting = true; _error = null; });
    try {
      await widget.repository.setDeliveryAddress(widget.listingId, addressId);
      if (mounted) widget.onSelected();
    } on OrderException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _createAndSelect() async {
    final l10n = AppLocalizations.of(context)!;
    final label = _labelCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final street = _streetCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (label.isEmpty || name.isEmpty || street.isEmpty || city.isEmpty || phone.isEmpty) {
      setState(() => _error = l10n.allFieldsRequired);
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      final addr = await widget.repository.createAddress(
        label: label,
        fullName: name,
        street: street,
        city: city,
        phone: phone,
      );
      await widget.repository.setDeliveryAddress(widget.listingId, addr.id);
      if (mounted) widget.onSelected();
    } on OrderException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _showForm ? l10n.newAddressTitle : l10n.selectAddressTitle,
            style: AppTypography.title.copyWith(
              color: AppColors.neutralDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_showForm)
            _buildForm(l10n)
          else
            _buildList(l10n),
        ],
      ),
    );
  }

  Widget _buildList(AppLocalizations l10n) {
    final addresses = _addresses ?? [];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...addresses.map(
          (a) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on_outlined, color: AppColors.primaryBlue),
            title: Text(
              '${a.label} — ${a.fullName}',
              style: AppTypography.body.copyWith(color: AppColors.neutralDark),
            ),
            subtitle: Text(
              '${a.street}, ${a.city}',
              style: AppTypography.caption.copyWith(color: AppColors.neutralGray),
            ),
            onTap: _submitting ? null : () => _selectAddress(a.id),
          ),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.add, color: AppColors.primaryBlue),
          title: Text(
            l10n.newAddressItem,
            style: AppTypography.body.copyWith(color: AppColors.primaryBlue),
          ),
          onTap: () => setState(() => _showForm = true),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.error)),
        ],
      ],
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _field(_labelCtrl, l10n.addressLabelHint),
        const SizedBox(height: 12),
        _field(_nameCtrl, l10n.fullNameHint),
        const SizedBox(height: 12),
        _field(_streetCtrl, l10n.streetAddressHint),
        const SizedBox(height: 12),
        _field(_cityCtrl, l10n.cityHint),
        const SizedBox(height: 12),
        _field(_phoneCtrl, l10n.phoneHint, keyboardType: TextInputType.phone),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.error)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _createAndSelect,
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.textLight,
                    ),
                  )
                : Text(l10n.saveAndUseAddress),
          ),
        ),
        TextButton(
          onPressed: () => setState(() { _showForm = false; _error = null; }),
          child: Text(l10n.backToSavedAddresses),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mark shipped bottom sheet
// ---------------------------------------------------------------------------

class _MarkShippedSheet extends StatefulWidget {
  const _MarkShippedSheet({required this.onSubmit});
  final void Function(String? trackingNote) onSubmit;

  @override
  State<_MarkShippedSheet> createState() => _MarkShippedSheetState();
}

class _MarkShippedSheetState extends State<_MarkShippedSheet> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.markAsShippedSheetTitle,
            style: AppTypography.title.copyWith(
              color: AppColors.neutralDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.trackingNoteOptionalSubtitle,
            style: AppTypography.caption.copyWith(color: AppColors.neutralGray),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: l10n.trackingNoteHint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final note = _noteCtrl.text.trim();
                widget.onSubmit(note.isEmpty ? null : note);
              },
              child: Text(l10n.confirmShipment),
            ),
          ),
        ],
      ),
    );
  }
}
