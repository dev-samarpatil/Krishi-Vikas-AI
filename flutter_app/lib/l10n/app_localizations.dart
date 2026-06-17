import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';

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
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('ta')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Krishi Vikas AI'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Farming Assistant'**
  String get appTagline;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @continueWithoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Continue without account'**
  String get continueWithoutAccount;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get logout;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// No description provided for @weWillSendOtp.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you an OTP to verify'**
  String get weWillSendOtp;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @getOtp.
  ///
  /// In en, this message translates to:
  /// **'Get OTP'**
  String get getOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP. Try again.'**
  String get invalidOtp;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to +91 {phone}'**
  String otpSent(String phone);

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @addFirstFarm.
  ///
  /// In en, this message translates to:
  /// **'Add your first farm'**
  String get addFirstFarm;

  /// No description provided for @farmName.
  ///
  /// In en, this message translates to:
  /// **'Farm Name'**
  String get farmName;

  /// No description provided for @farmNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Main Farm'**
  String get farmNameHint;

  /// No description provided for @primaryCrop.
  ///
  /// In en, this message translates to:
  /// **'Primary Crop'**
  String get primaryCrop;

  /// No description provided for @farmSize.
  ///
  /// In en, this message translates to:
  /// **'Farm Size'**
  String get farmSize;

  /// No description provided for @farmingType.
  ///
  /// In en, this message translates to:
  /// **'Farming Type'**
  String get farmingType;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use My Location'**
  String get useMyLocation;

  /// No description provided for @sowingDate.
  ///
  /// In en, this message translates to:
  /// **'Sowing Date'**
  String get sowingDate;

  /// No description provided for @yourFarmIsReady.
  ///
  /// In en, this message translates to:
  /// **'Your farm is ready!'**
  String get yourFarmIsReady;

  /// No description provided for @farmSetupComplete.
  ///
  /// In en, this message translates to:
  /// **'Start scanning crops, checking prices, and getting personalised advice.'**
  String get farmSetupComplete;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @myFarm.
  ///
  /// In en, this message translates to:
  /// **'My Farm'**
  String get myFarm;

  /// No description provided for @scanYourCrop.
  ///
  /// In en, this message translates to:
  /// **'Scan Your Crop'**
  String get scanYourCrop;

  /// No description provided for @scanningFor.
  ///
  /// In en, this message translates to:
  /// **'Scanning for: {crop}'**
  String scanningFor(String crop);

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @uploadFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Upload from Gallery'**
  String get uploadFromGallery;

  /// No description provided for @useThisPhoto.
  ///
  /// In en, this message translates to:
  /// **'Use This Photo'**
  String get useThisPhoto;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @analysingCrop.
  ///
  /// In en, this message translates to:
  /// **'Analysing your crop...'**
  String get analysingCrop;

  /// No description provided for @diagnosisResult.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis Result'**
  String get diagnosisResult;

  /// No description provided for @organic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get organic;

  /// No description provided for @chemical.
  ///
  /// In en, this message translates to:
  /// **'Chemical'**
  String get chemical;

  /// No description provided for @preventionTip.
  ///
  /// In en, this message translates to:
  /// **'Prevention Tip'**
  String get preventionTip;

  /// No description provided for @nearestKvk.
  ///
  /// In en, this message translates to:
  /// **'Nearest KVK'**
  String get nearestKvk;

  /// No description provided for @saveToFarmLog.
  ///
  /// In en, this message translates to:
  /// **'Save to Farm Log'**
  String get saveToFarmLog;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scanAgain;

  /// No description provided for @askAboutFarm.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything about your farm'**
  String get askAboutFarm;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Ask about your farm...'**
  String get typeMessage;

  /// No description provided for @diseaseOutbreak.
  ///
  /// In en, this message translates to:
  /// **'Disease Outbreak'**
  String get diseaseOutbreak;

  /// No description provided for @climateRisk.
  ///
  /// In en, this message translates to:
  /// **'Climate Risk'**
  String get climateRisk;

  /// No description provided for @noOutbreaks.
  ///
  /// In en, this message translates to:
  /// **'No disease outbreaks reported near you ✅'**
  String get noOutbreaks;

  /// No description provided for @mandiPrices.
  ///
  /// In en, this message translates to:
  /// **'Mandi Prices'**
  String get mandiPrices;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @whereToSell.
  ///
  /// In en, this message translates to:
  /// **'Where to Sell'**
  String get whereToSell;

  /// No description provided for @pricePerQuintal.
  ///
  /// In en, this message translates to:
  /// **'₹{price}/quintal'**
  String pricePerQuintal(String price);

  /// No description provided for @governmentSchemes.
  ///
  /// In en, this message translates to:
  /// **'Government Schemes'**
  String get governmentSchemes;

  /// No description provided for @applyOnGovWebsite.
  ///
  /// In en, this message translates to:
  /// **'Apply on Government Website'**
  String get applyOnGovWebsite;

  /// No description provided for @callHelpline.
  ///
  /// In en, this message translates to:
  /// **'Call Helpline'**
  String get callHelpline;

  /// No description provided for @eligibility.
  ///
  /// In en, this message translates to:
  /// **'Eligibility'**
  String get eligibility;

  /// No description provided for @howToApply.
  ///
  /// In en, this message translates to:
  /// **'How to Apply'**
  String get howToApply;

  /// No description provided for @documentsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Documents Needed'**
  String get documentsNeeded;

  /// No description provided for @soilHealth.
  ///
  /// In en, this message translates to:
  /// **'Soil Health'**
  String get soilHealth;

  /// No description provided for @soilScore.
  ///
  /// In en, this message translates to:
  /// **'Soil Score'**
  String get soilScore;

  /// No description provided for @degraded.
  ///
  /// In en, this message translates to:
  /// **'DEGRADED'**
  String get degraded;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'FAIR'**
  String get fair;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'HEALTHY'**
  String get healthy;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'EXCELLENT'**
  String get excellent;

  /// No description provided for @soilGuardian.
  ///
  /// In en, this message translates to:
  /// **'Soil Guardian'**
  String get soilGuardian;

  /// No description provided for @usedOrganic.
  ///
  /// In en, this message translates to:
  /// **'Used Organic +10'**
  String get usedOrganic;

  /// No description provided for @usedChemical.
  ///
  /// In en, this message translates to:
  /// **'Used Chemical +2'**
  String get usedChemical;

  /// No description provided for @farmDetails.
  ///
  /// In en, this message translates to:
  /// **'Farm Details'**
  String get farmDetails;

  /// No description provided for @farmLifecycle.
  ///
  /// In en, this message translates to:
  /// **'Farm Lifecycle'**
  String get farmLifecycle;

  /// No description provided for @diagnosisLog.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis Log'**
  String get diagnosisLog;

  /// No description provided for @noDiagnosesYet.
  ///
  /// In en, this message translates to:
  /// **'No diagnoses yet. Scan your crop to get started.'**
  String get noDiagnosesYet;

  /// No description provided for @addFarm.
  ///
  /// In en, this message translates to:
  /// **'Add Farm'**
  String get addFarm;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @noAlerts.
  ///
  /// In en, this message translates to:
  /// **'No alerts yet. We\'ll notify you of important changes.'**
  String get noAlerts;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection — showing cached data'**
  String get noConnection;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again.'**
  String get sessionExpired;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @couldNotAnalyse.
  ///
  /// In en, this message translates to:
  /// **'Could not analyse. Check your connection and try again.'**
  String get couldNotAnalyse;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cropTomato.
  ///
  /// In en, this message translates to:
  /// **'Tomato'**
  String get cropTomato;

  /// No description provided for @cropOnion.
  ///
  /// In en, this message translates to:
  /// **'Onion'**
  String get cropOnion;

  /// No description provided for @cropCotton.
  ///
  /// In en, this message translates to:
  /// **'Cotton'**
  String get cropCotton;

  /// No description provided for @cropWheat.
  ///
  /// In en, this message translates to:
  /// **'Wheat'**
  String get cropWheat;

  /// No description provided for @cropSoybean.
  ///
  /// In en, this message translates to:
  /// **'Soybean'**
  String get cropSoybean;

  /// No description provided for @cropRice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get cropRice;

  /// No description provided for @cropPotato.
  ///
  /// In en, this message translates to:
  /// **'Potato'**
  String get cropPotato;

  /// No description provided for @cropOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get cropOther;

  /// No description provided for @stageSowing.
  ///
  /// In en, this message translates to:
  /// **'Sowing'**
  String get stageSowing;

  /// No description provided for @stageGermination.
  ///
  /// In en, this message translates to:
  /// **'Germination'**
  String get stageGermination;

  /// No description provided for @stageVegetative.
  ///
  /// In en, this message translates to:
  /// **'Vegetative'**
  String get stageVegetative;

  /// No description provided for @stageFlowering.
  ///
  /// In en, this message translates to:
  /// **'Flowering'**
  String get stageFlowering;

  /// No description provided for @stageHarvest.
  ///
  /// In en, this message translates to:
  /// **'Harvest'**
  String get stageHarvest;

  /// No description provided for @typeOrganic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get typeOrganic;

  /// No description provided for @typeConventional.
  ///
  /// In en, this message translates to:
  /// **'Conventional'**
  String get typeConventional;

  /// No description provided for @typeMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get typeMixed;

  /// No description provided for @selectFarm.
  ///
  /// In en, this message translates to:
  /// **'Select Farm'**
  String get selectFarm;

  /// No description provided for @detectDiseasesInstantly.
  ///
  /// In en, this message translates to:
  /// **'Detect diseases instantly'**
  String get detectDiseasesInstantly;

  /// No description provided for @marketPrices.
  ///
  /// In en, this message translates to:
  /// **'Market Prices'**
  String get marketPrices;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All →'**
  String get seeAll;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All →'**
  String get viewAll;

  /// No description provided for @noLocationData.
  ///
  /// In en, this message translates to:
  /// **'No location data'**
  String get noLocationData;

  /// No description provided for @couldNotLoadWeather.
  ///
  /// In en, this message translates to:
  /// **'Could not load weather'**
  String get couldNotLoadWeather;

  /// No description provided for @noPricesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No prices available'**
  String get noPricesAvailable;

  /// No description provided for @couldNotLoadPrices.
  ///
  /// In en, this message translates to:
  /// **'Could not load prices'**
  String get couldNotLoadPrices;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language / भाषा चुनें'**
  String get selectLanguage;

  /// No description provided for @authenticatedAccount.
  ///
  /// In en, this message translates to:
  /// **'Authenticated account'**
  String get authenticatedAccount;

  /// No description provided for @offlineGuestMode.
  ///
  /// In en, this message translates to:
  /// **'Offline / Guest Mode'**
  String get offlineGuestMode;

  /// No description provided for @diseaseOutbreakAlerts.
  ///
  /// In en, this message translates to:
  /// **'Disease Outbreak Alerts'**
  String get diseaseOutbreakAlerts;

  /// No description provided for @notifyDiseaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when pests/diseases outbreaks occur near you'**
  String get notifyDiseaseSubtitle;

  /// No description provided for @climateWeatherWarnings.
  ///
  /// In en, this message translates to:
  /// **'Climate & Weather Warnings'**
  String get climateWeatherWarnings;

  /// No description provided for @notifyClimateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify about extreme weather alerts'**
  String get notifyClimateSubtitle;

  /// No description provided for @mandiPriceAlerts.
  ///
  /// In en, this message translates to:
  /// **'Mandi Price Alerts'**
  String get mandiPriceAlerts;

  /// No description provided for @notifyMandiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when prices change significantly'**
  String get notifyMandiSubtitle;

  /// No description provided for @confirmPhoto.
  ///
  /// In en, this message translates to:
  /// **'Confirm Photo'**
  String get confirmPhoto;

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis Failed'**
  String get analysisFailed;

  /// No description provided for @retryAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Retry Analysis'**
  String get retryAnalysis;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera Permission Required'**
  String get cameraPermissionRequired;

  /// No description provided for @openSystemCamera.
  ///
  /// In en, this message translates to:
  /// **'Open System Camera'**
  String get openSystemCamera;

  /// No description provided for @organicTreatment.
  ///
  /// In en, this message translates to:
  /// **'Organic Treatment'**
  String get organicTreatment;

  /// No description provided for @chemicalTreatment.
  ///
  /// In en, this message translates to:
  /// **'Chemical Treatment'**
  String get chemicalTreatment;

  /// No description provided for @treatmentSteps.
  ///
  /// In en, this message translates to:
  /// **'Treatment Steps'**
  String get treatmentSteps;

  /// No description provided for @estimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated Cost'**
  String get estimatedCost;

  /// No description provided for @consultKvk.
  ///
  /// In en, this message translates to:
  /// **'Consult nearest KVK'**
  String get consultKvk;

  /// No description provided for @noKvkFound.
  ///
  /// In en, this message translates to:
  /// **'No KVK expert details found'**
  String get noKvkFound;

  /// No description provided for @scanAgainBtn.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scanAgainBtn;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// No description provided for @totalEstimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Total Estimated Cost'**
  String get totalEstimatedCost;

  /// No description provided for @totalEstimate.
  ///
  /// In en, this message translates to:
  /// **'Total Estimate'**
  String get totalEstimate;

  /// No description provided for @callKvkExpert.
  ///
  /// In en, this message translates to:
  /// **'Call KVK Expert'**
  String get callKvkExpert;

  /// No description provided for @viewDetailsApply.
  ///
  /// In en, this message translates to:
  /// **'View Details & Apply'**
  String get viewDetailsApply;

  /// No description provided for @directBenefit.
  ///
  /// In en, this message translates to:
  /// **'Direct Benefit Transfer (DBT) eligible'**
  String get directBenefit;

  /// No description provided for @cropInsurance.
  ///
  /// In en, this message translates to:
  /// **'Crop Insurance'**
  String get cropInsurance;

  /// No description provided for @acres.
  ///
  /// In en, this message translates to:
  /// **'ACRES'**
  String get acres;

  /// No description provided for @stage.
  ///
  /// In en, this message translates to:
  /// **'Stage:'**
  String get stage;

  /// No description provided for @fitLeafInGuide.
  ///
  /// In en, this message translates to:
  /// **'Fit the leaf inside the square guide'**
  String get fitLeafInGuide;

  /// No description provided for @allowCameraAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access in Settings to use this feature.'**
  String get allowCameraAccess;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get cameraUnavailable;

  /// No description provided for @initializingCamera.
  ///
  /// In en, this message translates to:
  /// **'Initializing camera...'**
  String get initializingCamera;

  /// No description provided for @highRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get highRisk;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @lowRisk.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get lowRisk;

  /// No description provided for @climateLegend.
  ///
  /// In en, this message translates to:
  /// **'Climate Legend'**
  String get climateLegend;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @partlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly Cloudy'**
  String get partlyCloudy;

  /// No description provided for @overcast.
  ///
  /// In en, this message translates to:
  /// **'Overcast'**
  String get overcast;

  /// No description provided for @clouds.
  ///
  /// In en, this message translates to:
  /// **'Clouds'**
  String get clouds;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @precipitation.
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get precipitation;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @soilHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Soil Health Score'**
  String get soilHealthScore;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @nitrogenN.
  ///
  /// In en, this message translates to:
  /// **'Nitrogen (N)'**
  String get nitrogenN;

  /// No description provided for @phosphorusP.
  ///
  /// In en, this message translates to:
  /// **'Phosphorus (P)'**
  String get phosphorusP;

  /// No description provided for @potassiumK.
  ///
  /// In en, this message translates to:
  /// **'Potassium (K)'**
  String get potassiumK;

  /// No description provided for @optimal.
  ///
  /// In en, this message translates to:
  /// **'Optimal'**
  String get optimal;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @growthStage.
  ///
  /// In en, this message translates to:
  /// **'Growth Stage'**
  String get growthStage;

  /// No description provided for @cases.
  ///
  /// In en, this message translates to:
  /// **'{count} cases'**
  String cases(int count);

  /// No description provided for @cropGrapes.
  ///
  /// In en, this message translates to:
  /// **'Grapes'**
  String get cropGrapes;

  /// No description provided for @cropCorn.
  ///
  /// In en, this message translates to:
  /// **'Corn'**
  String get cropCorn;

  /// No description provided for @cropSugarcane.
  ///
  /// In en, this message translates to:
  /// **'Sugarcane'**
  String get cropSugarcane;

  /// No description provided for @cropPepperBell.
  ///
  /// In en, this message translates to:
  /// **'Pepper Bell'**
  String get cropPepperBell;

  /// No description provided for @scatteredClouds.
  ///
  /// In en, this message translates to:
  /// **'Scattered Clouds'**
  String get scatteredClouds;

  /// No description provided for @humid.
  ///
  /// In en, this message translates to:
  /// **'Humid'**
  String get humid;
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
      <String>['en', 'hi', 'mr', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
