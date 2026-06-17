// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'கிருஷி விகாஸ் AI';

  @override
  String get appTagline => 'AI-இயக்கிய விவசாய உதவியாளர்';

  @override
  String get getStarted => 'தொடங்குங்கள்';

  @override
  String get continueWithoutAccount => 'கணக்கு இல்லாமல் தொடரவும்';

  @override
  String get login => 'உள்நுழைவு';

  @override
  String get logout => 'வெளியேறு';

  @override
  String get enterPhoneNumber => 'உங்கள் தொலைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get weWillSendOtp => 'நாங்கள் உங்களுக்கு OTP அனுப்புவோம்';

  @override
  String get phoneNumber => 'தொலைபேசி எண்';

  @override
  String get getOtp => 'OTP பெறுக';

  @override
  String get verifyOtp => 'OTP சரிபார்க்கவும்';

  @override
  String get enterOtp => 'OTP உள்ளிடவும்';

  @override
  String get resendOtp => 'OTP மீண்டும் அனுப்பவும்';

  @override
  String get invalidOtp => 'தவறான OTP. மீண்டும் முயற்சிக்கவும்.';

  @override
  String otpSent(String phone) {
    return 'OTP +91 $phone க்கு அனுப்பப்பட்டது';
  }

  @override
  String get chooseLanguage => 'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get addFirstFarm => 'உங்கள் முதல் பண்ணையைச் சேர்க்கவும்';

  @override
  String get farmName => 'பண்ணையின் பெயர்';

  @override
  String get farmNameHint => 'எ.கா. முதன்மை பண்ணை';

  @override
  String get primaryCrop => 'முதன்மை பயிர்';

  @override
  String get farmSize => 'பண்ணை அளவு';

  @override
  String get farmingType => 'விவசாய வகை';

  @override
  String get useMyLocation => 'எனது இருப்பிடத்தைப் பயன்படுத்தவும்';

  @override
  String get sowingDate => 'விதைப்பு தேதி';

  @override
  String get yourFarmIsReady => 'உங்கள் பண்ணை தயார்!';

  @override
  String get farmSetupComplete =>
      'பயிர்களை ஸ்கேன் செய்யத் தொடங்குங்கள், விலைகளைச் சரிபார்க்கவும் மற்றும் தனிப்பட்ட ஆலோசனையைப் பெறவும்.';

  @override
  String get next => 'அடுத்து';

  @override
  String get goToHome => 'முகப்புக்குச் செல்';

  @override
  String get home => 'முகப்பு';

  @override
  String get map => 'வரைபடம்';

  @override
  String get scan => 'ஸ்கேன்';

  @override
  String get chat => 'அரட்டை';

  @override
  String get myFarm => 'எனது பண்ணை';

  @override
  String get scanYourCrop => 'உங்கள் பயிரை ஸ்கேன் செய்யுங்கள்';

  @override
  String scanningFor(String crop) {
    return 'ஸ்கேன் செய்கிறது: $crop';
  }

  @override
  String get takePhoto => 'புகைப்படம் எடுக்கவும்';

  @override
  String get uploadFromGallery => 'கேலரியிலிருந்து பதிவேற்றவும்';

  @override
  String get useThisPhoto => 'இந்த புகைப்படத்தைப் பயன்படுத்தவும்';

  @override
  String get retake => 'மீண்டும் எடுக்கவும்';

  @override
  String get analysingCrop => 'உங்கள் பயிரை பகுப்பாய்வு செய்கிறது...';

  @override
  String get diagnosisResult => 'நோயறிதல் முடிவு';

  @override
  String get organic => 'இயற்கை';

  @override
  String get chemical => 'ரசாயன';

  @override
  String get preventionTip => 'தடுப்பு குறிப்பு';

  @override
  String get nearestKvk => 'அருகிலுள்ள KVK';

  @override
  String get saveToFarmLog => 'பண்ணை பதிவில் சேமிக்கவும்';

  @override
  String get scanAgain => 'மீண்டும் ஸ்கேன் செய்';

  @override
  String get askAboutFarm => 'உங்கள் பண்ணையைப் பற்றி எதையும் கேளுங்கள்';

  @override
  String get aiChat => 'AI அரட்டை';

  @override
  String get typeMessage => 'உங்கள் பண்ணையைப் பற்றி கேளுங்கள்...';

  @override
  String get diseaseOutbreak => 'நோய் பரவல்';

  @override
  String get climateRisk => 'காலநிலை ஆபத்து';

  @override
  String get noOutbreaks =>
      'உங்கள் அருகில் நோய்த்தொற்றுகள் எதுவும் அறிவிக்கப்படவில்லை ✅';

  @override
  String get mandiPrices => 'சந்தை விலைகள்';

  @override
  String get live => 'நேரடி';

  @override
  String get whereToSell => 'எங்கே விற்பது';

  @override
  String pricePerQuintal(String price) {
    return '₹$price/குவின்டால்';
  }

  @override
  String get governmentSchemes => 'அரசு திட்டங்கள்';

  @override
  String get applyOnGovWebsite => 'அரசு வலைதளத்தில் விண்ணப்பிக்கவும்';

  @override
  String get callHelpline => 'உதவி எண்ணை அழைக்கவும்';

  @override
  String get eligibility => 'தகுதி';

  @override
  String get howToApply => 'எப்படி விண்ணப்பிப்பது';

  @override
  String get documentsNeeded => 'தேவைப்படும் ஆவணங்கள்';

  @override
  String get soilHealth => 'மண் ஆரோக்கியம்';

  @override
  String get soilScore => 'மண் மதிப்பெண்';

  @override
  String get degraded => 'சிதைந்தது';

  @override
  String get fair => 'நடுநிலை';

  @override
  String get healthy => 'ஆரோக்கியமான';

  @override
  String get excellent => 'சிறந்த';

  @override
  String get soilGuardian => 'மண் பாதுகாவலர்';

  @override
  String get usedOrganic => 'இயற்கை முறை பயன்படுத்தப்பட்டது +10';

  @override
  String get usedChemical => 'ரசாயன முறை பயன்படுத்தப்பட்டது +2';

  @override
  String get farmDetails => 'பண்ணை விவரங்கள்';

  @override
  String get farmLifecycle => 'பண்ணை வாழ்க்கைச் சுழற்சி';

  @override
  String get diagnosisLog => 'நோயறிதல் பதிவு';

  @override
  String get noDiagnosesYet =>
      'நோயறிதல்கள் எதுவும் இல்லை. தொடங்க பயிரை ஸ்கேன் செய்யவும்.';

  @override
  String get addFarm => 'பண்ணையைச் சேர்';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get language => 'மொழி';

  @override
  String get notifications => 'அறிவிப்புகள்';

  @override
  String get account => 'கணக்கு';

  @override
  String get appVersion => 'செயலி பதிப்பு';

  @override
  String get privacyPolicy => 'தனியுரிமைக் கொள்கை';

  @override
  String get noAlerts => 'இதுவரை எந்த அறிவிப்பும் இல்லை.';

  @override
  String get noConnection =>
      'இணைப்பு இல்லை — தேக்ககப்படுத்தப்பட்ட தரவைக் காட்டுகிறது';

  @override
  String get sessionExpired => 'அமர்வு காலாவதியானது. மீண்டும் உள்நுழையவும்.';

  @override
  String get somethingWentWrong => 'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get couldNotAnalyse =>
      'பகுப்பாய்வு செய்ய முடியவில்லை. உங்கள் இணைப்பை சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get retry => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get cropTomato => 'தக்காளி';

  @override
  String get cropOnion => 'வெங்காயம்';

  @override
  String get cropCotton => 'பருத்தி';

  @override
  String get cropWheat => 'கோதுமை';

  @override
  String get cropSoybean => 'சோயாபீன்';

  @override
  String get cropRice => 'அரிசி';

  @override
  String get cropPotato => 'உருளைக்கிழங்கு';

  @override
  String get cropOther => 'மற்றவை';

  @override
  String get stageSowing => 'விடைப்பு';

  @override
  String get stageGermination => 'முளைப்பு';

  @override
  String get stageVegetative => 'தாவரவியல்';

  @override
  String get stageFlowering => 'பூக்கும்';

  @override
  String get stageHarvest => 'அறுவடை';

  @override
  String get typeOrganic => 'இயற்கை';

  @override
  String get typeConventional => 'பாரம்பரிய';

  @override
  String get typeMixed => 'கலப்பு';

  @override
  String get selectFarm => 'பண்ணையைத் தேர்ந்தெடு';

  @override
  String get detectDiseasesInstantly => 'நோய்களை உடனே கண்டறியவும்';

  @override
  String get marketPrices => 'சந்தை விலைகள்';

  @override
  String get seeAll => 'அனைத்தையும் பார் →';

  @override
  String get viewAll => 'அனைத்தையும் பார் →';

  @override
  String get noLocationData => 'இருப்பிட தரவு இல்லை';

  @override
  String get couldNotLoadWeather => 'வானிலை விவரங்களை ஏற்ற முடியவில்லை';

  @override
  String get noPricesAvailable => 'விலை விவரங்கள் இல்லை';

  @override
  String get couldNotLoadPrices => 'விலைகளை ஏற்ற முடியவில்லை';

  @override
  String get selectLanguage => 'மொழியைத் தேர்ந்தெடுக்கவும் / Select Language';

  @override
  String get authenticatedAccount => 'சரிபார்க்கப்பட்ட கணக்கு';

  @override
  String get offlineGuestMode => 'ஆஃப்லைன் / விருந்தினர் பயன்முறை';

  @override
  String get diseaseOutbreakAlerts => 'நோய் வெடிப்பு எச்சரிக்கைகள்';

  @override
  String get notifyDiseaseSubtitle =>
      'உங்களுக்கு அருகில் பூச்சி/நோய் பரவும் போது அறிவிக்கவும்';

  @override
  String get climateWeatherWarnings => 'காலநிலை மற்றும் வானிலை எச்சரிக்கைகள்';

  @override
  String get notifyClimateSubtitle =>
      'தீவிர வானிலை எச்சரிக்கைகள் பற்றி அறிவிக்கவும்';

  @override
  String get mandiPriceAlerts => 'சந்தை விலை எச்சரிக்கைகள்';

  @override
  String get notifyMandiSubtitle => 'விலைகள் கணிசமாக மாறும்போது அறிவிக்கவும்';

  @override
  String get confirmPhoto => 'புகைப்படத்தை உறுதிப்படுத்து';

  @override
  String get analysisFailed => 'பகுப்பாய்வு தோல்வியடைந்தது';

  @override
  String get retryAnalysis => 'மீண்டும் பகுப்பாய்வு செய்';

  @override
  String get cameraPermissionRequired => 'கேமரா அனுமதி தேவை';

  @override
  String get openSystemCamera => 'சிஸ்டம் கேமராவைத் திறக்கவும்';

  @override
  String get organicTreatment => 'இயற்கை சிகிச்சை';

  @override
  String get chemicalTreatment => 'ரசாயன சிகிச்சை';

  @override
  String get treatmentSteps => 'சிகிச்சை படிகள்';

  @override
  String get estimatedCost => 'மதிப்பிடப்பட்ட செலவு';

  @override
  String get consultKvk => 'அருகிலுள்ள KVK-ஐ அணுகவும்';

  @override
  String get noKvkFound => 'KVK நிபுணர் விவரங்கள் எதுவும் கிடைக்கவில்லை';

  @override
  String get scanAgainBtn => 'மீண்டும் ஸ்கேன் செய்';

  @override
  String get goHome => 'முகப்புக்குச் செல்';

  @override
  String get totalEstimatedCost => 'மொத்த மதிப்பிடப்பட்ட செலவு';

  @override
  String get totalEstimate => 'மொத்த மதிப்பீடு';

  @override
  String get callKvkExpert => 'KVK நிபுணரை அழைக்கவும்';

  @override
  String get viewDetailsApply => 'விவரங்களை பார்த்து விண்ணப்பிக்கவும்';

  @override
  String get directBenefit => 'நேரடி பயன் பரிமாற்றம் (DBT) தகுதி பெற்றது';

  @override
  String get cropInsurance => 'பயிர் காப்பீடு';

  @override
  String get acres => 'ஏக்கர்';

  @override
  String get stage => 'நிலை:';

  @override
  String get fitLeafInGuide => 'இலையை சதுர வழிகாட்டிக்குள் பொருத்தவும்';

  @override
  String get allowCameraAccess =>
      'இந்த அம்சத்தைப் பயன்படுத்த அமைப்புகளில் கேமரா அனுமதியை அனுமதிக்கவும்.';

  @override
  String get cameraUnavailable => 'கேமரா கிடைக்கவில்லை';

  @override
  String get initializingCamera => 'கேமரா தொடங்கப்படுகிறது...';

  @override
  String get highRisk => 'அதிக ஆபத்து';

  @override
  String get medium => 'நடுத்தரம்';

  @override
  String get lowRisk => 'குறைந்த ஆபத்து';

  @override
  String get climateLegend => 'காலநிலை தகவல்';

  @override
  String get clear => 'தெளிவான';

  @override
  String get partlyCloudy => 'பகுதி மேகமூட்டம்';

  @override
  String get overcast => 'மேகமூட்டம்';

  @override
  String get clouds => 'மேகங்கள்';

  @override
  String get temperature => 'வெப்பநிலை';

  @override
  String get precipitation => 'மழை';

  @override
  String get wind => 'காற்று';

  @override
  String get soilHealthScore => 'மண் ஆரோக்கிய மதிப்பெண்';

  @override
  String get moderate => 'மிதமான';

  @override
  String get nitrogenN => 'நைட்ரஜன் (N)';

  @override
  String get phosphorusP => 'பாஸ்பரஸ் (P)';

  @override
  String get potassiumK => 'பொட்டாசியம் (K)';

  @override
  String get optimal => 'சிறந்த';

  @override
  String get good => 'நல்லது';

  @override
  String get low => 'குறைவு';

  @override
  String get growthStage => 'வளர்ச்சி நிலை';

  @override
  String cases(int count) {
    return '$count வழக்குகள்';
  }

  @override
  String get cropGrapes => 'திராட்சை';

  @override
  String get cropCorn => 'சோளம்';

  @override
  String get cropSugarcane => 'கரும்பு';

  @override
  String get cropPepperBell => 'குடை மிளகாய்';

  @override
  String get scatteredClouds => 'சிதறிய மேகங்கள்';

  @override
  String get humid => 'ஈரப்பதமான';
}
