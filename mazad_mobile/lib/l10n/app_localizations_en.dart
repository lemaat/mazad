// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get required => 'Required';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get couldNotReachServer => 'Could not reach the server.';

  @override
  String get somethingWentWrong => 'Something went wrong.';

  @override
  String get somethingWentWrongTryAgain =>
      'Something went wrong. Please try again.';

  @override
  String get navFeed => 'Feed';

  @override
  String get navLive => 'Live';

  @override
  String get navWallet => 'Wallet';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get navProfile => 'Profile';

  @override
  String get signInToSeeNotifications => 'Sign in to see notifications';

  @override
  String get createListingTooltip => 'Create listing';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get password => 'Password';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get register => 'Register';

  @override
  String get accountCreated => 'Account created';

  @override
  String get yourBidderNumber => 'Your bidder number is:';

  @override
  String get bidderNumberSaveNote =>
      'This is how you appear at auctions. Save it somewhere safe.';

  @override
  String get continueBtnLabel => 'Continue';

  @override
  String get displayName => 'Display name';

  @override
  String get displayNameHint => 'Shown to other bidders';

  @override
  String get onboardingTitle1 => 'Live Auctions';

  @override
  String get onboardingBody1 =>
      'Bid on cars, real estate, and goods in real time. Watch prices update live and never miss a beat.';

  @override
  String get onboardingTitle2 => 'Sell with Confidence';

  @override
  String get onboardingBody2 =>
      'List your items in minutes and reach verified buyers across Mauritania.';

  @override
  String get onboardingTitle3 => 'Stay in the Loop';

  @override
  String get onboardingBody3 =>
      'Get notified when you\'re outbid, when an auction ends, or when your listing gets its first offer.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get profile => 'Profile';

  @override
  String get sectionTrading => 'TRADING';

  @override
  String get myListings => 'My Listings';

  @override
  String get myBids => 'My Bids';

  @override
  String get saved => 'Saved';

  @override
  String get addressBook => 'Address Book';

  @override
  String get sectionSupport => 'SUPPORT';

  @override
  String get myDisputes => 'My Disputes';

  @override
  String get contactAndSupport => 'Contact & Support';

  @override
  String get aboutUs => 'About Us';

  @override
  String get sectionPreferences => 'PREFERENCES';

  @override
  String get sectionAccount => 'ACCOUNT';

  @override
  String get identityVerification => 'Identity Verification';

  @override
  String get signOut => 'Sign out';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get verifiedBadge => 'Verified';

  @override
  String get pendingBadge => 'Pending';

  @override
  String get signOutDialogTitle => 'Sign out?';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageArabic => 'العربية';

  @override
  String get searchListingsHint => 'Search listings…';

  @override
  String get mazadAppBarTitle => 'Mazad';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryCars => 'Cars';

  @override
  String get categoryLand => 'Land';

  @override
  String get categoryGoods => 'Goods';

  @override
  String get statusLive => 'Live';

  @override
  String get statusUpcoming => 'Upcoming';

  @override
  String get statusPendingDecision => 'Pending decision';

  @override
  String get statusSold => 'Sold';

  @override
  String get statusUnsold => 'Unsold';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusPendingPayment => 'Pending payment';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusBadgeLive => 'LIVE';

  @override
  String get statusBadgeUpcoming => 'UPCOMING';

  @override
  String get statusBadgePending => 'PENDING';

  @override
  String get statusBadgeSold => 'SOLD';

  @override
  String get statusBadgeUnsold => 'UNSOLD';

  @override
  String get timeEnded => 'Ended';

  @override
  String get timeStarted => 'Started';

  @override
  String get timeHasStarted => 'Has started';

  @override
  String endsIn(String timeLeft) {
    return 'Ends in $timeLeft';
  }

  @override
  String startsIn(String timeLeft) {
    return 'Starts in $timeLeft';
  }

  @override
  String priceFrom(String price) {
    return 'From $price';
  }

  @override
  String bidCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bids',
      one: '$count bid',
    );
    return '$_temp0';
  }

  @override
  String get noListingsAvailable => 'No listings available right now.';

  @override
  String noListingsInCategory(String category) {
    return 'No $category listings right now.';
  }

  @override
  String get currentBid => 'Current bid';

  @override
  String get startingPrice => 'Starting price';

  @override
  String get minimumIncrement => 'Minimum increment';

  @override
  String get auctionOpens => 'Auction opens';

  @override
  String get auctionCloses => 'Auction closes';

  @override
  String get timeRemaining => 'Time remaining';

  @override
  String get softCloseWindow => 'Soft-close window';

  @override
  String softCloseWindowValue(int count) {
    return '$count min';
  }

  @override
  String get descriptionSectionLabel => 'Description';

  @override
  String get depositNote =>
      'A refundable deposit is required to participate. Your deposit determines your maximum bid ceiling (10× your deposit).';

  @override
  String get auctionEndedDecisionRequired =>
      'Auction ended — decision required';

  @override
  String get winningBid => 'Winning bid';

  @override
  String get runnerUpBidder => 'Runner-up bidder';

  @override
  String get secondChanceDeadline => 'Second chance deadline';

  @override
  String get sellerReviewingResult =>
      'The seller is reviewing the auction result.';

  @override
  String get secondChanceOfferedTitle => 'Second chance offered!';

  @override
  String get yourOfferPrice => 'Your offer price';

  @override
  String get expiresLabel => 'Expires';

  @override
  String get endUnsoldButton => 'End Unsold';

  @override
  String get secondChanceButton => 'Second Chance';

  @override
  String get acceptSecondChanceButton => 'Accept Second Chance';

  @override
  String get joinAuction => 'Join Auction';

  @override
  String get signInToBid => 'Sign in to bid';

  @override
  String get depositRequired => 'Deposit Required';

  @override
  String get yourIntendedMaxBid => 'Your intended maximum bid';

  @override
  String get availableBalance => 'Available balance';

  @override
  String placeDeposit(String amount) {
    return 'Place Deposit — $amount';
  }

  @override
  String get enterIntendedBidAbove => 'Enter your intended bid above';

  @override
  String get requiredDepositLabel => 'Required deposit (1/10 of max bid)';

  @override
  String get yourBidCeiling => 'Your bid ceiling';

  @override
  String get liveAuctions => 'Live Auctions';

  @override
  String get liveNow => 'LIVE NOW';

  @override
  String get comingUp => 'COMING UP';

  @override
  String get noLiveOrUpcomingAuctions =>
      'No live or upcoming auctions right now.';

  @override
  String get startingSoon => 'Starting soon';

  @override
  String get createListingStepCategory => 'Category';

  @override
  String get createListingStepDetails => 'Details';

  @override
  String get createListingStepPricing => 'Pricing & Schedule';

  @override
  String get idVerificationRequired => 'ID Verification Required';

  @override
  String idVerificationRequiredMessage(String categoryName) {
    return '$categoryName listings require identity verification. Submit your ID to unlock this category.';
  }

  @override
  String get verifyNow => 'Verify Now';

  @override
  String listingFeeDisplay(String fee) {
    return 'Listing fee: $fee';
  }

  @override
  String get requiresIdVerification => 'Requires ID verification';

  @override
  String get nextDetails => 'Next: Details';

  @override
  String get nextPricing => 'Next: Pricing';

  @override
  String get reviewAndPay => 'Review & Pay';

  @override
  String get creatingListing => 'Creating…';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleHint => 'e.g. 2019 Toyota Land Cruiser';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionHint =>
      'Describe the item — condition, specs, any defects…';

  @override
  String get photosAddedAfterPublishing =>
      'Photos can be added after publishing.';

  @override
  String get startingPriceMru => 'Starting price (MRU)';

  @override
  String get reservePriceMru => 'Reserve price (MRU)';

  @override
  String get reservePriceNote => 'Hidden from bidders. Minimum you\'ll accept.';

  @override
  String get minBidIncrementMru => 'Min bid increment (MRU)';

  @override
  String get auctionStartLabel => 'Auction start';

  @override
  String get auctionEndLabel => 'Auction end';

  @override
  String get listingFeeTitle => 'Listing Fee';

  @override
  String get testModeBanner =>
      'TEST MODE — no real charge. Sedad integration not yet wired.';

  @override
  String get listingSummaryLabel => 'Listing summary';

  @override
  String get platformListingFee => 'Platform listing fee';

  @override
  String get sedadProductionNote =>
      'In production, payment will be collected via Sedad before the listing is published.';

  @override
  String get listingPublished => 'Listing published!';

  @override
  String listingPublishedBody(String title) {
    return '\"$title\" is now scheduled. Bidders will be able to join once the auction starts.';
  }

  @override
  String get processing => 'Processing…';

  @override
  String confirmStub(String fee) {
    return 'Confirm (stub — $fee not charged)';
  }

  @override
  String get sectionActive => 'ACTIVE';

  @override
  String get sectionPending => 'PENDING';

  @override
  String get sectionCompleted => 'COMPLETED';

  @override
  String get noListingsYet => 'You have no listings yet.';

  @override
  String get wallet => 'Wallet';

  @override
  String get signInToViewWallet => 'Sign in to view your wallet';

  @override
  String get walletBalanceWillAppear =>
      'Your balance and active deposits will appear here.';

  @override
  String get activeDeposits => 'ACTIVE DEPOSITS';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get available => 'Available';

  @override
  String get inDeposits => 'In deposits';

  @override
  String get noActiveDeposits =>
      'No active deposits.\nBrowse listings and join an auction to place a deposit.';

  @override
  String bidCeilingLabel(String amount) {
    return 'Bid ceiling: $amount';
  }

  @override
  String get activeAuctions => 'ACTIVE AUCTIONS';

  @override
  String get pastAuctions => 'PAST AUCTIONS';

  @override
  String get noPlacedBids => 'You haven\'t placed any bids yet.';

  @override
  String get myBidLabel => 'My bid';

  @override
  String get currentBidShortLabel => 'Current';

  @override
  String get indicatorWon => 'WON';

  @override
  String get indicatorLost => 'LOST';

  @override
  String get indicatorNotSold => 'NOT SOLD';

  @override
  String get indicatorAwaitingSeller => 'AWAITING SELLER';

  @override
  String get indicatorLeading => 'LEADING';

  @override
  String get indicatorOutbid => 'OUTBID';

  @override
  String get stepPaid => 'Paid';

  @override
  String get stepShipped => 'Shipped';

  @override
  String get stepDelivered => 'Delivered';

  @override
  String get orderItemLabel => 'Item';

  @override
  String get orderFinalPrice => 'Final price';

  @override
  String get orderSellerLabel => 'Seller';

  @override
  String get orderBuyerLabel => 'Buyer';

  @override
  String get orderShippedLabel => 'Shipped';

  @override
  String get orderDeliveredLabel => 'Delivered';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get confirmPayment => 'Confirm Payment';

  @override
  String get addDeliveryAddress => 'Add Delivery Address';

  @override
  String get waitingForSellerToShip => 'Waiting for seller to ship your item.';

  @override
  String get confirmReceived => 'Confirm Received';

  @override
  String get orderCompleteEnjoy => 'Order complete. Enjoy your item!';

  @override
  String get waitingForBuyerPayment => 'Waiting for buyer to confirm payment.';

  @override
  String get waitingForBuyerAddress =>
      'Waiting for buyer to add a delivery address.';

  @override
  String get markAsShippedButton => 'Mark as Shipped';

  @override
  String get waitingForBuyerDelivery =>
      'Waiting for buyer to confirm delivery.';

  @override
  String get orderCompleteFundsReleased => 'Order complete. Funds released.';

  @override
  String get reportAProblem => 'Report a problem';

  @override
  String get newAddressTitle => 'New Address';

  @override
  String get selectAddressTitle => 'Select Address';

  @override
  String get newAddressItem => 'New address';

  @override
  String get allFieldsRequired => 'All fields are required.';

  @override
  String get saveAndUseAddress => 'Save & Use This Address';

  @override
  String get backToSavedAddresses => 'Back to saved addresses';

  @override
  String get markAsShippedSheetTitle => 'Mark as Shipped';

  @override
  String get trackingNoteOptionalSubtitle =>
      'Optionally add a tracking number or note for the buyer.';

  @override
  String get trackingNoteHint => 'Tracking note (optional)';

  @override
  String get confirmShipment => 'Confirm Shipment';

  @override
  String get addressLabelHint => 'Label (e.g. Home)';

  @override
  String get fullNameHint => 'Full name';

  @override
  String get streetAddressHint => 'Street address';

  @override
  String get cityHint => 'City';

  @override
  String get phoneHint => 'Phone';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get allCaughtUp => 'You\'re all caught up.';

  @override
  String get kycTitle => 'Identity Verification';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get idFrontLabel => 'ID Front';

  @override
  String get idFrontHint => 'Front of your national ID card';

  @override
  String get idBackLabel => 'ID Back';

  @override
  String get idBackHint => 'Back of your national ID card';

  @override
  String get selfieLabel => 'Selfie';

  @override
  String get selfieHint => 'Hold your ID next to your face';

  @override
  String get submitForReview => 'Submit for Review';

  @override
  String get kycPendingTitle => 'Pending Review';

  @override
  String get kycPendingSubtitle =>
      'Your documents have been submitted and are under review.';

  @override
  String get kycApprovedTitle => 'Identity Verified';

  @override
  String get kycApprovedSubtitle =>
      'Your identity has been confirmed. You can list Land properties.';

  @override
  String get kycRejectedTitle => 'Submission Rejected';

  @override
  String get kycRejectedDefaultReason =>
      'Your submission was rejected. Please re-submit with clearer photos.';

  @override
  String get kycNoneTitle => 'Not Verified';

  @override
  String get kycNoneSubtitle =>
      'Submit your ID and a selfie to unlock Land listings.';

  @override
  String get myDisputesTitle => 'My Disputes';

  @override
  String get noDisputes => 'You don\'t have any disputes.';

  @override
  String get disputeCategoryItemNotAsDescribed => 'Item not as described';

  @override
  String get disputeCategoryItemNotReceived => 'Item not received';

  @override
  String get disputeCategoryPaymentIssue => 'Payment issue';

  @override
  String get disputeCategorySellerUnresponsive => 'Seller unresponsive';

  @override
  String get disputeCategoryOther => 'Other';

  @override
  String disputeOtherParty(String bidderNumber) {
    return 'Other party: #$bidderNumber';
  }

  @override
  String get disputeStatusOpen => 'OPEN';

  @override
  String get disputeStatusUnderReview => 'UNDER REVIEW';

  @override
  String get disputeStatusResolved => 'RESOLVED';

  @override
  String get disputeStatusDismissed => 'DISMISSED';

  @override
  String get reportDisputeTitle => 'Report a Problem';

  @override
  String get disputeCategoryLabel => 'Category';

  @override
  String get disputeDescriptionLabel => 'Description';

  @override
  String get disputeDescriptionHint => 'Describe the issue in detail…';

  @override
  String get disputeEvidenceLabel => 'Evidence (optional)';

  @override
  String get submitDisputeButton => 'Submit Dispute';

  @override
  String get selectCategoryHint => 'Select a category';

  @override
  String get attachPhoto => 'Attach photo';

  @override
  String get pleaseDescribeIssue => 'Please describe the issue.';

  @override
  String get disputeSubmittedSnackbar =>
      'Dispute submitted. Our team will review it shortly.';

  @override
  String get savedTitle => 'Saved';

  @override
  String get noFavoritesYet => 'You haven\'t saved any listings yet.';

  @override
  String get addressBookTitle => 'Address Book';

  @override
  String get addAddress => 'Add address';

  @override
  String get noAddressesYet => 'You haven\'t saved any addresses yet.';

  @override
  String get deleteAddressTitle => 'Delete address?';

  @override
  String deleteAddressMessage(String label) {
    return 'Remove \"$label\"?';
  }

  @override
  String get setAsDefault => 'Set as default';

  @override
  String get defaultBadge => 'Default';

  @override
  String get editAddress => 'Edit Address';

  @override
  String get addressLabelField => 'Label';

  @override
  String get addressLabelFieldHint => 'e.g. Home, Work';

  @override
  String get addressFullNameField => 'Full name';

  @override
  String get addressStreetField => 'Street / address';

  @override
  String get addressCityField => 'City';

  @override
  String get addressCountryField => 'Country';

  @override
  String get addressPhoneField => 'Phone';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get aboutTitle => 'About Us';

  @override
  String get aboutBody1 =>
      'Mazad is a Mauritanian online auction platform that lets users participate in live auctions and buy or sell cars, real estate, and goods with ease and transparency.';

  @override
  String get aboutBody2 =>
      'Our mission is to modernise the auction experience in Mauritania by providing a trusted digital platform that gives sellers access to more buyers and gives buyers real opportunities to get better value for their money.';

  @override
  String get aboutBody3 =>
      'Sellers create listings for items they wish to sell and set a start and end time for the auction. Interested buyers submit bids in real time, and the winner is the highest bidder when the auction closes.';

  @override
  String get appVersion => 'Version 1.0.0';

  @override
  String get copyright => '© 2026 Mazad. All rights reserved.';

  @override
  String get contactSupportTitle => 'Contact & Support';

  @override
  String get contactUs => 'CONTACT US';

  @override
  String get faqSectionTitle => 'FREQUENTLY ASKED QUESTIONS';

  @override
  String get faq1Question => 'How do I place a bid?';

  @override
  String get faq1Answer =>
      'Open any live auction listing and tap the \"Place Bid\" button. Enter an amount above the current highest bid and confirm. Your bid is submitted instantly.';

  @override
  String get faq2Question => 'Can I cancel a bid after placing it?';

  @override
  String get faq2Answer =>
      'Bids are binding once submitted and cannot be cancelled. Please review the listing details carefully before bidding.';

  @override
  String get faq3Question => 'How do I sell an item on Mazad?';

  @override
  String get faq3Answer =>
      'Go to the Sell tab, fill in the listing details including title, category, starting price, and auction dates, then submit. Your listing will be reviewed before going live.';

  @override
  String get faq4Question => 'What payment methods are accepted?';

  @override
  String get faq4Answer =>
      'Payment terms are agreed between buyer and seller after the auction closes. Mazad currently facilitates the auction process; direct payment integration is coming soon.';

  @override
  String get faq5Question => 'What happens if I win an auction?';

  @override
  String get faq5Answer =>
      'You will receive a notification when you win. The seller will be notified to confirm the sale. You can then coordinate delivery and payment through the order details screen.';

  @override
  String get faq6Question => 'How do I verify my identity (KYC)?';

  @override
  String get faq6Answer =>
      'Go to Profile → Identity Verification and follow the steps to upload your ID document. Verification typically takes 1–2 business days.';

  @override
  String get faq7Question => 'How do I open a dispute?';

  @override
  String get faq7Answer =>
      'If you have an issue with a completed auction, go to Profile → My Disputes and tap \"Report a Dispute\". Provide a clear description and our team will review it within 3 business days.';

  @override
  String get faq8Question => 'How do I delete my account?';

  @override
  String get faq8Answer =>
      'Contact our support team at projectestingemail@gmail.com and request account deletion. We will process it within 7 business days in accordance with applicable data protection regulations.';

  @override
  String get liveAuctionEndedLabel => 'AUCTION ENDED';

  @override
  String get liveAuctionLiveLabel => 'LIVE';

  @override
  String get reconnecting => 'Reconnecting…';

  @override
  String get connectionLostRetry => 'Connection lost — tap to retry';

  @override
  String get endingSoon => 'ending soon';

  @override
  String get calculatingResultLabel => 'calculating result…';

  @override
  String get waitingForFirstBid => 'Waiting for first bid…';

  @override
  String get recentBids => 'RECENT BIDS';

  @override
  String get couldntReachServer => 'COULDN\'T REACH THE SERVER';

  @override
  String get checkConnectionRetry => 'Check your connection and try again.';

  @override
  String get youWon => 'YOU WON';

  @override
  String get auctionEndedHeadline => 'AUCTION ENDED';

  @override
  String get reserveNotMet => 'RESERVE NOT MET';

  @override
  String get calculatingResultHeadline => 'CALCULATING RESULT';

  @override
  String finalPriceLabel(String amount) {
    return 'Final price: $amount';
  }

  @override
  String soldToOther(String bidder, String amount) {
    return 'Sold to $bidder · $amount';
  }

  @override
  String get awaitingSellerDecision => 'Awaiting seller\'s decision';

  @override
  String get noBidsMetReserve => 'No bids met the reserve';

  @override
  String get youreLeading => 'You\'re leading';

  @override
  String youveBeenOutbid(String bidder) {
    return 'You\'ve been outbid  ·  $bidder leads';
  }

  @override
  String get noBidsYet => 'No bids yet';

  @override
  String get loadingBidButton => 'Loading…';

  @override
  String bidButton(String amount) {
    return 'Bid $amount';
  }

  @override
  String get networkError => 'Network error — please try again.';

  @override
  String get addPhotos => 'Add Photos';

  @override
  String get listingPhotosTitle => 'Listing Photos';

  @override
  String get listingPhotosSubtitle =>
      'Add up to 5 photos. The first photo will be the listing thumbnail.';

  @override
  String get addPhotoButton => 'Add Photo';

  @override
  String get skipPhotos => 'Skip';

  @override
  String get uploadPhotos => 'Upload Photos';

  @override
  String uploadingPhotoProgress(int current, int total) {
    return 'Uploading $current of $total…';
  }

  @override
  String get photoUploadDone => 'Photos added to your listing.';

  @override
  String get maxPhotosReached => 'Maximum 5 photos reached.';
}
