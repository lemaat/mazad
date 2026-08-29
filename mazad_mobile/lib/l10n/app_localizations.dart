import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @couldNotReachServer.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server.'**
  String get couldNotReachServer;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get somethingWentWrong;

  /// No description provided for @somethingWentWrongTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrongTryAgain;

  /// No description provided for @navFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get navFeed;

  /// No description provided for @navLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get navLive;

  /// No description provided for @navWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get navWallet;

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @signInToSeeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see notifications'**
  String get signInToSeeNotifications;

  /// No description provided for @createListingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create listing'**
  String get createListingTooltip;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get accountCreated;

  /// No description provided for @yourBidderNumber.
  ///
  /// In en, this message translates to:
  /// **'Your bidder number is:'**
  String get yourBidderNumber;

  /// No description provided for @bidderNumberSaveNote.
  ///
  /// In en, this message translates to:
  /// **'This is how you appear at auctions. Save it somewhere safe.'**
  String get bidderNumberSaveNote;

  /// No description provided for @continueBtnLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtnLabel;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Shown to other bidders'**
  String get displayNameHint;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Live Auctions'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Bid on cars, real estate, and goods in real time. Watch prices update live and never miss a beat.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Sell with Confidence'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'List your items in minutes and reach verified buyers across Mauritania.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Stay in the Loop'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Get notified when you\'re outbid, when an auction ends, or when your listing gets its first offer.'**
  String get onboardingBody3;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @sectionTrading.
  ///
  /// In en, this message translates to:
  /// **'TRADING'**
  String get sectionTrading;

  /// No description provided for @myListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get myListings;

  /// No description provided for @myBids.
  ///
  /// In en, this message translates to:
  /// **'My Bids'**
  String get myBids;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @addressBook.
  ///
  /// In en, this message translates to:
  /// **'Address Book'**
  String get addressBook;

  /// No description provided for @sectionSupport.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get sectionSupport;

  /// No description provided for @myDisputes.
  ///
  /// In en, this message translates to:
  /// **'My Disputes'**
  String get myDisputes;

  /// No description provided for @contactAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact & Support'**
  String get contactAndSupport;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @sectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get sectionPreferences;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get sectionAccount;

  /// No description provided for @identityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get identityVerification;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @verifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedBadge;

  /// No description provided for @pendingBadge.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingBadge;

  /// No description provided for @signOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutDialogTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @searchListingsHint.
  ///
  /// In en, this message translates to:
  /// **'Search listings…'**
  String get searchListingsHint;

  /// No description provided for @mazadAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Mazad'**
  String get mazadAppBarTitle;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryCars.
  ///
  /// In en, this message translates to:
  /// **'Cars'**
  String get categoryCars;

  /// No description provided for @categoryLand.
  ///
  /// In en, this message translates to:
  /// **'Land'**
  String get categoryLand;

  /// No description provided for @categoryGoods.
  ///
  /// In en, this message translates to:
  /// **'Goods'**
  String get categoryGoods;

  /// No description provided for @statusLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get statusLive;

  /// No description provided for @statusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get statusUpcoming;

  /// No description provided for @statusPendingDecision.
  ///
  /// In en, this message translates to:
  /// **'Pending decision'**
  String get statusPendingDecision;

  /// No description provided for @statusSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get statusSold;

  /// No description provided for @statusUnsold.
  ///
  /// In en, this message translates to:
  /// **'Unsold'**
  String get statusUnsold;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusPendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Pending payment'**
  String get statusPendingPayment;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusBadgeLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get statusBadgeLive;

  /// No description provided for @statusBadgeUpcoming.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get statusBadgeUpcoming;

  /// No description provided for @statusBadgePending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get statusBadgePending;

  /// No description provided for @statusBadgeSold.
  ///
  /// In en, this message translates to:
  /// **'SOLD'**
  String get statusBadgeSold;

  /// No description provided for @statusBadgeUnsold.
  ///
  /// In en, this message translates to:
  /// **'UNSOLD'**
  String get statusBadgeUnsold;

  /// No description provided for @timeEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get timeEnded;

  /// No description provided for @timeStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get timeStarted;

  /// No description provided for @timeHasStarted.
  ///
  /// In en, this message translates to:
  /// **'Has started'**
  String get timeHasStarted;

  /// No description provided for @endsIn.
  ///
  /// In en, this message translates to:
  /// **'Ends in {timeLeft}'**
  String endsIn(String timeLeft);

  /// No description provided for @startsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in {timeLeft}'**
  String startsIn(String timeLeft);

  /// No description provided for @priceFrom.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String priceFrom(String price);

  /// No description provided for @bidCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} bid} other{{count} bids}}'**
  String bidCountLabel(int count);

  /// No description provided for @noListingsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No listings available right now.'**
  String get noListingsAvailable;

  /// No description provided for @noListingsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No {category} listings right now.'**
  String noListingsInCategory(String category);

  /// No description provided for @currentBid.
  ///
  /// In en, this message translates to:
  /// **'Current bid'**
  String get currentBid;

  /// No description provided for @startingPrice.
  ///
  /// In en, this message translates to:
  /// **'Starting price'**
  String get startingPrice;

  /// No description provided for @minimumIncrement.
  ///
  /// In en, this message translates to:
  /// **'Minimum increment'**
  String get minimumIncrement;

  /// No description provided for @auctionOpens.
  ///
  /// In en, this message translates to:
  /// **'Auction opens'**
  String get auctionOpens;

  /// No description provided for @auctionCloses.
  ///
  /// In en, this message translates to:
  /// **'Auction closes'**
  String get auctionCloses;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get timeRemaining;

  /// No description provided for @softCloseWindow.
  ///
  /// In en, this message translates to:
  /// **'Soft-close window'**
  String get softCloseWindow;

  /// No description provided for @softCloseWindowValue.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String softCloseWindowValue(int count);

  /// No description provided for @descriptionSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionSectionLabel;

  /// No description provided for @depositNote.
  ///
  /// In en, this message translates to:
  /// **'A refundable deposit is required to participate. Your deposit determines your maximum bid ceiling (10× your deposit).'**
  String get depositNote;

  /// No description provided for @auctionEndedDecisionRequired.
  ///
  /// In en, this message translates to:
  /// **'Auction ended — decision required'**
  String get auctionEndedDecisionRequired;

  /// No description provided for @winningBid.
  ///
  /// In en, this message translates to:
  /// **'Winning bid'**
  String get winningBid;

  /// No description provided for @runnerUpBidder.
  ///
  /// In en, this message translates to:
  /// **'Runner-up bidder'**
  String get runnerUpBidder;

  /// No description provided for @secondChanceDeadline.
  ///
  /// In en, this message translates to:
  /// **'Second chance deadline'**
  String get secondChanceDeadline;

  /// No description provided for @sellerReviewingResult.
  ///
  /// In en, this message translates to:
  /// **'The seller is reviewing the auction result.'**
  String get sellerReviewingResult;

  /// No description provided for @secondChanceOfferedTitle.
  ///
  /// In en, this message translates to:
  /// **'Second chance offered!'**
  String get secondChanceOfferedTitle;

  /// No description provided for @yourOfferPrice.
  ///
  /// In en, this message translates to:
  /// **'Your offer price'**
  String get yourOfferPrice;

  /// No description provided for @expiresLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expiresLabel;

  /// No description provided for @endUnsoldButton.
  ///
  /// In en, this message translates to:
  /// **'End Unsold'**
  String get endUnsoldButton;

  /// No description provided for @secondChanceButton.
  ///
  /// In en, this message translates to:
  /// **'Second Chance'**
  String get secondChanceButton;

  /// No description provided for @acceptSecondChanceButton.
  ///
  /// In en, this message translates to:
  /// **'Accept Second Chance'**
  String get acceptSecondChanceButton;

  /// No description provided for @joinAuction.
  ///
  /// In en, this message translates to:
  /// **'Join Auction'**
  String get joinAuction;

  /// No description provided for @signInToBid.
  ///
  /// In en, this message translates to:
  /// **'Sign in to bid'**
  String get signInToBid;

  /// No description provided for @depositRequired.
  ///
  /// In en, this message translates to:
  /// **'Deposit Required'**
  String get depositRequired;

  /// No description provided for @yourIntendedMaxBid.
  ///
  /// In en, this message translates to:
  /// **'Your intended maximum bid'**
  String get yourIntendedMaxBid;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get availableBalance;

  /// No description provided for @placeDeposit.
  ///
  /// In en, this message translates to:
  /// **'Place Deposit — {amount}'**
  String placeDeposit(String amount);

  /// No description provided for @enterIntendedBidAbove.
  ///
  /// In en, this message translates to:
  /// **'Enter your intended bid above'**
  String get enterIntendedBidAbove;

  /// No description provided for @requiredDepositLabel.
  ///
  /// In en, this message translates to:
  /// **'Required deposit (1/10 of max bid)'**
  String get requiredDepositLabel;

  /// No description provided for @yourBidCeiling.
  ///
  /// In en, this message translates to:
  /// **'Your bid ceiling'**
  String get yourBidCeiling;

  /// No description provided for @liveAuctions.
  ///
  /// In en, this message translates to:
  /// **'Live Auctions'**
  String get liveAuctions;

  /// No description provided for @liveNow.
  ///
  /// In en, this message translates to:
  /// **'LIVE NOW'**
  String get liveNow;

  /// No description provided for @comingUp.
  ///
  /// In en, this message translates to:
  /// **'COMING UP'**
  String get comingUp;

  /// No description provided for @noLiveOrUpcomingAuctions.
  ///
  /// In en, this message translates to:
  /// **'No live or upcoming auctions right now.'**
  String get noLiveOrUpcomingAuctions;

  /// No description provided for @startingSoon.
  ///
  /// In en, this message translates to:
  /// **'Starting soon'**
  String get startingSoon;

  /// No description provided for @createListingStepCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get createListingStepCategory;

  /// No description provided for @createListingStepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get createListingStepDetails;

  /// No description provided for @createListingStepPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing & Schedule'**
  String get createListingStepPricing;

  /// No description provided for @idVerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'ID Verification Required'**
  String get idVerificationRequired;

  /// No description provided for @idVerificationRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'{categoryName} listings require identity verification. Submit your ID to unlock this category.'**
  String idVerificationRequiredMessage(String categoryName);

  /// No description provided for @verifyNow.
  ///
  /// In en, this message translates to:
  /// **'Verify Now'**
  String get verifyNow;

  /// No description provided for @listingFeeDisplay.
  ///
  /// In en, this message translates to:
  /// **'Listing fee: {fee}'**
  String listingFeeDisplay(String fee);

  /// No description provided for @requiresIdVerification.
  ///
  /// In en, this message translates to:
  /// **'Requires ID verification'**
  String get requiresIdVerification;

  /// No description provided for @nextDetails.
  ///
  /// In en, this message translates to:
  /// **'Next: Details'**
  String get nextDetails;

  /// No description provided for @nextPricing.
  ///
  /// In en, this message translates to:
  /// **'Next: Pricing'**
  String get nextPricing;

  /// No description provided for @reviewAndPay.
  ///
  /// In en, this message translates to:
  /// **'Review & Pay'**
  String get reviewAndPay;

  /// No description provided for @creatingListing.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get creatingListing;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2019 Toyota Land Cruiser'**
  String get titleHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the item — condition, specs, any defects…'**
  String get descriptionHint;

  /// No description provided for @photosAddedAfterPublishing.
  ///
  /// In en, this message translates to:
  /// **'Photos can be added after publishing.'**
  String get photosAddedAfterPublishing;

  /// No description provided for @startingPriceMru.
  ///
  /// In en, this message translates to:
  /// **'Starting price (MRU)'**
  String get startingPriceMru;

  /// No description provided for @reservePriceMru.
  ///
  /// In en, this message translates to:
  /// **'Reserve price (MRU)'**
  String get reservePriceMru;

  /// No description provided for @reservePriceNote.
  ///
  /// In en, this message translates to:
  /// **'Hidden from bidders. Minimum you\'ll accept.'**
  String get reservePriceNote;

  /// No description provided for @minBidIncrementMru.
  ///
  /// In en, this message translates to:
  /// **'Min bid increment (MRU)'**
  String get minBidIncrementMru;

  /// No description provided for @auctionStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Auction start'**
  String get auctionStartLabel;

  /// No description provided for @auctionEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Auction end'**
  String get auctionEndLabel;

  /// No description provided for @listingFeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing Fee'**
  String get listingFeeTitle;

  /// No description provided for @testModeBanner.
  ///
  /// In en, this message translates to:
  /// **'TEST MODE — no real charge. Sedad integration not yet wired.'**
  String get testModeBanner;

  /// No description provided for @listingSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Listing summary'**
  String get listingSummaryLabel;

  /// No description provided for @platformListingFee.
  ///
  /// In en, this message translates to:
  /// **'Platform listing fee'**
  String get platformListingFee;

  /// No description provided for @sedadProductionNote.
  ///
  /// In en, this message translates to:
  /// **'In production, payment will be collected via Sedad before the listing is published.'**
  String get sedadProductionNote;

  /// No description provided for @listingPublished.
  ///
  /// In en, this message translates to:
  /// **'Listing published!'**
  String get listingPublished;

  /// No description provided for @listingPublishedBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is now scheduled. Bidders will be able to join once the auction starts.'**
  String listingPublishedBody(String title);

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get processing;

  /// No description provided for @confirmStub.
  ///
  /// In en, this message translates to:
  /// **'Confirm (stub — {fee} not charged)'**
  String confirmStub(String fee);

  /// No description provided for @sectionActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get sectionActive;

  /// No description provided for @sectionPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get sectionPending;

  /// No description provided for @sectionCompleted.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get sectionCompleted;

  /// No description provided for @noListingsYet.
  ///
  /// In en, this message translates to:
  /// **'You have no listings yet.'**
  String get noListingsYet;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @signInToViewWallet.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your wallet'**
  String get signInToViewWallet;

  /// No description provided for @walletBalanceWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Your balance and active deposits will appear here.'**
  String get walletBalanceWillAppear;

  /// No description provided for @activeDeposits.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE DEPOSITS'**
  String get activeDeposits;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @inDeposits.
  ///
  /// In en, this message translates to:
  /// **'In deposits'**
  String get inDeposits;

  /// No description provided for @noActiveDeposits.
  ///
  /// In en, this message translates to:
  /// **'No active deposits.\nBrowse listings and join an auction to place a deposit.'**
  String get noActiveDeposits;

  /// No description provided for @bidCeilingLabel.
  ///
  /// In en, this message translates to:
  /// **'Bid ceiling: {amount}'**
  String bidCeilingLabel(String amount);

  /// No description provided for @activeAuctions.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE AUCTIONS'**
  String get activeAuctions;

  /// No description provided for @pastAuctions.
  ///
  /// In en, this message translates to:
  /// **'PAST AUCTIONS'**
  String get pastAuctions;

  /// No description provided for @noPlacedBids.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t placed any bids yet.'**
  String get noPlacedBids;

  /// No description provided for @myBidLabel.
  ///
  /// In en, this message translates to:
  /// **'My bid'**
  String get myBidLabel;

  /// No description provided for @currentBidShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentBidShortLabel;

  /// No description provided for @indicatorWon.
  ///
  /// In en, this message translates to:
  /// **'WON'**
  String get indicatorWon;

  /// No description provided for @indicatorLost.
  ///
  /// In en, this message translates to:
  /// **'LOST'**
  String get indicatorLost;

  /// No description provided for @indicatorNotSold.
  ///
  /// In en, this message translates to:
  /// **'NOT SOLD'**
  String get indicatorNotSold;

  /// No description provided for @indicatorAwaitingSeller.
  ///
  /// In en, this message translates to:
  /// **'AWAITING SELLER'**
  String get indicatorAwaitingSeller;

  /// No description provided for @indicatorLeading.
  ///
  /// In en, this message translates to:
  /// **'LEADING'**
  String get indicatorLeading;

  /// No description provided for @indicatorOutbid.
  ///
  /// In en, this message translates to:
  /// **'OUTBID'**
  String get indicatorOutbid;

  /// No description provided for @stepPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get stepPaid;

  /// No description provided for @stepShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get stepShipped;

  /// No description provided for @stepDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get stepDelivered;

  /// No description provided for @orderItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get orderItemLabel;

  /// No description provided for @orderFinalPrice.
  ///
  /// In en, this message translates to:
  /// **'Final price'**
  String get orderFinalPrice;

  /// No description provided for @orderSellerLabel.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get orderSellerLabel;

  /// No description provided for @orderBuyerLabel.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get orderBuyerLabel;

  /// No description provided for @orderShippedLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get orderShippedLabel;

  /// No description provided for @orderDeliveredLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderDeliveredLabel;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPayment;

  /// No description provided for @addDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Delivery Address'**
  String get addDeliveryAddress;

  /// No description provided for @waitingForSellerToShip.
  ///
  /// In en, this message translates to:
  /// **'Waiting for seller to ship your item.'**
  String get waitingForSellerToShip;

  /// No description provided for @confirmReceived.
  ///
  /// In en, this message translates to:
  /// **'Confirm Received'**
  String get confirmReceived;

  /// No description provided for @orderCompleteEnjoy.
  ///
  /// In en, this message translates to:
  /// **'Order complete. Enjoy your item!'**
  String get orderCompleteEnjoy;

  /// No description provided for @waitingForBuyerPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for buyer to confirm payment.'**
  String get waitingForBuyerPayment;

  /// No description provided for @waitingForBuyerAddress.
  ///
  /// In en, this message translates to:
  /// **'Waiting for buyer to add a delivery address.'**
  String get waitingForBuyerAddress;

  /// No description provided for @markAsShippedButton.
  ///
  /// In en, this message translates to:
  /// **'Mark as Shipped'**
  String get markAsShippedButton;

  /// No description provided for @waitingForBuyerDelivery.
  ///
  /// In en, this message translates to:
  /// **'Waiting for buyer to confirm delivery.'**
  String get waitingForBuyerDelivery;

  /// No description provided for @orderCompleteFundsReleased.
  ///
  /// In en, this message translates to:
  /// **'Order complete. Funds released.'**
  String get orderCompleteFundsReleased;

  /// No description provided for @reportAProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportAProblem;

  /// No description provided for @newAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'New Address'**
  String get newAddressTitle;

  /// No description provided for @selectAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Address'**
  String get selectAddressTitle;

  /// No description provided for @newAddressItem.
  ///
  /// In en, this message translates to:
  /// **'New address'**
  String get newAddressItem;

  /// No description provided for @allFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required.'**
  String get allFieldsRequired;

  /// No description provided for @saveAndUseAddress.
  ///
  /// In en, this message translates to:
  /// **'Save & Use This Address'**
  String get saveAndUseAddress;

  /// No description provided for @backToSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Back to saved addresses'**
  String get backToSavedAddresses;

  /// No description provided for @markAsShippedSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as Shipped'**
  String get markAsShippedSheetTitle;

  /// No description provided for @trackingNoteOptionalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optionally add a tracking number or note for the buyer.'**
  String get trackingNoteOptionalSubtitle;

  /// No description provided for @trackingNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Tracking note (optional)'**
  String get trackingNoteHint;

  /// No description provided for @confirmShipment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Shipment'**
  String get confirmShipment;

  /// No description provided for @addressLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Label (e.g. Home)'**
  String get addressLabelHint;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameHint;

  /// No description provided for @streetAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Street address'**
  String get streetAddressHint;

  /// No description provided for @cityHint.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityHint;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneHint;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get allCaughtUp;

  /// No description provided for @kycTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get kycTitle;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @idFrontLabel.
  ///
  /// In en, this message translates to:
  /// **'ID Front'**
  String get idFrontLabel;

  /// No description provided for @idFrontHint.
  ///
  /// In en, this message translates to:
  /// **'Front of your national ID card'**
  String get idFrontHint;

  /// No description provided for @idBackLabel.
  ///
  /// In en, this message translates to:
  /// **'ID Back'**
  String get idBackLabel;

  /// No description provided for @idBackHint.
  ///
  /// In en, this message translates to:
  /// **'Back of your national ID card'**
  String get idBackHint;

  /// No description provided for @selfieLabel.
  ///
  /// In en, this message translates to:
  /// **'Selfie'**
  String get selfieLabel;

  /// No description provided for @selfieHint.
  ///
  /// In en, this message translates to:
  /// **'Hold your ID next to your face'**
  String get selfieHint;

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review'**
  String get submitForReview;

  /// No description provided for @kycPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get kycPendingTitle;

  /// No description provided for @kycPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your documents have been submitted and are under review.'**
  String get kycPendingSubtitle;

  /// No description provided for @kycApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity Verified'**
  String get kycApprovedTitle;

  /// No description provided for @kycApprovedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your identity has been confirmed. You can list Land properties.'**
  String get kycApprovedSubtitle;

  /// No description provided for @kycRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Submission Rejected'**
  String get kycRejectedTitle;

  /// No description provided for @kycRejectedDefaultReason.
  ///
  /// In en, this message translates to:
  /// **'Your submission was rejected. Please re-submit with clearer photos.'**
  String get kycRejectedDefaultReason;

  /// No description provided for @kycNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Not Verified'**
  String get kycNoneTitle;

  /// No description provided for @kycNoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit your ID and a selfie to unlock Land listings.'**
  String get kycNoneSubtitle;

  /// No description provided for @myDisputesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Disputes'**
  String get myDisputesTitle;

  /// No description provided for @noDisputes.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any disputes.'**
  String get noDisputes;

  /// No description provided for @disputeCategoryItemNotAsDescribed.
  ///
  /// In en, this message translates to:
  /// **'Item not as described'**
  String get disputeCategoryItemNotAsDescribed;

  /// No description provided for @disputeCategoryItemNotReceived.
  ///
  /// In en, this message translates to:
  /// **'Item not received'**
  String get disputeCategoryItemNotReceived;

  /// No description provided for @disputeCategoryPaymentIssue.
  ///
  /// In en, this message translates to:
  /// **'Payment issue'**
  String get disputeCategoryPaymentIssue;

  /// No description provided for @disputeCategorySellerUnresponsive.
  ///
  /// In en, this message translates to:
  /// **'Seller unresponsive'**
  String get disputeCategorySellerUnresponsive;

  /// No description provided for @disputeCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get disputeCategoryOther;

  /// No description provided for @disputeOtherParty.
  ///
  /// In en, this message translates to:
  /// **'Other party: #{bidderNumber}'**
  String disputeOtherParty(String bidderNumber);

  /// No description provided for @disputeStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get disputeStatusOpen;

  /// No description provided for @disputeStatusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'UNDER REVIEW'**
  String get disputeStatusUnderReview;

  /// No description provided for @disputeStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'RESOLVED'**
  String get disputeStatusResolved;

  /// No description provided for @disputeStatusDismissed.
  ///
  /// In en, this message translates to:
  /// **'DISMISSED'**
  String get disputeStatusDismissed;

  /// No description provided for @reportDisputeTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a Problem'**
  String get reportDisputeTitle;

  /// No description provided for @disputeCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get disputeCategoryLabel;

  /// No description provided for @disputeDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get disputeDescriptionLabel;

  /// No description provided for @disputeDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue in detail…'**
  String get disputeDescriptionHint;

  /// No description provided for @disputeEvidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Evidence (optional)'**
  String get disputeEvidenceLabel;

  /// No description provided for @submitDisputeButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Dispute'**
  String get submitDisputeButton;

  /// No description provided for @selectCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get selectCategoryHint;

  /// No description provided for @attachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach photo'**
  String get attachPhoto;

  /// No description provided for @pleaseDescribeIssue.
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue.'**
  String get pleaseDescribeIssue;

  /// No description provided for @disputeSubmittedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Dispute submitted. Our team will review it shortly.'**
  String get disputeSubmittedSnackbar;

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTitle;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t saved any listings yet.'**
  String get noFavoritesYet;

  /// No description provided for @addressBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Address Book'**
  String get addressBookTitle;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddress;

  /// No description provided for @noAddressesYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t saved any addresses yet.'**
  String get noAddressesYet;

  /// No description provided for @deleteAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete address?'**
  String get deleteAddressTitle;

  /// No description provided for @deleteAddressMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{label}\"?'**
  String deleteAddressMessage(String label);

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefault;

  /// No description provided for @defaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultBadge;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get editAddress;

  /// No description provided for @addressLabelField.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get addressLabelField;

  /// No description provided for @addressLabelFieldHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Home, Work'**
  String get addressLabelFieldHint;

  /// No description provided for @addressFullNameField.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get addressFullNameField;

  /// No description provided for @addressStreetField.
  ///
  /// In en, this message translates to:
  /// **'Street / address'**
  String get addressStreetField;

  /// No description provided for @addressCityField.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get addressCityField;

  /// No description provided for @addressCountryField.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get addressCountryField;

  /// No description provided for @addressPhoneField.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get addressPhoneField;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutTitle;

  /// No description provided for @aboutBody1.
  ///
  /// In en, this message translates to:
  /// **'Mazad is a Mauritanian online auction platform that lets users participate in live auctions and buy or sell cars, real estate, and goods with ease and transparency.'**
  String get aboutBody1;

  /// No description provided for @aboutBody2.
  ///
  /// In en, this message translates to:
  /// **'Our mission is to modernise the auction experience in Mauritania by providing a trusted digital platform that gives sellers access to more buyers and gives buyers real opportunities to get better value for their money.'**
  String get aboutBody2;

  /// No description provided for @aboutBody3.
  ///
  /// In en, this message translates to:
  /// **'Sellers create listings for items they wish to sell and set a start and end time for the auction. Interested buyers submit bids in real time, and the winner is the highest bidder when the auction closes.'**
  String get aboutBody3;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get appVersion;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Mazad. All rights reserved.'**
  String get copyright;

  /// No description provided for @contactSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact & Support'**
  String get contactSupportTitle;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'CONTACT US'**
  String get contactUs;

  /// No description provided for @faqSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'FREQUENTLY ASKED QUESTIONS'**
  String get faqSectionTitle;

  /// No description provided for @faq1Question.
  ///
  /// In en, this message translates to:
  /// **'How do I place a bid?'**
  String get faq1Question;

  /// No description provided for @faq1Answer.
  ///
  /// In en, this message translates to:
  /// **'Open any live auction listing and tap the \"Place Bid\" button. Enter an amount above the current highest bid and confirm. Your bid is submitted instantly.'**
  String get faq1Answer;

  /// No description provided for @faq2Question.
  ///
  /// In en, this message translates to:
  /// **'Can I cancel a bid after placing it?'**
  String get faq2Question;

  /// No description provided for @faq2Answer.
  ///
  /// In en, this message translates to:
  /// **'Bids are binding once submitted and cannot be cancelled. Please review the listing details carefully before bidding.'**
  String get faq2Answer;

  /// No description provided for @faq3Question.
  ///
  /// In en, this message translates to:
  /// **'How do I sell an item on Mazad?'**
  String get faq3Question;

  /// No description provided for @faq3Answer.
  ///
  /// In en, this message translates to:
  /// **'Go to the Sell tab, fill in the listing details including title, category, starting price, and auction dates, then submit. Your listing will be reviewed before going live.'**
  String get faq3Answer;

  /// No description provided for @faq4Question.
  ///
  /// In en, this message translates to:
  /// **'What payment methods are accepted?'**
  String get faq4Question;

  /// No description provided for @faq4Answer.
  ///
  /// In en, this message translates to:
  /// **'Payment terms are agreed between buyer and seller after the auction closes. Mazad currently facilitates the auction process; direct payment integration is coming soon.'**
  String get faq4Answer;

  /// No description provided for @faq5Question.
  ///
  /// In en, this message translates to:
  /// **'What happens if I win an auction?'**
  String get faq5Question;

  /// No description provided for @faq5Answer.
  ///
  /// In en, this message translates to:
  /// **'You will receive a notification when you win. The seller will be notified to confirm the sale. You can then coordinate delivery and payment through the order details screen.'**
  String get faq5Answer;

  /// No description provided for @faq6Question.
  ///
  /// In en, this message translates to:
  /// **'How do I verify my identity (KYC)?'**
  String get faq6Question;

  /// No description provided for @faq6Answer.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile → Identity Verification and follow the steps to upload your ID document. Verification typically takes 1–2 business days.'**
  String get faq6Answer;

  /// No description provided for @faq7Question.
  ///
  /// In en, this message translates to:
  /// **'How do I open a dispute?'**
  String get faq7Question;

  /// No description provided for @faq7Answer.
  ///
  /// In en, this message translates to:
  /// **'If you have an issue with a completed auction, go to Profile → My Disputes and tap \"Report a Dispute\". Provide a clear description and our team will review it within 3 business days.'**
  String get faq7Answer;

  /// No description provided for @faq8Question.
  ///
  /// In en, this message translates to:
  /// **'How do I delete my account?'**
  String get faq8Question;

  /// No description provided for @faq8Answer.
  ///
  /// In en, this message translates to:
  /// **'Contact our support team at projectestingemail@gmail.com and request account deletion. We will process it within 7 business days in accordance with applicable data protection regulations.'**
  String get faq8Answer;

  /// No description provided for @liveAuctionEndedLabel.
  ///
  /// In en, this message translates to:
  /// **'AUCTION ENDED'**
  String get liveAuctionEndedLabel;

  /// No description provided for @liveAuctionLiveLabel.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveAuctionLiveLabel;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get reconnecting;

  /// No description provided for @connectionLostRetry.
  ///
  /// In en, this message translates to:
  /// **'Connection lost — tap to retry'**
  String get connectionLostRetry;

  /// No description provided for @endingSoon.
  ///
  /// In en, this message translates to:
  /// **'ending soon'**
  String get endingSoon;

  /// No description provided for @calculatingResultLabel.
  ///
  /// In en, this message translates to:
  /// **'calculating result…'**
  String get calculatingResultLabel;

  /// No description provided for @waitingForFirstBid.
  ///
  /// In en, this message translates to:
  /// **'Waiting for first bid…'**
  String get waitingForFirstBid;

  /// No description provided for @recentBids.
  ///
  /// In en, this message translates to:
  /// **'RECENT BIDS'**
  String get recentBids;

  /// No description provided for @couldntReachServer.
  ///
  /// In en, this message translates to:
  /// **'COULDN\'T REACH THE SERVER'**
  String get couldntReachServer;

  /// No description provided for @checkConnectionRetry.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkConnectionRetry;

  /// No description provided for @youWon.
  ///
  /// In en, this message translates to:
  /// **'YOU WON'**
  String get youWon;

  /// No description provided for @auctionEndedHeadline.
  ///
  /// In en, this message translates to:
  /// **'AUCTION ENDED'**
  String get auctionEndedHeadline;

  /// No description provided for @reserveNotMet.
  ///
  /// In en, this message translates to:
  /// **'RESERVE NOT MET'**
  String get reserveNotMet;

  /// No description provided for @calculatingResultHeadline.
  ///
  /// In en, this message translates to:
  /// **'CALCULATING RESULT'**
  String get calculatingResultHeadline;

  /// No description provided for @finalPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Final price: {amount}'**
  String finalPriceLabel(String amount);

  /// No description provided for @soldToOther.
  ///
  /// In en, this message translates to:
  /// **'Sold to {bidder} · {amount}'**
  String soldToOther(String bidder, String amount);

  /// No description provided for @awaitingSellerDecision.
  ///
  /// In en, this message translates to:
  /// **'Awaiting seller\'s decision'**
  String get awaitingSellerDecision;

  /// No description provided for @noBidsMetReserve.
  ///
  /// In en, this message translates to:
  /// **'No bids met the reserve'**
  String get noBidsMetReserve;

  /// No description provided for @youreLeading.
  ///
  /// In en, this message translates to:
  /// **'You\'re leading'**
  String get youreLeading;

  /// No description provided for @youveBeenOutbid.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been outbid  ·  {bidder} leads'**
  String youveBeenOutbid(String bidder);

  /// No description provided for @noBidsYet.
  ///
  /// In en, this message translates to:
  /// **'No bids yet'**
  String get noBidsYet;

  /// No description provided for @loadingBidButton.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingBidButton;

  /// No description provided for @bidButton.
  ///
  /// In en, this message translates to:
  /// **'Bid {amount}'**
  String bidButton(String amount);

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error — please try again.'**
  String get networkError;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotos;

  /// No description provided for @listingPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing Photos'**
  String get listingPhotosTitle;

  /// No description provided for @listingPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add up to 5 photos. The first photo will be the listing thumbnail.'**
  String get listingPhotosSubtitle;

  /// No description provided for @addPhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhotoButton;

  /// No description provided for @skipPhotos.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipPhotos;

  /// No description provided for @uploadPhotos.
  ///
  /// In en, this message translates to:
  /// **'Upload Photos'**
  String get uploadPhotos;

  /// No description provided for @uploadingPhotoProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading {current} of {total}…'**
  String uploadingPhotoProgress(int current, int total);

  /// No description provided for @photoUploadDone.
  ///
  /// In en, this message translates to:
  /// **'Photos added to your listing.'**
  String get photoUploadDone;

  /// No description provided for @maxPhotosReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 photos reached.'**
  String get maxPhotosReached;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
