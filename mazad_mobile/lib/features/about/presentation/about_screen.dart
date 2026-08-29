import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.aboutTitle,
            style: AppTypography.body.copyWith(color: AppColors.neutralDark)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Image.asset(
              'assets/icon/mazad_icon.png',
              width: 96,
              height: 96,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Mazad',
            textAlign: TextAlign.center,
            style: AppTypography.title.copyWith(
              color: AppColors.neutralDark,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
          _Paragraph(l10n.aboutBody1),
          const SizedBox(height: 16),
          _Paragraph(l10n.aboutBody2),
          const SizedBox(height: 16),
          _Paragraph(l10n.aboutBody3),
          const SizedBox(height: 32),
          Text(
            l10n.appVersion,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.neutralGray),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.copyright,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.neutralGray),
          ),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.body.copyWith(
        color: AppColors.neutralDark,
        height: 1.6,
      ),
    );
  }
}
