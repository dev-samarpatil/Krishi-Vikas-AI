// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'कृषी विकास AI';

  @override
  String get appTagline => 'AI-संचालित शेती सहाय्यक';

  @override
  String get getStarted => 'सुरू करा';

  @override
  String get continueWithoutAccount => 'खात्याशिवाय सुरू ठेवा';

  @override
  String get login => 'लॉगिन';

  @override
  String get logout => 'साइन आउट';

  @override
  String get enterPhoneNumber => 'तुमचा फोन नंबर टाका';

  @override
  String get weWillSendOtp => 'आम्ही तुम्हाला OTP पाठवू';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get getOtp => 'OTP मिळवा';

  @override
  String get verifyOtp => 'OTP सत्यापित करा';

  @override
  String get enterOtp => 'OTP टाका';

  @override
  String get resendOtp => 'OTP पुन्हा पाठवा';

  @override
  String get invalidOtp => 'चुकीचा OTP. पुन्हा प्रयत्न करा.';

  @override
  String otpSent(String phone) {
    return '+91 $phone वर OTP पाठवला आहे';
  }

  @override
  String get chooseLanguage => 'तुमची भाषा निवडा';

  @override
  String get addFirstFarm => 'तुमचा पहिला शेत जोडा';

  @override
  String get farmName => 'शेताचे नाव';

  @override
  String get farmNameHint => 'उदा. मुख्य शेत';

  @override
  String get primaryCrop => 'मुख्य पीक';

  @override
  String get farmSize => 'शेताचा आकार';

  @override
  String get farmingType => 'शेतीचा प्रकार';

  @override
  String get useMyLocation => 'माझे स्थान वापरा';

  @override
  String get sowingDate => 'पेरणीची तारीख';

  @override
  String get yourFarmIsReady => 'तुमचे शेत तयार आहे!';

  @override
  String get farmSetupComplete =>
      'पिकांचे स्कॅनिंग सुरू करा, दर तपासा आणि वैयक्तिकृत सल्ला मिळवा.';

  @override
  String get next => 'पुढे';

  @override
  String get goToHome => 'होमवर जा';

  @override
  String get home => 'होम';

  @override
  String get map => 'नकाशा';

  @override
  String get scan => 'स्कॅन';

  @override
  String get chat => 'चॅट';

  @override
  String get myFarm => 'माझे शेत';

  @override
  String get scanYourCrop => 'तुमचे पीक स्कॅन करा';

  @override
  String scanningFor(String crop) {
    return 'स्कॅनिंग: $crop';
  }

  @override
  String get takePhoto => 'फोटो घ्या';

  @override
  String get uploadFromGallery => 'गॅलरीतून अपलोड करा';

  @override
  String get useThisPhoto => 'हा फोटो वापरा';

  @override
  String get retake => 'पुन्हा घ्या';

  @override
  String get analysingCrop => 'तुमच्या पिकाचे विश्लेषण होत आहे...';

  @override
  String get diagnosisResult => 'निदान परिणाम';

  @override
  String get organic => 'सेंद्रिय';

  @override
  String get chemical => 'रासायनिक';

  @override
  String get preventionTip => 'प्रतिबंध टिप';

  @override
  String get nearestKvk => 'जवळचे KVK';

  @override
  String get saveToFarmLog => 'फार्म लॉग मध्ये जतन करा';

  @override
  String get scanAgain => 'पुन्हा स्कॅन करा';

  @override
  String get askAboutFarm => 'तुमच्या शेताबद्दल काहीही विचारा';

  @override
  String get aiChat => 'AI चॅट';

  @override
  String get typeMessage => 'तुमच्या शेताबद्दल विचारा...';

  @override
  String get diseaseOutbreak => 'रोग उद्रेक';

  @override
  String get climateRisk => 'हवामान धोका';

  @override
  String get noOutbreaks =>
      'तुमच्या जवळ कोणत्याही रोगाचा प्रादुर्भाव झाल्याचे वृत्त नाही ✅';

  @override
  String get mandiPrices => 'मंडी भाव';

  @override
  String get live => 'लाइव्ह';

  @override
  String get whereToSell => 'कुठे विकायचे';

  @override
  String pricePerQuintal(String price) {
    return '₹$price/क्विंटल';
  }

  @override
  String get governmentSchemes => 'सरकारी योजना';

  @override
  String get applyOnGovWebsite => 'सरकारी वेबसाइटवर अर्ज करा';

  @override
  String get callHelpline => 'हेल्पलाइनवर कॉल करा';

  @override
  String get eligibility => 'पात्रता';

  @override
  String get howToApply => 'अर्ज कसा करावा';

  @override
  String get documentsNeeded => 'आवश्यक कागदपत्रे';

  @override
  String get soilHealth => 'माती आरोग्य';

  @override
  String get soilScore => 'माती स्कोअर';

  @override
  String get degraded => 'खराब';

  @override
  String get fair => 'बरे';

  @override
  String get healthy => 'निरोगी';

  @override
  String get excellent => 'उत्कृष्ट';

  @override
  String get soilGuardian => 'माती रक्षक';

  @override
  String get usedOrganic => 'सेंद्रिय वापरले +10';

  @override
  String get usedChemical => 'रासायनिक वापरले +2';

  @override
  String get farmDetails => 'शेताचा तपशील';

  @override
  String get farmLifecycle => 'शेतीचे जीवन चक्र';

  @override
  String get diagnosisLog => 'निदान लॉग';

  @override
  String get noDiagnosesYet =>
      'अद्याप कोणतेही निदान नाही. सुरू करण्यासाठी तुमचे पीक स्कॅन करा.';

  @override
  String get addFarm => 'शेत जोडा';

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get language => 'भाषा';

  @override
  String get notifications => 'सूचना';

  @override
  String get account => 'खाते';

  @override
  String get appVersion => 'अॅप आवृत्ती';

  @override
  String get privacyPolicy => 'गोपनीयता धोरण';

  @override
  String get noAlerts => 'अद्याप कोणतीही सूचना नाही.';

  @override
  String get noConnection => 'कनेक्शन नाही — कॅश्ड डेटा दाखवत आहे';

  @override
  String get sessionExpired => 'सत्र संपले आहे. कृपया पुन्हा लॉगिन करा.';

  @override
  String get somethingWentWrong =>
      'काहीतरी चूक झाली. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get couldNotAnalyse =>
      'विश्लेषण होऊ शकले नाही. तुमचे कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.';

  @override
  String get retry => 'पुन्हा प्रयत्न करा';

  @override
  String get cropTomato => 'टोमॅटो';

  @override
  String get cropOnion => 'कांदा';

  @override
  String get cropCotton => 'कापूस';

  @override
  String get cropWheat => 'गहू';

  @override
  String get cropSoybean => 'सोयाबीन';

  @override
  String get cropRice => 'तांदूळ';

  @override
  String get cropPotato => 'बटाटा';

  @override
  String get cropOther => 'इतर';

  @override
  String get stageSowing => 'पेरणी';

  @override
  String get stageGermination => 'उगवण';

  @override
  String get stageVegetative => 'वनस्पतिजन्य';

  @override
  String get stageFlowering => 'फुलोरा';

  @override
  String get stageHarvest => 'कापणी';

  @override
  String get typeOrganic => 'सेंद्रिय';

  @override
  String get typeConventional => 'पारंपारिक';

  @override
  String get typeMixed => 'मिश्रित';

  @override
  String get selectFarm => 'शेत निवडा';

  @override
  String get detectDiseasesInstantly => 'रोगांचा त्वरित शोध घ्या';

  @override
  String get marketPrices => 'मंडी भाव';

  @override
  String get seeAll => 'सर्व पहा →';

  @override
  String get viewAll => 'सर्व पहा →';

  @override
  String get noLocationData => 'स्थान डेटा उपलब्ध नाही';

  @override
  String get couldNotLoadWeather => 'हवामान लोड होऊ शकले नाही';

  @override
  String get noPricesAvailable => 'कोणतेही दर उपलब्ध नाहीत';

  @override
  String get couldNotLoadPrices => 'दर लोड होऊ शकले नाहीत';

  @override
  String get selectLanguage => 'भाषा निवडा / Select Language';

  @override
  String get authenticatedAccount => 'सत्यापित खाते';

  @override
  String get offlineGuestMode => 'ऑफलाइन / अतिथी मोड';

  @override
  String get diseaseOutbreakAlerts => 'रोग उद्रेक अलर्ट';

  @override
  String get notifyDiseaseSubtitle =>
      'तुमच्या जवळ कीटक/रोगांचा प्रादुर्भाव झाल्यावर सूचित करा';

  @override
  String get climateWeatherWarnings => 'हवामान आणि हवामानाचा इशारा';

  @override
  String get notifyClimateSubtitle => 'गंभीर हवामान इशाऱ्यांबद्दल सूचित करा';

  @override
  String get mandiPriceAlerts => 'मंडी भाव अलर्ट';

  @override
  String get notifyMandiSubtitle => 'भावात लक्षणीय बदल झाल्यावर सूचित करा';

  @override
  String get confirmPhoto => 'फोटोची पुष्टी करा';

  @override
  String get analysisFailed => 'विश्लेषण अयशस्वी';

  @override
  String get retryAnalysis => 'विश्लेषण पुन्हा प्रयत्न करा';

  @override
  String get cameraPermissionRequired => 'कॅमेरा परवानगी आवश्यक आहे';

  @override
  String get openSystemCamera => 'सिस्टम कॅमेरा उघडा';

  @override
  String get organicTreatment => 'सेंद्रिय उपचार';

  @override
  String get chemicalTreatment => 'रासायनिक उपचार';

  @override
  String get treatmentSteps => 'उपचार पायऱ्या';

  @override
  String get estimatedCost => 'अंदाजे खर्च';

  @override
  String get consultKvk => 'जवळच्या KVK चा सल्ला घ्या';

  @override
  String get noKvkFound => 'कोणताही KVK तज्ञ तपशील आढळला नाही';

  @override
  String get scanAgainBtn => 'पुन्हा स्कॅन करा';

  @override
  String get goHome => 'होमवर जा';

  @override
  String get totalEstimatedCost => 'एकूण अंदाजे खर्च';

  @override
  String get totalEstimate => 'एकूण अंदाज';

  @override
  String get callKvkExpert => 'KVK तज्ञाला कॉल करा';

  @override
  String get viewDetailsApply => 'तपशील पहा आणि अर्ज करा';

  @override
  String get directBenefit => 'प्रत्यक्ष लाभ हस्तांतरण (DBT) पात्र';

  @override
  String get cropInsurance => 'पीक विमा';

  @override
  String get acres => 'एकर';

  @override
  String get stage => 'टप्पा:';

  @override
  String get fitLeafInGuide => 'पाने चौकोनी मार्गदर्शकाच्या आत बसवा';

  @override
  String get allowCameraAccess =>
      'वैशिष्ट्य वापरण्यासाठी सेटिंग्जमध्ये कॅमेरा परवानगी द्या.';

  @override
  String get cameraUnavailable => 'कॅमेरा उपलब्ध नाही';

  @override
  String get initializingCamera => 'कॅमेरा सुरू होत आहे...';

  @override
  String get highRisk => 'उच्च धोका';

  @override
  String get medium => 'मध्यम';

  @override
  String get lowRisk => 'कमी धोका';

  @override
  String get climateLegend => 'हवामान माहिती';

  @override
  String get clear => 'स्वच्छ';

  @override
  String get partlyCloudy => 'अंशतः ढगाळ';

  @override
  String get overcast => 'पूर्ण ढगाळ';

  @override
  String get clouds => 'ढग';

  @override
  String get temperature => 'तापमान';

  @override
  String get precipitation => 'पाऊस';

  @override
  String get wind => 'वारा';

  @override
  String get soilHealthScore => 'माती आरोग्य स्कोअर';

  @override
  String get moderate => 'मध्यम';

  @override
  String get nitrogenN => 'नायट्रोजन (N)';

  @override
  String get phosphorusP => 'फॉस्फरस (P)';

  @override
  String get potassiumK => 'पोटॅशियम (K)';

  @override
  String get optimal => 'उत्तम';

  @override
  String get good => 'चांगले';

  @override
  String get low => 'कमी';

  @override
  String get growthStage => 'वाढीचा टप्पा';

  @override
  String cases(int count) {
    return '$count प्रकरणे';
  }

  @override
  String get cropGrapes => 'द्राक्षे';

  @override
  String get cropCorn => 'मका';

  @override
  String get cropSugarcane => 'ऊस';

  @override
  String get cropPepperBell => 'शिमला मिरची';

  @override
  String get scatteredClouds => 'विखुरलेले ढग';

  @override
  String get humid => 'दमट';
}
