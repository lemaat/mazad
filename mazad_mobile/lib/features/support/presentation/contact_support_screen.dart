import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';

const _supportEmail = 'projectestingemail@gmail.com';
const _supportPhone = '+22233889010';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'Mazad Support Request'},
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchPhone() async {
    final uri = Uri(scheme: 'tel', path: _supportPhone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.contactSupportTitle,
            style: AppTypography.body.copyWith(color: AppColors.neutralDark)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionLabel(l10n.contactUs),
          const SizedBox(height: 8),
          _ContactCard(
            icon: Icons.email_outlined,
            label: _supportEmail,
            onTap: _launchEmail,
          ),
          const SizedBox(height: 8),
          _ContactCard(
            icon: Icons.phone_outlined,
            label: '+222 33 88 90 10',
            onTap: _launchPhone,
          ),
          const SizedBox(height: 28),
          _SectionLabel(l10n.faqSectionTitle),
          const SizedBox(height: 8),
          _FaqAccordion(l10n: l10n),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: AppTypography.label
            .copyWith(color: AppColors.neutralGray, letterSpacing: 0.8),
      );
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppTypography.body
                      .copyWith(color: AppColors.primaryBlue)),
            ),
            const Icon(Icons.open_in_new,
                size: 16, color: AppColors.neutralGray),
          ],
        ),
      ),
    );
  }
}

class _FaqAccordion extends StatelessWidget {
  const _FaqAccordion({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final faqs = [
      (q: l10n.faq1Question, a: l10n.faq1Answer),
      (q: l10n.faq2Question, a: l10n.faq2Answer),
      (q: l10n.faq3Question, a: l10n.faq3Answer),
      (q: l10n.faq4Question, a: l10n.faq4Answer),
      (q: l10n.faq5Question, a: l10n.faq5Answer),
      (q: l10n.faq6Question, a: l10n.faq6Answer),
      (q: l10n.faq7Question, a: l10n.faq7Answer),
      (q: l10n.faq8Question, a: l10n.faq8Answer),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: faqs.indexed.map((entry) {
          final (i, faq) = entry;
          return Column(
            children: [
              ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                childrenPadding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 14),
                title: Text(
                  faq.q,
                  style: AppTypography.body
                      .copyWith(color: AppColors.neutralDark),
                ),
                iconColor: AppColors.primaryBlue,
                collapsedIconColor: AppColors.neutralGray,
                children: [
                  Text(
                    faq.a,
                    style: AppTypography.body.copyWith(
                      color: AppColors.neutralGray,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              if (i < faqs.length - 1)
                const Divider(height: 1, color: AppColors.borderLight),
            ],
          );
        }).toList(),
      ),
    );
  }
}
