import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/address_repository.dart';

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key, required this.controller});
  final AuthController controller;

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  List<OrderAddress>? _addresses;
  bool _loading = true;
  String? _error;

  late final AddressRepository _repo;
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

  @override
  void initState() {
    super.initState();
    _repo = AddressRepository(
      host: AppConfig.host,
      token: widget.controller.token!,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.fetchAddresses();
      if (mounted) setState(() => _addresses = result);
    } on AddressException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on SocketException {
      if (mounted) setState(() => _error = _l10n.couldNotReachServer);
    } catch (_) {
      if (mounted) setState(() => _error = _l10n.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(OrderAddress address) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteAddressTitle),
        content: Text(l10n.deleteAddressMessage(address.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repo.deleteAddress(address.id);
      setState(() => _addresses?.removeWhere((a) => a.id == address.id));
    } on AddressException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _setDefault(OrderAddress address) async {
    try {
      final updated = await _repo.setDefault(address.id);
      setState(() {
        _addresses = _addresses
            ?.map((a) => a.id == updated.id
                ? updated
                : OrderAddress(
                    id: a.id,
                    label: a.label,
                    fullName: a.fullName,
                    street: a.street,
                    city: a.city,
                    country: a.country,
                    phone: a.phone,
                    isDefault: false,
                  ))
            .toList();
      });
    } on AddressException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _openForm({OrderAddress? existing}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AddressFormScreen(
          repo: _repo,
          existing: existing,
        ),
      ),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.addressBookTitle,
            style: AppTypography.body.copyWith(color: AppColors.neutralDark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addAddress,
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: AppColors.neutralGray),
              const SizedBox(height: 16),
              Text(_error!,
                  style: AppTypography.body
                      .copyWith(color: AppColors.neutralGray),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _load, child: Text(_l10n.retry)),
            ],
          ),
        ),
      );
    }
    final items = _addresses ?? [];
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined,
                  size: 48, color: AppColors.neutralGray),
              const SizedBox(height: 16),
              Text(
                l10n.noAddressesYet,
                style: AppTypography.body
                    .copyWith(color: AppColors.neutralGray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _openForm(),
                child: Text(l10n.addAddress),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (_, i) => _AddressTile(
          address: items[i],
          onEdit: () => _openForm(existing: items[i]),
          onDelete: () => _confirmDelete(items[i]),
          onSetDefault: items[i].isDefault ? null : () => _setDefault(items[i]),
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.onSetDefault,
  });
  final OrderAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: address.isDefault ? AppColors.primaryBlue : AppColors.borderLight,
          width: address.isDefault ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label,
                        style: AppTypography.body.copyWith(
                          color: AppColors.neutralDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.defaultBadge,
                            style: AppTypography.label.copyWith(
                              color: AppColors.primaryBlue,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(address.fullName,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.neutralGray)),
                  Text(
                    '${address.street}, ${address.city}',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.neutralGray),
                  ),
                  Text(address.phone,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.neutralGray)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.neutralGray),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
                if (v == 'default' && onSetDefault != null) onSetDefault!();
              },
              itemBuilder: (ctx) {
                final l10n = AppLocalizations.of(ctx)!;
                return [
                  PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                  if (onSetDefault != null)
                    PopupMenuItem(
                        value: 'default',
                        child: Text(l10n.setAsDefault)),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.delete,
                          style: const TextStyle(color: AppColors.error))),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressFormScreen extends StatefulWidget {
  const _AddressFormScreen({required this.repo, this.existing});
  final AddressRepository repo;
  final OrderAddress? existing;

  @override
  State<_AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<_AddressFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _fullName;
  late final TextEditingController _street;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _phone;
  bool _isDefault = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _label = TextEditingController(text: a?.label ?? '');
    _fullName = TextEditingController(text: a?.fullName ?? '');
    _street = TextEditingController(text: a?.street ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _country = TextEditingController(text: a?.country ?? 'Mauritania');
    _phone = TextEditingController(text: a?.phone ?? '');
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _fullName.dispose();
    _street.dispose();
    _city.dispose();
    _country.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await widget.repo.createAddress(
          label: _label.text.trim(),
          fullName: _fullName.text.trim(),
          street: _street.text.trim(),
          city: _city.text.trim(),
          country: _country.text.trim(),
          phone: _phone.text.trim(),
          isDefault: _isDefault,
        );
      } else {
        await widget.repo.updateAddress(
          widget.existing!.id,
          label: _label.text.trim(),
          fullName: _fullName.text.trim(),
          street: _street.text.trim(),
          city: _city.text.trim(),
          country: _country.text.trim(),
          phone: _phone.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on AddressException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isEdit ? l10n.editAddress : l10n.newAddressTitle,
            style:
                AppTypography.body.copyWith(color: AppColors.neutralDark)),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Field(controller: _label, label: l10n.addressLabelField, hint: l10n.addressLabelFieldHint),
            const SizedBox(height: 12),
            _Field(controller: _fullName, label: l10n.addressFullNameField),
            const SizedBox(height: 12),
            _Field(controller: _street, label: l10n.addressStreetField),
            const SizedBox(height: 12),
            _Field(controller: _city, label: l10n.addressCityField),
            const SizedBox(height: 12),
            _Field(controller: _country, label: l10n.addressCountryField),
            const SizedBox(height: 12),
            _Field(
              controller: _phone,
              label: l10n.addressPhoneField,
              keyboardType: TextInputType.phone,
            ),
            if (!isEdit) ...[
              const SizedBox(height: 4),
              SwitchListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                title: Text(l10n.setAsDefault,
                    style: AppTypography.body
                        .copyWith(color: AppColors.neutralDark)),
                contentPadding: EdgeInsets.zero,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? l10n.saveChanges : l10n.addAddress),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: AppColors.surfaceWhite,
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }
}
