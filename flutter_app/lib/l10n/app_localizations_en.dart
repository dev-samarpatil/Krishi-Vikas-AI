// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Krishi Vikas AI';

  @override
  String get appTagline => 'AI-Powered Farming Assistant';

  @override
  String get getStarted => 'Get Started';

  @override
  String get continueWithoutAccount => 'Continue without account';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Sign Out';

  @override
  String get enterPhoneNumber => 'Enter your phone number';

  @override
  String get weWillSendOtp => 'We\'ll send you an OTP to verify';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get getOtp => 'Get OTP';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get enterOtp => 'Enter OTP';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get invalidOtp => 'Invalid OTP. Try again.';

  @override
  String otpSent(String phone) {
    return 'OTP sent to +91 $phone';
  }

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get addFirstFarm => 'Add your first farm';

  @override
  String get farmName => 'Farm Name';

  @override
  String get farmNameHint => 'e.g. Main Farm';

  @override
  String get primaryCrop => 'Primary Crop';

  @override
  String get farmSize => 'Farm Size';

  @override
  String get farmingType => 'Farming Type';

  @override
  String get useMyLocation => 'Use My Location';

  @override
  String get sowingDate => 'Sowing Date';

  @override
  String get yourFarmIsReady => 'Your farm is ready!';

  @override
  String get farmSetupComplete =>
      'Start scanning crops, checking prices, and getting personalised advice.';

  @override
  String get next => 'Next';

  @override
  String get goToHome => 'Go to Home';

  @override
  String get home => 'Home';

  @override
  String get map => 'Map';

  @override
  String get scan => 'Scan';

  @override
  String get chat => 'Chat';

  @override
  String get myFarm => 'My Farm';

  @override
  String get scanYourCrop => 'Scan Your Crop';

  @override
  String scanningFor(String crop) {
    return 'Scanning for: $crop';
  }

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get uploadFromGallery => 'Upload from Gallery';

  @override
  String get useThisPhoto => 'Use This Photo';

  @override
  String get retake => 'Retake';

  @override
  String get analysingCrop => 'Analysing your crop...';

  @override
  String get diagnosisResult => 'Diagnosis Result';

  @override
  String get organic => 'Organic';

  @override
  String get chemical => 'Chemical';

  @override
  String get preventionTip => 'Prevention Tip';

  @override
  String get nearestKvk => 'Nearest KVK';

  @override
  String get saveToFarmLog => 'Save to Farm Log';

  @override
  String get scanAgain => 'Scan Again';

  @override
  String get askAboutFarm => 'Ask me anything about your farm';

  @override
  String get aiChat => 'AI Chat';

  @override
  String get typeMessage => 'Ask about your farm...';

  @override
  String get diseaseOutbreak => 'Disease Outbreak';

  @override
  String get climateRisk => 'Climate Risk';

  @override
  String get noOutbreaks => 'No disease outbreaks reported near you ✅';

  @override
  String get mandiPrices => 'Mandi Prices';

  @override
  String get live => 'Live';

  @override
  String get whereToSell => 'Where to Sell';

  @override
  String pricePerQuintal(String price) {
    return '₹$price/quintal';
  }

  @override
  String get governmentSchemes => 'Government Schemes';

  @override
  String get applyOnGovWebsite => 'Apply on Government Website';

  @override
  String get callHelpline => 'Call Helpline';

  @override
  String get eligibility => 'Eligibility';

  @override
  String get howToApply => 'How to Apply';

  @override
  String get documentsNeeded => 'Documents Needed';

  @override
  String get soilHealth => 'Soil Health';

  @override
  String get soilScore => 'Soil Score';

  @override
  String get degraded => 'DEGRADED';

  @override
  String get fair => 'FAIR';

  @override
  String get healthy => 'HEALTHY';

  @override
  String get excellent => 'EXCELLENT';

  @override
  String get soilGuardian => 'Soil Guardian';

  @override
  String get usedOrganic => 'Used Organic +10';

  @override
  String get usedChemical => 'Used Chemical +2';

  @override
  String get farmDetails => 'Farm Details';

  @override
  String get farmLifecycle => 'Farm Lifecycle';

  @override
  String get diagnosisLog => 'Diagnosis Log';

  @override
  String get noDiagnosesYet =>
      'No diagnoses yet. Scan your crop to get started.';

  @override
  String get addFarm => 'Add Farm';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get account => 'Account';

  @override
  String get appVersion => 'App Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get noAlerts =>
      'No alerts yet. We\'ll notify you of important changes.';

  @override
  String get noConnection => 'No connection — showing cached data';

  @override
  String get sessionExpired => 'Session expired. Please login again.';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get couldNotAnalyse =>
      'Could not analyse. Check your connection and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get cropTomato => 'Tomato';

  @override
  String get cropOnion => 'Onion';

  @override
  String get cropCotton => 'Cotton';

  @override
  String get cropWheat => 'Wheat';

  @override
  String get cropSoybean => 'Soybean';

  @override
  String get cropRice => 'Rice';

  @override
  String get cropPotato => 'Potato';

  @override
  String get cropOther => 'Other';

  @override
  String get stageSowing => 'Sowing';

  @override
  String get stageGermination => 'Germination';

  @override
  String get stageVegetative => 'Vegetative';

  @override
  String get stageFlowering => 'Flowering';

  @override
  String get stageHarvest => 'Harvest';

  @override
  String get typeOrganic => 'Organic';

  @override
  String get typeConventional => 'Conventional';

  @override
  String get typeMixed => 'Mixed';

  @override
  String get selectFarm => 'Select Farm';

  @override
  String get detectDiseasesInstantly => 'Detect diseases instantly';

  @override
  String get marketPrices => 'Market Prices';

  @override
  String get seeAll => 'See All →';

  @override
  String get viewAll => 'View All →';

  @override
  String get noLocationData => 'No location data';

  @override
  String get couldNotLoadWeather => 'Could not load weather';

  @override
  String get noPricesAvailable => 'No prices available';

  @override
  String get couldNotLoadPrices => 'Could not load prices';

  @override
  String get selectLanguage => 'Select Language / भाषा चुनें';

  @override
  String get authenticatedAccount => 'Authenticated account';

  @override
  String get offlineGuestMode => 'Offline / Guest Mode';

  @override
  String get diseaseOutbreakAlerts => 'Disease Outbreak Alerts';

  @override
  String get notifyDiseaseSubtitle =>
      'Notify when pests/diseases outbreaks occur near you';

  @override
  String get climateWeatherWarnings => 'Climate & Weather Warnings';

  @override
  String get notifyClimateSubtitle => 'Notify about extreme weather alerts';

  @override
  String get mandiPriceAlerts => 'Mandi Price Alerts';

  @override
  String get notifyMandiSubtitle => 'Notify when prices change significantly';

  @override
  String get confirmPhoto => 'Confirm Photo';

  @override
  String get analysisFailed => 'Analysis Failed';

  @override
  String get retryAnalysis => 'Retry Analysis';

  @override
  String get cameraPermissionRequired => 'Camera Permission Required';

  @override
  String get openSystemCamera => 'Open System Camera';

  @override
  String get organicTreatment => 'Organic Treatment';

  @override
  String get chemicalTreatment => 'Chemical Treatment';

  @override
  String get treatmentSteps => 'Treatment Steps';

  @override
  String get estimatedCost => 'Estimated Cost';

  @override
  String get consultKvk => 'Consult nearest KVK';

  @override
  String get noKvkFound => 'No KVK expert details found';

  @override
  String get scanAgainBtn => 'Scan Again';

  @override
  String get goHome => 'Go Home';

  @override
  String get totalEstimatedCost => 'Total Estimated Cost';

  @override
  String get totalEstimate => 'Total Estimate';

  @override
  String get callKvkExpert => 'Call KVK Expert';

  @override
  String get viewDetailsApply => 'View Details & Apply';

  @override
  String get directBenefit => 'Direct Benefit Transfer (DBT) eligible';

  @override
  String get cropInsurance => 'Crop Insurance';

  @override
  String get acres => 'ACRES';

  @override
  String get stage => 'Stage:';

  @override
  String get fitLeafInGuide => 'Fit the leaf inside the square guide';

  @override
  String get allowCameraAccess =>
      'Allow camera access in Settings to use this feature.';

  @override
  String get cameraUnavailable => 'Camera unavailable';

  @override
  String get initializingCamera => 'Initializing camera...';

  @override
  String get highRisk => 'High Risk';

  @override
  String get medium => 'Medium';

  @override
  String get lowRisk => 'Low Risk';

  @override
  String get climateLegend => 'Climate Legend';

  @override
  String get clear => 'Clear';

  @override
  String get partlyCloudy => 'Partly Cloudy';

  @override
  String get overcast => 'Overcast';

  @override
  String get clouds => 'Clouds';

  @override
  String get temperature => 'Temperature';

  @override
  String get precipitation => 'Precipitation';

  @override
  String get wind => 'Wind';

  @override
  String get soilHealthScore => 'Soil Health Score';

  @override
  String get moderate => 'Moderate';

  @override
  String get nitrogenN => 'Nitrogen (N)';

  @override
  String get phosphorusP => 'Phosphorus (P)';

  @override
  String get potassiumK => 'Potassium (K)';

  @override
  String get optimal => 'Optimal';

  @override
  String get good => 'Good';

  @override
  String get low => 'Low';

  @override
  String get growthStage => 'Growth Stage';

  @override
  String cases(int count) {
    return '$count cases';
  }

  @override
  String get cropGrapes => 'Grapes';

  @override
  String get cropCorn => 'Corn';

  @override
  String get cropSugarcane => 'Sugarcane';

  @override
  String get cropPepperBell => 'Pepper Bell';

  @override
  String get scatteredClouds => 'Scattered Clouds';

  @override
  String get humid => 'Humid';
}
