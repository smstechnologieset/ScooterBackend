import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized strings interface for the ISOKO application.
abstract class AppStrings {
  // General / Common
  String get appName;
  String get cancel;
  String get confirm;
  String get done;
  String get tryAgain;
  String get pleaseWait;
  String get gotIt;
  String get submit;
  String get close;
  String get back;
  String get continueText;

  // Auth
  String get hello;
  String get signInNow;
  String get signUpNow;
  String get looksLikeNotRegistered;
  String get enterEmail;
  String get enterPhoneNumber;
  String get fullName;
  String get password;
  String get confirmPassword;
  String get forgotPassword;
  String get signIn;
  String get createAccount;
  String get createAccountButton;
  String get orContinueWith;
  String get continueWithGoogle;
  String get continueWithApple;
  String get dontHaveAccount;
  String get alreadyHaveAccount;
  String get byContinuingAgree;
  String get termsAndConditions;
  String get privacyPolicy;
  String get resetPassword;
  String get sendResetLink;
  String get checkYourEmail;
  String get checkEmailDesc;
  String get goToSignIn;
  String get backToSignIn;
  String get newPassword;
  String get confirmNewPassword;
  String get updatePassword;
  String get passwordUpdated;

  // Bootstrap & Location
  String get preparingAccount;
  String get getIsokoAnywhere;
  String get pleaseAllowLocation;
  String get enableLocation;
  String get findingLocation;
  String get openMap;
  String get locationServicesDisabled;
  String get locationBlocked;

  // Map & Scooter Selection
  String get findScooters;
  String get nearYou;
  String get scanNow;
  String get ringBell;
  String get range;
  String get battery;
  String get availableScooters;

  // QR Scanner & Manual Code
  String get scanQrCode;
  String get alignQrFrame;
  String get bikeNumber;
  String get torch;
  String get enterBikeNumber;
  String get unlock;
  String get tryDemoCode;
  String get unlocking;
  String get parkInElectraZone;
  String get privateArea;
  String get enjoyRide;

  // Active Ride
  String get riding;
  String get paused;
  String get timeUsed;
  String get distanceTraveled;
  String get pause;
  String get resume;
  String get endRide;
  String get endRideConfirmTitle;
  String get endRideConfirmMessage;

  // Parking Verification
  String get takePicture;
  String get takePictureSubtitle;
  String get verifyingParking;
  String get invalidParkingZone;
  String get parkingRestricted;
  String get invalidParkingMessage;
  String get endRideBypass;
  String get whyIsThisHappening;
  String get parkingExplanationTitle;
  String get parkingExplanationBody;

  // Payment & Rating
  String get paymentDue;
  String get rideSummary;
  String get tripBreakdown;
  String get baseFare;
  String get rideTimeCost;
  String get pilotDiscount;
  String get totalFare;
  String get selectPaymentMethod;
  String get payNow;
  String get paymentSuccess;
  String get thankYouRiding;
  String get rateRide;
  String get howWasExperience;
  String get submitReview;

  // Sidebar Menu & Stats
  String get ridesTaken;
  String get rideTimes;
  String get carbonSaved;
  String get rideHistory;
  String get paymentWallet;
  String get referral;
  String get tutorial;
  String get helpFaq;
  String get settings;
  String get logout;
  String get logoutConfirmTitle;
  String get logoutConfirmMessage;

  // Settings
  String get settingsTitle;
  String get questionsAnswered;
  String get selectLanguage;
  String get appMode;
  String get darkMode;
  String get lightMode;
  String get systemMode;
  String get distanceUnit;
  String get kmUnit;
  String get english;
  String get french;
}

/// English translation strings
class AppStringsEn implements AppStrings {
  const AppStringsEn();

  @override
  String get appName => 'ISOKO';
  @override
  String get cancel => 'Cancel';
  @override
  String get confirm => 'Confirm';
  @override
  String get done => 'Done';
  @override
  String get tryAgain => 'Try Again';
  @override
  String get pleaseWait => 'Please wait';
  @override
  String get gotIt => 'Got it';
  @override
  String get submit => 'Submit';
  @override
  String get close => 'Close';
  @override
  String get back => 'Back';
  @override
  String get continueText => 'Continue';

