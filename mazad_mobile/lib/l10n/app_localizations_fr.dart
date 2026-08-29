// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get signIn => 'Se connecter';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get required => 'Requis';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get done => 'Terminé';

  @override
  String get couldNotReachServer => 'Impossible de joindre le serveur.';

  @override
  String get somethingWentWrong => 'Une erreur est survenue.';

  @override
  String get somethingWentWrongTryAgain =>
      'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get navFeed => 'Fil';

  @override
  String get navLive => 'En direct';

  @override
  String get navWallet => 'Portefeuille';

  @override
  String get navAlerts => 'Alertes';

  @override
  String get navProfile => 'Profil';

  @override
  String get signInToSeeNotifications =>
      'Connectez-vous pour voir les notifications';

  @override
  String get createListingTooltip => 'Créer une annonce';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get password => 'Mot de passe';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte ? ';

  @override
  String get register => 'S\'inscrire';

  @override
  String get accountCreated => 'Compte créé';

  @override
  String get yourBidderNumber => 'Votre numéro d\'enchérisseur est :';

  @override
  String get bidderNumberSaveNote =>
      'C\'est ainsi que vous apparaissez aux enchères. Conservez-le en lieu sûr.';

  @override
  String get continueBtnLabel => 'Continuer';

  @override
  String get displayName => 'Nom d\'affichage';

  @override
  String get displayNameHint => 'Visible par les autres enchérisseurs';

  @override
  String get onboardingTitle1 => 'Enchères en direct';

  @override
  String get onboardingBody1 =>
      'Enchérissez sur des voitures, des biens immobiliers et des marchandises en temps réel. Regardez les prix évoluer en direct et ne manquez rien.';

  @override
  String get onboardingTitle2 => 'Vendez en toute confiance';

  @override
  String get onboardingBody2 =>
      'Publiez vos annonces en quelques minutes et atteignez des acheteurs vérifiés en Mauritanie.';

  @override
  String get onboardingTitle3 => 'Restez informé';

  @override
  String get onboardingBody3 =>
      'Recevez des notifications lorsque vous êtes surenchéri, lorsqu\'une enchère se termine ou lorsque votre annonce reçoit sa première offre.';

  @override
  String get skip => 'Passer';

  @override
  String get next => 'Suivant';

  @override
  String get getStarted => 'Commencer';

  @override
  String get profile => 'Profil';

  @override
  String get sectionTrading => 'COMMERCE';

  @override
  String get myListings => 'Mes annonces';

  @override
  String get myBids => 'Mes offres';

  @override
  String get saved => 'Enregistrés';

  @override
  String get addressBook => 'Carnet d\'adresses';

  @override
  String get sectionSupport => 'ASSISTANCE';

  @override
  String get myDisputes => 'Mes litiges';

  @override
  String get contactAndSupport => 'Contact et assistance';

  @override
  String get aboutUs => 'À propos';

  @override
  String get sectionPreferences => 'PRÉFÉRENCES';

  @override
  String get sectionAccount => 'COMPTE';

  @override
  String get identityVerification => 'Vérification d\'identité';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get verifiedBadge => 'Vérifié';

  @override
  String get pendingBadge => 'En attente';

  @override
  String get signOutDialogTitle => 'Se déconnecter ?';

  @override
  String get languageLabel => 'Langue';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageArabic => 'العربية';

  @override
  String get searchListingsHint => 'Rechercher des annonces…';

  @override
  String get mazadAppBarTitle => 'Mazad';

  @override
  String get categoryAll => 'Tous';

  @override
  String get categoryCars => 'Voitures';

  @override
  String get categoryLand => 'Terrains';

  @override
  String get categoryGoods => 'Biens';

  @override
  String get statusLive => 'En direct';

  @override
  String get statusUpcoming => 'À venir';

  @override
  String get statusPendingDecision => 'Décision en attente';

  @override
  String get statusSold => 'Vendu';

  @override
  String get statusUnsold => 'Non vendu';

  @override
  String get statusDraft => 'Brouillon';

  @override
  String get statusPendingPayment => 'Paiement en attente';

  @override
  String get statusCancelled => 'Annulé';

  @override
  String get statusBadgeLive => 'EN DIRECT';

  @override
  String get statusBadgeUpcoming => 'À VENIR';

  @override
  String get statusBadgePending => 'EN ATTENTE';

  @override
  String get statusBadgeSold => 'VENDU';

  @override
  String get statusBadgeUnsold => 'NON VENDU';

  @override
  String get timeEnded => 'Terminé';

  @override
  String get timeStarted => 'Commencé';

  @override
  String get timeHasStarted => 'A commencé';

  @override
  String endsIn(String timeLeft) {
    return 'Fin dans $timeLeft';
  }

  @override
  String startsIn(String timeLeft) {
    return 'Début dans $timeLeft';
  }

  @override
  String priceFrom(String price) {
    return 'À partir de $price';
  }

  @override
  String bidCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offres',
      one: '$count offre',
    );
    return '$_temp0';
  }

  @override
  String get noListingsAvailable =>
      'Aucune annonce disponible pour l\'instant.';

  @override
  String noListingsInCategory(String category) {
    return 'Aucune annonce $category pour l\'instant.';
  }

  @override
  String get currentBid => 'Offre actuelle';

  @override
  String get startingPrice => 'Prix de départ';

  @override
  String get minimumIncrement => 'Incrément minimum';

  @override
  String get auctionOpens => 'Ouverture de l\'enchère';

  @override
  String get auctionCloses => 'Clôture de l\'enchère';

  @override
  String get timeRemaining => 'Temps restant';

  @override
  String get softCloseWindow => 'Fenêtre de clôture souple';

  @override
  String softCloseWindowValue(int count) {
    return '$count min';
  }

  @override
  String get descriptionSectionLabel => 'Description';

  @override
  String get depositNote =>
      'Un dépôt remboursable est requis pour participer. Votre dépôt détermine votre plafond d\'enchère maximum (10× votre dépôt).';

  @override
  String get auctionEndedDecisionRequired =>
      'Enchère terminée — décision requise';

  @override
  String get winningBid => 'Offre gagnante';

  @override
  String get runnerUpBidder => 'Deuxième enchérisseur';

  @override
  String get secondChanceDeadline => 'Délai de deuxième chance';

  @override
  String get sellerReviewingResult =>
      'Le vendeur examine le résultat de l\'enchère.';

  @override
  String get secondChanceOfferedTitle => 'Deuxième chance proposée !';

  @override
  String get yourOfferPrice => 'Votre prix proposé';

  @override
  String get expiresLabel => 'Expire le';

  @override
  String get endUnsoldButton => 'Clore sans vente';

  @override
  String get secondChanceButton => 'Deuxième chance';

  @override
  String get acceptSecondChanceButton => 'Accepter la deuxième chance';

  @override
  String get joinAuction => 'Rejoindre l\'enchère';

  @override
  String get signInToBid => 'Se connecter pour enchérir';

  @override
  String get depositRequired => 'Dépôt requis';

  @override
  String get yourIntendedMaxBid => 'Votre offre maximum souhaitée';

  @override
  String get availableBalance => 'Solde disponible';

  @override
  String placeDeposit(String amount) {
    return 'Déposer la caution — $amount';
  }

  @override
  String get enterIntendedBidAbove =>
      'Saisissez votre offre souhaitée ci-dessus';

  @override
  String get requiredDepositLabel => 'Caution requise (1/10 de l\'offre max)';

  @override
  String get yourBidCeiling => 'Votre plafond d\'enchère';

  @override
  String get liveAuctions => 'Enchères en direct';

  @override
  String get liveNow => 'EN DIRECT';

  @override
  String get comingUp => 'À VENIR';

  @override
  String get noLiveOrUpcomingAuctions =>
      'Aucune enchère en direct ou à venir pour l\'instant.';

  @override
  String get startingSoon => 'Bientôt';

  @override
  String get createListingStepCategory => 'Catégorie';

  @override
  String get createListingStepDetails => 'Détails';

  @override
  String get createListingStepPricing => 'Prix et calendrier';

  @override
  String get idVerificationRequired => 'Vérification d\'identité requise';

  @override
  String idVerificationRequiredMessage(String categoryName) {
    return 'Les annonces $categoryName requièrent une vérification d\'identité. Soumettez votre pièce d\'identité pour débloquer cette catégorie.';
  }

  @override
  String get verifyNow => 'Vérifier maintenant';

  @override
  String listingFeeDisplay(String fee) {
    return 'Frais d\'annonce : $fee';
  }

  @override
  String get requiresIdVerification => 'Nécessite une vérification d\'identité';

  @override
  String get nextDetails => 'Suivant : Détails';

  @override
  String get nextPricing => 'Suivant : Prix';

  @override
  String get reviewAndPay => 'Vérifier et payer';

  @override
  String get creatingListing => 'Création…';

  @override
  String get titleLabel => 'Titre';

  @override
  String get titleHint => 'ex. Toyota Land Cruiser 2019';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionHint =>
      'Décrivez l\'article — état, caractéristiques, défauts éventuels…';

  @override
  String get photosAddedAfterPublishing =>
      'Les photos peuvent être ajoutées après la publication.';

  @override
  String get startingPriceMru => 'Prix de départ (MRU)';

  @override
  String get reservePriceMru => 'Prix de réserve (MRU)';

  @override
  String get reservePriceNote =>
      'Masqué aux enchérisseurs. Minimum que vous acceptez.';

  @override
  String get minBidIncrementMru => 'Incrément min. (MRU)';

  @override
  String get auctionStartLabel => 'Début de l\'enchère';

  @override
  String get auctionEndLabel => 'Fin de l\'enchère';

  @override
  String get listingFeeTitle => 'Frais d\'annonce';

  @override
  String get testModeBanner =>
      'MODE TEST — aucun frais réel. L\'intégration Sedad n\'est pas encore active.';

  @override
  String get listingSummaryLabel => 'Résumé de l\'annonce';

  @override
  String get platformListingFee => 'Frais d\'annonce de la plateforme';

  @override
  String get sedadProductionNote =>
      'En production, le paiement sera collecté via Sedad avant la publication de l\'annonce.';

  @override
  String get listingPublished => 'Annonce publiée !';

  @override
  String listingPublishedBody(String title) {
    return '« $title » est maintenant programmé. Les enchérisseurs pourront rejoindre une fois l\'enchère lancée.';
  }

  @override
  String get processing => 'Traitement…';

  @override
  String confirmStub(String fee) {
    return 'Confirmer (test — $fee non débité)';
  }

  @override
  String get sectionActive => 'ACTIF';

  @override
  String get sectionPending => 'EN ATTENTE';

  @override
  String get sectionCompleted => 'TERMINÉ';

  @override
  String get noListingsYet => 'Vous n\'avez pas encore d\'annonces.';

  @override
  String get wallet => 'Portefeuille';

  @override
  String get signInToViewWallet =>
      'Connectez-vous pour voir votre portefeuille';

  @override
  String get walletBalanceWillAppear =>
      'Votre solde et vos dépôts actifs apparaîtront ici.';

  @override
  String get activeDeposits => 'DÉPÔTS ACTIFS';

  @override
  String get totalBalance => 'Solde total';

  @override
  String get available => 'Disponible';

  @override
  String get inDeposits => 'En dépôts';

  @override
  String get noActiveDeposits =>
      'Aucun dépôt actif.\nParcourez les annonces et rejoignez une enchère pour déposer une caution.';

  @override
  String bidCeilingLabel(String amount) {
    return 'Plafond d\'enchère : $amount';
  }

  @override
  String get activeAuctions => 'ENCHÈRES ACTIVES';

  @override
  String get pastAuctions => 'ENCHÈRES PASSÉES';

  @override
  String get noPlacedBids => 'Vous n\'avez pas encore placé d\'offres.';

  @override
  String get myBidLabel => 'Mon offre';

  @override
  String get currentBidShortLabel => 'Actuelle';

  @override
  String get indicatorWon => 'GAGNÉ';

  @override
  String get indicatorLost => 'PERDU';

  @override
  String get indicatorNotSold => 'NON VENDU';

  @override
  String get indicatorAwaitingSeller => 'EN ATTENTE VENDEUR';

  @override
  String get indicatorLeading => 'EN TÊTE';

  @override
  String get indicatorOutbid => 'SURENCHÉRI';

  @override
  String get stepPaid => 'Payé';

  @override
  String get stepShipped => 'Expédié';

  @override
  String get stepDelivered => 'Livré';

  @override
  String get orderItemLabel => 'Article';

  @override
  String get orderFinalPrice => 'Prix final';

  @override
  String get orderSellerLabel => 'Vendeur';

  @override
  String get orderBuyerLabel => 'Acheteur';

  @override
  String get orderShippedLabel => 'Expédié';

  @override
  String get orderDeliveredLabel => 'Livré';

  @override
  String get deliveryAddress => 'Adresse de livraison';

  @override
  String get confirmPayment => 'Confirmer le paiement';

  @override
  String get addDeliveryAddress => 'Ajouter une adresse de livraison';

  @override
  String get waitingForSellerToShip =>
      'En attente d\'expédition par le vendeur.';

  @override
  String get confirmReceived => 'Confirmer la réception';

  @override
  String get orderCompleteEnjoy =>
      'Commande complète. Profitez de votre article !';

  @override
  String get waitingForBuyerPayment =>
      'En attente de confirmation du paiement par l\'acheteur.';

  @override
  String get waitingForBuyerAddress =>
      'En attente de l\'ajout d\'une adresse de livraison par l\'acheteur.';

  @override
  String get markAsShippedButton => 'Marquer comme expédié';

  @override
  String get waitingForBuyerDelivery =>
      'En attente de confirmation de livraison par l\'acheteur.';

  @override
  String get orderCompleteFundsReleased => 'Commande complète. Fonds libérés.';

  @override
  String get reportAProblem => 'Signaler un problème';

  @override
  String get newAddressTitle => 'Nouvelle adresse';

  @override
  String get selectAddressTitle => 'Sélectionner une adresse';

  @override
  String get newAddressItem => 'Nouvelle adresse';

  @override
  String get allFieldsRequired => 'Tous les champs sont obligatoires.';

  @override
  String get saveAndUseAddress => 'Enregistrer et utiliser cette adresse';

  @override
  String get backToSavedAddresses => 'Retour aux adresses enregistrées';

  @override
  String get markAsShippedSheetTitle => 'Marquer comme expédié';

  @override
  String get trackingNoteOptionalSubtitle =>
      'Ajoutez optionnellement un numéro de suivi ou une note pour l\'acheteur.';

  @override
  String get trackingNoteHint => 'Note de suivi (facultatif)';

  @override
  String get confirmShipment => 'Confirmer l\'expédition';

  @override
  String get addressLabelHint => 'Étiquette (ex. Domicile)';

  @override
  String get fullNameHint => 'Nom complet';

  @override
  String get streetAddressHint => 'Adresse';

  @override
  String get cityHint => 'Ville';

  @override
  String get phoneHint => 'Téléphone';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Tout marquer comme lu';

  @override
  String get allCaughtUp => 'Vous êtes à jour.';

  @override
  String get kycTitle => 'Vérification d\'identité';

  @override
  String get camera => 'Caméra';

  @override
  String get gallery => 'Galerie';

  @override
  String get idFrontLabel => 'Recto de la pièce d\'identité';

  @override
  String get idFrontHint => 'Recto de votre carte d\'identité nationale';

  @override
  String get idBackLabel => 'Verso de la pièce d\'identité';

  @override
  String get idBackHint => 'Verso de votre carte d\'identité nationale';

  @override
  String get selfieLabel => 'Selfie';

  @override
  String get selfieHint =>
      'Tenez votre pièce d\'identité à côté de votre visage';

  @override
  String get submitForReview => 'Soumettre pour révision';

  @override
  String get kycPendingTitle => 'En cours de révision';

  @override
  String get kycPendingSubtitle =>
      'Vos documents ont été soumis et sont en cours d\'examen.';

  @override
  String get kycApprovedTitle => 'Identité vérifiée';

  @override
  String get kycApprovedSubtitle =>
      'Votre identité a été confirmée. Vous pouvez publier des annonces de terrains.';

  @override
  String get kycRejectedTitle => 'Soumission rejetée';

  @override
  String get kycRejectedDefaultReason =>
      'Votre soumission a été rejetée. Veuillez resoumettre avec des photos plus claires.';

  @override
  String get kycNoneTitle => 'Non vérifié';

  @override
  String get kycNoneSubtitle =>
      'Soumettez votre pièce d\'identité et un selfie pour débloquer les annonces de terrains.';

  @override
  String get myDisputesTitle => 'Mes litiges';

  @override
  String get noDisputes => 'Vous n\'avez aucun litige.';

  @override
  String get disputeCategoryItemNotAsDescribed =>
      'Article non conforme à la description';

  @override
  String get disputeCategoryItemNotReceived => 'Article non reçu';

  @override
  String get disputeCategoryPaymentIssue => 'Problème de paiement';

  @override
  String get disputeCategorySellerUnresponsive => 'Vendeur non réactif';

  @override
  String get disputeCategoryOther => 'Autre';

  @override
  String disputeOtherParty(String bidderNumber) {
    return 'Autre partie : #$bidderNumber';
  }

  @override
  String get disputeStatusOpen => 'OUVERT';

  @override
  String get disputeStatusUnderReview => 'EN RÉVISION';

  @override
  String get disputeStatusResolved => 'RÉSOLU';

  @override
  String get disputeStatusDismissed => 'REJETÉ';

  @override
  String get reportDisputeTitle => 'Signaler un problème';

  @override
  String get disputeCategoryLabel => 'Catégorie';

  @override
  String get disputeDescriptionLabel => 'Description';

  @override
  String get disputeDescriptionHint => 'Décrivez le problème en détail…';

  @override
  String get disputeEvidenceLabel => 'Preuves (facultatif)';

  @override
  String get submitDisputeButton => 'Soumettre le litige';

  @override
  String get selectCategoryHint => 'Sélectionner une catégorie';

  @override
  String get attachPhoto => 'Joindre une photo';

  @override
  String get pleaseDescribeIssue => 'Veuillez décrire le problème.';

  @override
  String get disputeSubmittedSnackbar =>
      'Litige soumis. Notre équipe l\'examinera sous peu.';

  @override
  String get savedTitle => 'Enregistrés';

  @override
  String get noFavoritesYet =>
      'Vous n\'avez pas encore enregistré d\'annonces.';

  @override
  String get addressBookTitle => 'Carnet d\'adresses';

  @override
  String get addAddress => 'Ajouter une adresse';

  @override
  String get noAddressesYet =>
      'Vous n\'avez pas encore d\'adresses enregistrées.';

  @override
  String get deleteAddressTitle => 'Supprimer l\'adresse ?';

  @override
  String deleteAddressMessage(String label) {
    return 'Supprimer « $label » ?';
  }

  @override
  String get setAsDefault => 'Définir par défaut';

  @override
  String get defaultBadge => 'Par défaut';

  @override
  String get editAddress => 'Modifier l\'adresse';

  @override
  String get addressLabelField => 'Étiquette';

  @override
  String get addressLabelFieldHint => 'ex. Domicile, Travail';

  @override
  String get addressFullNameField => 'Nom complet';

  @override
  String get addressStreetField => 'Rue / adresse';

  @override
  String get addressCityField => 'Ville';

  @override
  String get addressCountryField => 'Pays';

  @override
  String get addressPhoneField => 'Téléphone';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get aboutTitle => 'À propos';

  @override
  String get aboutBody1 =>
      'Mazad est une plateforme d\'enchères en ligne mauritanienne qui permet aux utilisateurs de participer à des enchères en direct et d\'acheter ou de vendre des voitures, des biens immobiliers et des marchandises en toute facilité et transparence.';

  @override
  String get aboutBody2 =>
      'Notre mission est de moderniser l\'expérience des enchères en Mauritanie en proposant une plateforme numérique fiable qui offre aux vendeurs un accès à davantage d\'acheteurs et aux acheteurs de réelles opportunités d\'obtenir une meilleure valeur pour leur argent.';

  @override
  String get aboutBody3 =>
      'Les vendeurs créent des annonces pour les articles qu\'ils souhaitent vendre et définissent une heure de début et de fin pour l\'enchère. Les acheteurs intéressés soumettent des offres en temps réel, et le gagnant est l\'enchérisseur le plus offrant à la clôture de l\'enchère.';

  @override
  String get appVersion => 'Version 1.0.0';

  @override
  String get copyright => '© 2026 Mazad. Tous droits réservés.';

  @override
  String get contactSupportTitle => 'Contact et assistance';

  @override
  String get contactUs => 'NOUS CONTACTER';

  @override
  String get faqSectionTitle => 'QUESTIONS FRÉQUENTES';

  @override
  String get faq1Question => 'Comment placer une offre ?';

  @override
  String get faq1Answer =>
      'Ouvrez n\'importe quelle annonce d\'enchère en direct et appuyez sur le bouton « Placer une offre ». Saisissez un montant supérieur à l\'offre la plus élevée actuelle et confirmez. Votre offre est soumise instantanément.';

  @override
  String get faq2Question =>
      'Puis-je annuler une offre après l\'avoir placée ?';

  @override
  String get faq2Answer =>
      'Les offres sont contraignantes une fois soumises et ne peuvent pas être annulées. Veuillez examiner attentivement les détails de l\'annonce avant d\'enchérir.';

  @override
  String get faq3Question => 'Comment vendre un article sur Mazad ?';

  @override
  String get faq3Answer =>
      'Accédez à l\'onglet Vendre, remplissez les détails de l\'annonce incluant le titre, la catégorie, le prix de départ et les dates de l\'enchère, puis soumettez. Votre annonce sera examinée avant d\'être mise en ligne.';

  @override
  String get faq4Question => 'Quels modes de paiement sont acceptés ?';

  @override
  String get faq4Answer =>
      'Les modalités de paiement sont convenues entre l\'acheteur et le vendeur après la clôture de l\'enchère. Mazad facilite actuellement le processus d\'enchère ; l\'intégration directe du paiement sera disponible prochainement.';

  @override
  String get faq5Question => 'Que se passe-t-il si je remporte une enchère ?';

  @override
  String get faq5Answer =>
      'Vous recevrez une notification lorsque vous gagnez. Le vendeur sera notifié pour confirmer la vente. Vous pourrez ensuite coordonner la livraison et le paiement via l\'écran de détails de la commande.';

  @override
  String get faq6Question => 'Comment vérifier mon identité (KYC) ?';

  @override
  String get faq6Answer =>
      'Accédez à Profil → Vérification d\'identité et suivez les étapes pour télécharger votre pièce d\'identité. La vérification prend généralement 1 à 2 jours ouvrables.';

  @override
  String get faq7Question => 'Comment ouvrir un litige ?';

  @override
  String get faq7Answer =>
      'Si vous avez un problème avec une enchère terminée, accédez à Profil → Mes litiges et appuyez sur « Signaler un litige ». Fournissez une description claire et notre équipe l\'examinera dans les 3 jours ouvrables.';

  @override
  String get faq8Question => 'Comment supprimer mon compte ?';

  @override
  String get faq8Answer =>
      'Contactez notre équipe d\'assistance à projectestingemail@gmail.com et demandez la suppression du compte. Nous le traiterons dans les 7 jours ouvrables conformément aux réglementations applicables en matière de protection des données.';

  @override
  String get liveAuctionEndedLabel => 'ENCHÈRE TERMINÉE';

  @override
  String get liveAuctionLiveLabel => 'EN DIRECT';

  @override
  String get reconnecting => 'Reconnexion…';

  @override
  String get connectionLostRetry => 'Connexion perdue — appuyez pour réessayer';

  @override
  String get endingSoon => 'se termine bientôt';

  @override
  String get calculatingResultLabel => 'calcul du résultat…';

  @override
  String get waitingForFirstBid => 'En attente de la première offre…';

  @override
  String get recentBids => 'OFFRES RÉCENTES';

  @override
  String get couldntReachServer => 'IMPOSSIBLE DE JOINDRE LE SERVEUR';

  @override
  String get checkConnectionRetry => 'Vérifiez votre connexion et réessayez.';

  @override
  String get youWon => 'VOUS AVEZ GAGNÉ';

  @override
  String get auctionEndedHeadline => 'ENCHÈRE TERMINÉE';

  @override
  String get reserveNotMet => 'RÉSERVE NON ATTEINTE';

  @override
  String get calculatingResultHeadline => 'CALCUL DU RÉSULTAT';

  @override
  String finalPriceLabel(String amount) {
    return 'Prix final : $amount';
  }

  @override
  String soldToOther(String bidder, String amount) {
    return 'Vendu à $bidder · $amount';
  }

  @override
  String get awaitingSellerDecision => 'En attente de la décision du vendeur';

  @override
  String get noBidsMetReserve => 'Aucune offre n\'a atteint la réserve';

  @override
  String get youreLeading => 'Vous êtes en tête';

  @override
  String youveBeenOutbid(String bidder) {
    return 'Vous avez été surenchéri  ·  $bidder mène';
  }

  @override
  String get noBidsYet => 'Aucune offre pour l\'instant';

  @override
  String get loadingBidButton => 'Chargement…';

  @override
  String bidButton(String amount) {
    return 'Offrir $amount';
  }

  @override
  String get networkError => 'Erreur réseau — veuillez réessayer.';

  @override
  String get addPhotos => 'Ajouter des photos';

  @override
  String get listingPhotosTitle => 'Photos de l\'annonce';

  @override
  String get listingPhotosSubtitle =>
      'Ajoutez jusqu\'à 5 photos. La première photo sera la miniature de l\'annonce.';

  @override
  String get addPhotoButton => 'Ajouter une photo';

  @override
  String get skipPhotos => 'Passer';

  @override
  String get uploadPhotos => 'Télécharger les photos';

  @override
  String uploadingPhotoProgress(int current, int total) {
    return 'Téléchargement $current sur $total…';
  }

  @override
  String get photoUploadDone => 'Photos ajoutées à votre annonce.';

  @override
  String get maxPhotosReached => 'Limite de 5 photos atteinte.';
}
