import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Text styles. Fraunces carries bid amounts and countdowns (the emotional
/// focal point of the app). Manrope is UI/body text. IBM Plex Mono is for
/// bidder numbers, timestamps, and reference codes — anything ledger-like.
class AppTypography {
  AppTypography._();

  static TextStyle bidAmountDark = GoogleFonts.fraunces(
    fontSize: 38,
    fontWeight: FontWeight.w500,
    color: AppColors.accentYellow,
  );

  static TextStyle bidAmountLight = GoogleFonts.fraunces(
    fontSize: 38,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryBlue,
  );

  static TextStyle title = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static TextStyle body = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle caption = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static TextStyle label = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  static TextStyle monoData = GoogleFonts.ibmPlexMono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static TextStyle monoCountdown = GoogleFonts.ibmPlexMono(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );
}