  @override
  String get hello => 'Hello,';
  @override
  String get signInNow => 'Sign in Now';
  @override
  String get signUpNow => 'Sign Up Now';
  @override
  String get looksLikeNotRegistered => "Looks like you're not registered yet.";
  @override
  String get enterEmail => 'Enter Email';
  @override
  String get enterPhoneNumber => 'Enter Phone Number';
  @override
  String get fullName => 'Full name';
  @override
  String get password => 'Password';
  @override
  String get confirmPassword => 'Confirm password';
  @override
  String get forgotPassword => 'Forgot password?';
  @override
  String get signIn => 'Sign in';
  @override
  String get createAccount => 'Create an account';
  @override
  String get createAccountButton => 'Create account';
  @override
  String get orContinueWith => 'Or Continue with';
  @override
  String get continueWithGoogle => 'Continue with Google';
  @override
  String get continueWithApple => 'Continue with Apple';
  @override
  String get dontHaveAccount => "Don't have an account? ";
  @override
  String get alreadyHaveAccount => 'Already have an account? ';
  @override
  String get byContinuingAgree => 'By continuing you agree to our';
  @override
  String get termsAndConditions => 'Terms and Conditions.';
  @override
  String get privacyPolicy => 'Privacy Policy';
  @override
  String get resetPassword => 'Reset password';
  @override
  String get sendResetLink => 'Send reset link';
  @override
  String get checkYourEmail => 'Check your email';
  @override
  String get checkEmailDesc =>
      'Open the confirmation link on this device. ISOKO will continue automatically after verification.';
  @override
  String get goToSignIn => 'Go to sign in';
  @override
  String get backToSignIn => 'Back to sign in';
  @override
  String get newPassword => 'New password';
  @override
  String get confirmNewPassword => 'Confirm new password';
  @override
  String get updatePassword => 'Update password';
  @override
  String get passwordUpdated => 'Password updated';

  @override
  String get preparingAccount => 'Preparing your account...';
  @override
  String get getIsokoAnywhere => 'Get Isoko\nAnywhere....';
  @override
  String get pleaseAllowLocation =>
      'Please allow us to use your location to show nearby bikes available';
  @override
  String get enableLocation => 'Enable Location';
  @override
  String get findingLocation => 'Finding location...';
  @override
  String get openMap => 'Open Map';
  @override
  String get locationServicesDisabled => 'Location Services are turned off.';
  @override
  String get locationBlocked => 'Allow location from your device settings.';

  @override
  String get findScooters => 'Find Bikes';
  @override
  String get nearYou => 'Near you';
  @override
  String get scanNow => 'Scan Now';
  @override
  String get ringBell => 'Ring Bell';
  @override
  String get range => 'Range';
  @override
  String get battery => 'Battery';
  @override
  String get availableScooters => 'Available Bikes';

  @override
  String get scanQrCode => 'Scan QR Code';
  @override
  String get alignQrFrame => 'Align QR code within the frame';
  @override
  String get bikeNumber => 'Bike Num';
  @override
  String get torch => 'Torch';
  @override
  String get enterBikeNumber => 'Enter Bike Number';
  @override
  String get unlock => 'Unlock';
  @override
  String get tryDemoCode => 'Try Demo Code';
  @override
  String get unlocking => 'Unlocking...';
  @override
  String get parkInElectraZone => 'Park in Electra Zone';
  @override
  String get privateArea => 'Private Area';
  @override
  String get enjoyRide => 'Enjoy your ride!';

  @override
  String get riding => 'Riding';
  @override
  String get paused => 'Paused';
  @override
  String get timeUsed => 'Time used';
  @override
  String get distanceTraveled => 'Traveled';
  @override
  String get pause => 'Pause';
  @override
  String get resume => 'Resume';
  @override
  String get endRide => 'End Ride';
  @override
  String get endRideConfirmTitle => 'End Ride?';
  @override
  String get endRideConfirmMessage =>
      'Are you sure you want to end your ride? Please ensure the scooter is safely parked at a designated station.';

  @override
  String get takePicture => 'Take Picture';
  @override
  String get takePictureSubtitle =>
      'Take a picture of the bike parked in the station';
  @override
  String get verifyingParking => 'Verifying parking location...';
  @override
  String get invalidParkingZone => 'INVALID\nPARKING ZONE';
  @override
  String get parkingRestricted => 'PARKING RESTRICTED';
  @override
  String get invalidParkingMessage =>
      'It looks like you\'re outside a designated station. To end your ride, please move your scooter to a marked zone to avoid a penalty fee.';
  @override
  String get endRideBypass => 'End Ride Anyway (Demo Bypass)';
  @override
  String get whyIsThisHappening => 'Why is this happening?';
  @override
  String get parkingExplanationTitle =>
      'Why do I need to park at a station?';
  @override
  String get parkingExplanationBody =>
      'ISOKO scooters must be returned to designated parking stations after each ride. This ensures:\n\n'
      '• Scooters are available for the next rider\n'
      '• Sidewalks and roads stay clear\n'
      '• Scooters are parked safely and securely\n\n'
      'Ending a ride outside a station may result in a penalty fee.';

  @override
  String get paymentDue => 'Payment Due';
  @override
  String get rideSummary => 'Ride Summary';
  @override
  String get tripBreakdown => 'Trip Breakdown';
  @override
  String get baseFare => 'Base Fare';
  @override
  String get rideTimeCost => 'Ride Time';
  @override
  String get pilotDiscount => 'Pilot Demo Discount';
  @override
  String get totalFare => 'Total';
  @override
  String get selectPaymentMethod => 'Select Payment Method';
  @override
  String get payNow => 'Pay Now';
  @override
  String get paymentSuccess => 'Payment Successful';
  @override
  String get thankYouRiding => 'Thank you for riding with ISOKO!';
  @override
  String get rateRide => 'Rate Your Ride';
  @override
  String get howWasExperience => 'How was your experience?';
  @override
  String get submitReview => 'Submit Review';

  @override
  String get ridesTaken => 'Rides taken';
  @override
  String get rideTimes => 'Ride Times';
  @override
  String get carbonSaved => 'Carbon Saved';
  @override
  String get rideHistory => 'Ride History';
  @override
  String get paymentWallet => 'Payment & Wallet';
  @override
  String get referral => 'Referral';
  @override
  String get tutorial => 'Tutorial';
  @override
  String get helpFaq => 'Help & FAQ';
  @override
  String get settings => 'Settings';
  @override
  String get logout => 'Logout';
  @override
  String get logoutConfirmTitle => 'Sign Out';
  @override
  String get logoutConfirmMessage =>
      'Are you sure you want to sign out of ISOKO?';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get questionsAnswered => 'Your Questions got answered';
  @override
  String get selectLanguage => 'Select Language';
  @override
  String get appMode => 'App Mode';
  @override
  String get darkMode => 'Dark Mode';
  @override
  String get lightMode => 'Light Mode';
  @override
  String get systemMode => 'System Default';
  @override
  String get distanceUnit => 'Distance Unit';
  @override
  String get kmUnit => 'Km (Kilometer)';
  @override
  String get english => 'English';
  @override
  String get french => 'Français';
}

/// French translation strings
class AppStringsFr implements AppStrings {
  const AppStringsFr();

  @override
  String get appName => 'ISOKO';
  @override
  String get cancel => 'Annuler';
  @override
  String get confirm => 'Confirmer';
  @override
  String get done => 'Terminé';
  @override
  String get tryAgain => 'Réessayer';
  @override
  String get pleaseWait => 'Veuillez patienter';
  @override
  String get gotIt => 'Compris';
  @override
  String get submit => 'Soumettre';
  @override
  String get close => 'Fermer';
  @override
  String get back => 'Retour';
  @override
  String get continueText => 'Continuer';

  @override
  String get hello => 'Bonjour,';
  @override
  String get signInNow => 'Connexion';
  @override
  String get signUpNow => 'Créer un compte';
  @override
  String get looksLikeNotRegistered =>
      "Il semble que vous n'êtes pas encore inscrit.";
  @override
  String get enterEmail => 'Entrez votre e-mail';
  @override
  String get enterPhoneNumber => 'Entrez votre numéro';
  @override
  String get fullName => 'Nom complet';
  @override
  String get password => 'Mot de passe';
  @override
  String get confirmPassword => 'Confirmer le mot de passe';
  @override
  String get forgotPassword => 'Mot de passe oublié ?';
  @override
  String get signIn => 'Se connecter';
  @override
  String get createAccount => 'Créer un compte';
  @override
  String get createAccountButton => 'Créer un compte';
  @override
  String get orContinueWith => 'Ou continuer avec';
  @override
  String get continueWithGoogle => 'Continuer avec Google';
  @override
  String get continueWithApple => 'Continuer avec Apple';
  @override
  String get dontHaveAccount => "Vous n'avez pas de compte ? ";
  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ? ';
  @override
  String get byContinuingAgree => 'En continuant, vous acceptez nos';
  @override
  String get termsAndConditions => 'Conditions Générales.';
  @override
  String get privacyPolicy => 'Politique de Confidentialité';
  @override
  String get resetPassword => 'Réinitialiser le mot de passe';
  @override
  String get sendResetLink => 'Envoyer le lien';
  @override
  String get checkYourEmail => 'Vérifiez votre e-mail';
  @override
  String get checkEmailDesc =>
      'Ouvrez le lien de confirmation sur cet appareil. ISOKO continuera automatiquement après validation.';
  @override
  String get goToSignIn => 'Aller à la connexion';
  @override
  String get backToSignIn => 'Retour à la connexion';
  @override
  String get newPassword => 'Nouveau mot de passe';
  @override
  String get confirmNewPassword => 'Confirmer le mot de passe';
  @override
  String get updatePassword => 'Mettre à jour';
  @override
  String get passwordUpdated => 'Mot de passe mis à jour';

  @override
  String get preparingAccount => 'Préparation de votre compte...';
  @override
  String get getIsokoAnywhere => 'ISOKO Partout\navec vous....';
  @override
  String get pleaseAllowLocation =>
      'Veuillez autoriser l\'accès à la localisation pour voir les vélos à proximité';
  @override
  String get enableLocation => 'Activer la localisation';
  @override
  String get findingLocation => 'Recherche de localisation...';
  @override
  String get openMap => 'Ouvrir la carte';
  @override
  String get locationServicesDisabled =>
      'Les services de localisation sont désactivés.';
  @override
  String get locationBlocked =>
      'Autorisez la localisation dans les paramètres de votre appareil.';

  @override
  String get findScooters => 'Trouver un vélo';
  @override
  String get nearYou => 'Près de vous';
  @override
  String get scanNow => 'Scanner';
  @override
  String get ringBell => 'Sonner';
  @override
  String get range => 'Autonomie';
  @override
  String get battery => 'Batterie';
  @override
  String get availableScooters => 'Vélos disponibles';

  @override
  String get scanQrCode => 'Scanner le code QR';
  @override
  String get alignQrFrame => 'Alignez le QR code dans le cadre';
  @override
  String get bikeNumber => 'N° Trottinette';
  @override
  String get torch => 'Lampe';
  @override
  String get enterBikeNumber => 'Entrez le numéro du véhicule';
  @override
  String get unlock => 'Déverrouiller';
  @override
  String get tryDemoCode => 'Essayer le code démo';
  @override
  String get unlocking => 'Déverrouillage en cours...';
  @override
  String get parkInElectraZone => 'Stationner en zone Electra';
  @override
  String get privateArea => 'Espace privé';
  @override
  String get enjoyRide => 'Bonne route !';

  @override
  String get riding => 'En route';
  @override
  String get paused => 'En pause';
  @override
  String get timeUsed => 'Durée';
  @override
  String get distanceTraveled => 'Distance';
  @override
  String get pause => 'Pause';
  @override
  String get resume => 'Reprendre';
  @override
  String get endRide => 'Terminer le trajet';
  @override
  String get endRideConfirmTitle => 'Terminer le trajet ?';
  @override
  String get endRideConfirmMessage =>
      'Êtes-vous sûr de vouloir terminer votre trajet ? Veuillez vous assurer que le véhicule est garé dans une station désignée.';

  @override
  String get takePicture => 'Prendre une photo';
  @override
  String get takePictureSubtitle =>
      'Prenez une photo de la trottinette garée à la station';
  @override
  String get verifyingParking => 'Vérification de la station...';
  @override
  String get invalidParkingZone => 'ZONE DE\nSTATIONNEMENT INVALIDE';
  @override
  String get parkingRestricted => 'STATIONNEMENT RESTREINT';
  @override
  String get invalidParkingMessage =>
      'Vous êtes en dehors d\'une station désignée. Veuillez déplacer votre trottinette vers une station pour éviter des frais supplémentaires.';
  @override
  String get endRideBypass => 'Terminer quand même (Démo)';
  @override
  String get whyIsThisHappening => 'Pourquoi ce message ?';
  @override
  String get parkingExplanationTitle =>
      'Pourquoi stationner dans une station ?';
  @override
  String get parkingExplanationBody =>
      'Les trottinettes ISOKO doivent être rendues dans des stations désignées après chaque trajet afin de :\n\n'
      '• Garantir la disponibilité pour le prochain utilisateur\n'
      '• Laisser les trottoirs et rues dégagés\n'
      '• Protéger les véhicules en toute sécurité\n\n'
      'Terminer un trajet hors station peut entraîner des pénalités.';

  @override
  String get paymentDue => 'Paiement dû';
  @override
  String get rideSummary => 'Résumé du trajet';
  @override
  String get tripBreakdown => 'Détails du trajet';
  @override
  String get baseFare => 'Tarif de base';
  @override
  String get rideTimeCost => 'Durée du trajet';
  @override
  String get pilotDiscount => 'Remise Démo Pilote';
  @override
  String get totalFare => 'Total';
  @override
  String get selectPaymentMethod => 'Mode de paiement';
  @override
  String get payNow => 'Payer maintenant';
  @override
  String get paymentSuccess => 'Paiement réussi';
  @override
  String get thankYouRiding => 'Merci d\'avoir voyagé avec ISOKO !';
  @override
  String get rateRide => 'Évaluez votre trajet';
  @override
  String get howWasExperience => 'Comment s\'est passée votre expérience ?';
  @override
  String get submitReview => 'Envoyer l\'avis';

  @override
  String get ridesTaken => 'Trajets effectués';
  @override
  String get rideTimes => 'Temps de route';
  @override
  String get carbonSaved => 'Carbone évité';
  @override
  String get rideHistory => 'Historique des trajets';
  @override
  String get paymentWallet => 'Paiement et portefeuille';
  @override
  String get referral => 'Parrainage';
  @override
  String get tutorial => 'Tutoriel';
  @override
  String get helpFaq => 'Aide & FAQ';
  @override
  String get settings => 'Paramètres';
  @override
  String get logout => 'Déconnexion';
  @override
  String get logoutConfirmTitle => 'Déconnexion';
  @override
  String get logoutConfirmMessage =>
      'Êtes-vous sûr de vouloir vous déconnecter d\'ISOKO ?';

  @override
  String get settingsTitle => 'Paramètres';
  @override
  String get questionsAnswered => 'Toutes vos réponses ici';
  @override
  String get selectLanguage => 'Choisir la langue';
  @override
  String get appMode => 'Mode de l\'application';
  @override
  String get darkMode => 'Mode sombre';
  @override
  String get lightMode => 'Mode clair';
  @override
  String get systemMode => 'Système par défaut';
  @override
  String get distanceUnit => 'Unité de distance';
  @override
  String get kmUnit => 'Km (Kilomètre)';
  @override
  String get english => 'English';
  @override
  String get french => 'Français';
}

/// AppLocalizations provides strings based on the active Locale.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
  ];

  static const AppStrings _en = AppStringsEn();
  static const AppStrings _fr = AppStringsFr();

  AppStrings get strings {
    if (locale.languageCode == 'fr') {
      return _fr;
    }
    return _en;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extension on BuildContext for quick access to localized strings: `context.tr`
extension LocalizedContextExtension on BuildContext {
  AppStrings get tr => AppLocalizations.of(this).strings;
}
