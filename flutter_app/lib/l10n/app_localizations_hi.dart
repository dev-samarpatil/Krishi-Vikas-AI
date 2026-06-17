// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'कृषि विकास AI';

  @override
  String get appTagline => 'AI-संचालित कृषि सहायक';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get continueWithoutAccount => 'बिना अकाउंट के जारी रखें';

  @override
  String get login => 'लॉगिन';

  @override
  String get logout => 'साइन आउट';

  @override
  String get enterPhoneNumber => 'अपना फोन नंबर दर्ज करें';

  @override
  String get weWillSendOtp => 'हम आपको OTP भेजेंगे';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get getOtp => 'OTP प्राप्त करें';

  @override
  String get verifyOtp => 'OTP सत्यापित करें';

  @override
  String get enterOtp => 'OTP दर्ज करें';

  @override
  String get resendOtp => 'OTP पुनः भेजें';

  @override
  String get invalidOtp => 'गलत OTP। फिर से कोशिश करें।';

  @override
  String otpSent(String phone) {
    return 'OTP +91 $phone पर भेजा गया';
  }

  @override
  String get chooseLanguage => 'अपनी भाषा चुनें';

  @override
  String get addFirstFarm => 'अपना पहला खेत जोड़ें';

  @override
  String get farmName => 'खेत का नाम';

  @override
  String get farmNameHint => 'जैसे: मुख्य खेत';

  @override
  String get primaryCrop => 'मुख्य फसल';

  @override
  String get farmSize => 'खेत का आकार';

  @override
  String get farmingType => 'खेती का प्रकार';

  @override
  String get useMyLocation => 'मेरा स्थान उपयोग करें';

  @override
  String get sowingDate => 'बुवाई की तारीख';

  @override
  String get yourFarmIsReady => 'आपका खेत तैयार है!';

  @override
  String get farmSetupComplete =>
      'फसलों को स्कैन करना, कीमतें देखना और व्यक्तिगत सलाह प्राप्त करना शुरू करें।';

  @override
  String get next => 'अगला';

  @override
  String get goToHome => 'होम पर जाएं';

  @override
  String get home => 'होम';

  @override
  String get map => 'नक्शा';

  @override
  String get scan => 'स्कैन';

  @override
  String get chat => 'चैट';

  @override
  String get myFarm => 'मेरा खेत';

  @override
  String get scanYourCrop => 'अपनी फसल स्कैन करें';

  @override
  String scanningFor(String crop) {
    return 'स्कैनिंग: $crop';
  }

  @override
  String get takePhoto => 'फोटो लें';

  @override
  String get uploadFromGallery => 'गैलरी से अपलोड करें';

  @override
  String get useThisPhoto => 'यह फोटो उपयोग करें';

  @override
  String get retake => 'फिर से लें';

  @override
  String get analysingCrop => 'आपकी फसल का विश्लेषण हो रहा है...';

  @override
  String get diagnosisResult => 'निदान परिणाम';

  @override
  String get organic => 'जैविक';

  @override
  String get chemical => 'रासायनिक';

  @override
  String get preventionTip => 'रोकथाम टिप';

  @override
  String get nearestKvk => 'निकटतम KVK';

  @override
  String get saveToFarmLog => 'फार्म लॉग में सहेजें';

  @override
  String get scanAgain => 'फिर से स्कैन करें';

  @override
  String get askAboutFarm => 'अपने खेत के बारे में कुछ भी पूछें';

  @override
  String get aiChat => 'AI चैट';

  @override
  String get typeMessage => 'अपने खेत के बारे में पूछें...';

  @override
  String get diseaseOutbreak => 'रोग प्रकोप';

  @override
  String get climateRisk => 'जलवायु जोखिम';

  @override
  String get noOutbreaks => 'आपके आस-पास किसी रोग के प्रकोप की सूचना नहीं है ✅';

  @override
  String get mandiPrices => 'मंडी भाव';

  @override
  String get live => 'लाइव';

  @override
  String get whereToSell => 'कहां बेचें';

  @override
  String pricePerQuintal(String price) {
    return '₹$price/क्विंटल';
  }

  @override
  String get governmentSchemes => 'सरकारी योजनाएं';

  @override
  String get applyOnGovWebsite => 'सरकारी वेबसाइट पर आवेदन करें';

  @override
  String get callHelpline => 'हेल्पलाइन पर कॉल करें';

  @override
  String get eligibility => 'पात्रता';

  @override
  String get howToApply => 'आवेदन कैसे करें';

  @override
  String get documentsNeeded => 'आवश्यक दस्तावेज';

  @override
  String get soilHealth => 'मिट्टी स्वास्थ्य';

  @override
  String get soilScore => 'मिट्टी स्कोर';

  @override
  String get degraded => 'खराब';

  @override
  String get fair => 'ठीक';

  @override
  String get healthy => 'स्वस्थ';

  @override
  String get excellent => 'उत्कृष्ट';

  @override
  String get soilGuardian => 'सॉइल गार्जियन';

  @override
  String get usedOrganic => 'जैविक उपयोग किया +10';

  @override
  String get usedChemical => 'रासायनिक उपयोग किया +2';

  @override
  String get farmDetails => 'खेत का विवरण';

  @override
  String get farmLifecycle => 'खेत का जीवन चक्र';

  @override
  String get diagnosisLog => 'निदान लॉग';

  @override
  String get noDiagnosesYet =>
      'अभी तक कोई निदान नहीं। शुरू करने के लिए अपनी फसल स्कैन करें।';

  @override
  String get addFarm => 'खेत जोड़ें';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get account => 'अकाउंट';

  @override
  String get appVersion => 'ऐप संस्करण';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get noAlerts => 'अभी तक कोई सूचना नहीं है।';

  @override
  String get noConnection => 'कनेक्शन नहीं — कैश्ड डेटा दिखा रहे हैं';

  @override
  String get sessionExpired => 'सत्र समाप्त हो गया है। कृपया पुनः लॉगिन करें।';

  @override
  String get somethingWentWrong => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get couldNotAnalyse =>
      'विश्लेषण नहीं हो सका। अपने कनेक्शन की जांच करें और पुनः प्रयास करें।';

  @override
  String get retry => 'पुनः प्रयास';

  @override
  String get cropTomato => 'टमाटर';

  @override
  String get cropOnion => 'प्याज';

  @override
  String get cropCotton => 'कपास';

  @override
  String get cropWheat => 'गेहूं';

  @override
  String get cropSoybean => 'सोयाबीन';

  @override
  String get cropRice => 'चावल';

  @override
  String get cropPotato => 'आलू';

  @override
  String get cropOther => 'अन्य';

  @override
  String get stageSowing => 'बुवाई';

  @override
  String get stageGermination => 'अंकुरण';

  @override
  String get stageVegetative => 'वानस्पतिक';

  @override
  String get stageFlowering => 'फूल';

  @override
  String get stageHarvest => 'कटाई';

  @override
  String get typeOrganic => 'जैविक';

  @override
  String get typeConventional => 'पारंपरिक';

  @override
  String get typeMixed => 'मिश्रित';

  @override
  String get selectFarm => 'खेत चुनें';

  @override
  String get detectDiseasesInstantly => 'तुरंत रोगों का पता लगाएं';

  @override
  String get marketPrices => 'मंडी भाव';

  @override
  String get seeAll => 'सभी देखें →';

  @override
  String get viewAll => 'सभी देखें →';

  @override
  String get noLocationData => 'स्थान डेटा उपलब्ध नहीं';

  @override
  String get couldNotLoadWeather => 'मौसम लोड नहीं हो सका';

  @override
  String get noPricesAvailable => 'कोई भाव उपलब्ध नहीं';

  @override
  String get couldNotLoadPrices => 'भाव लोड नहीं हो सका';

  @override
  String get selectLanguage => 'भाषा चुनें / Select Language';

  @override
  String get authenticatedAccount => 'सत्यापित खाता';

  @override
  String get offlineGuestMode => 'ऑफलाइन / अतिथि मोड';

  @override
  String get diseaseOutbreakAlerts => 'रोग प्रकोप अलर्ट';

  @override
  String get notifyDiseaseSubtitle =>
      'आपके निकट कीट/रोग का प्रकोप होने पर सूचित करें';

  @override
  String get climateWeatherWarnings => 'जलवायु और मौसम की चेतावनी';

  @override
  String get notifyClimateSubtitle =>
      'गंभीर मौसम की चेतावनी के बारे में सूचित करें';

  @override
  String get mandiPriceAlerts => 'मंडी भाव अलर्ट';

  @override
  String get notifyMandiSubtitle =>
      'भाव में महत्वपूर्ण बदलाव होने पर सूचित करें';

  @override
  String get confirmPhoto => 'फोटो की पुष्टि करें';

  @override
  String get analysisFailed => 'विश्लेषण विफल रहा';

  @override
  String get retryAnalysis => 'विश्लेषण पुनः प्रयास करें';

  @override
  String get cameraPermissionRequired => 'कैमरा अनुमति आवश्यक है';

  @override
  String get openSystemCamera => 'सिस्टम कैमरा खोलें';

  @override
  String get organicTreatment => 'जैविक उपचार';

  @override
  String get chemicalTreatment => 'रासायनिक उपचार';

  @override
  String get treatmentSteps => 'उपचार के चरण';

  @override
  String get estimatedCost => 'अनुमानित लागत';

  @override
  String get consultKvk => 'निकटतम KVK से परामर्श करें';

  @override
  String get noKvkFound => 'कोई KVK विशेषज्ञ विवरण नहीं मिला';

  @override
  String get scanAgainBtn => 'पुनः स्कैन करें';

  @override
  String get goHome => 'होम पर जाएं';

  @override
  String get totalEstimatedCost => 'कुल अनुमानित लागत';

  @override
  String get totalEstimate => 'कुल अनुमान';

  @override
  String get callKvkExpert => 'KVK विशेषज्ञ को कॉल करें';

  @override
  String get viewDetailsApply => 'विवरण देखें और आवेदन करें';

  @override
  String get directBenefit => 'प्रत्यक्ष लाभ अंतरण (DBT) पात्र';

  @override
  String get cropInsurance => 'फसल बीमा';

  @override
  String get acres => 'एकड़';

  @override
  String get stage => 'चरण:';

  @override
  String get fitLeafInGuide => 'पत्ती को वर्गाकार गाइड के अंदर फिट करें';

  @override
  String get allowCameraAccess =>
      'इस सुविधा का उपयोग करने के लिए सेटिंग्स में कैमरा एक्सेस की अनुमति दें।';

  @override
  String get cameraUnavailable => 'कैमरा अनुपलब्ध है';

  @override
  String get initializingCamera => 'कैमरा शुरू किया जा रहा है...';

  @override
  String get highRisk => 'उच्च जोखिम';

  @override
  String get medium => 'मध्यम';

  @override
  String get lowRisk => 'कम जोखिम';

  @override
  String get climateLegend => 'जलवायु सूचना';

  @override
  String get clear => 'साफ़';

  @override
  String get partlyCloudy => 'आंशिक बादल';

  @override
  String get overcast => 'घटाटोप';

  @override
  String get clouds => 'बादल';

  @override
  String get temperature => 'तापमान';

  @override
  String get precipitation => 'वर्षा';

  @override
  String get wind => 'हवा';

  @override
  String get soilHealthScore => 'मिट्टी स्वास्थ्य स्कोर';

  @override
  String get moderate => 'मध्यम';

  @override
  String get nitrogenN => 'नाइट्रोजन (N)';

  @override
  String get phosphorusP => 'फॉस्फोरस (P)';

  @override
  String get potassiumK => 'पोटेशियम (K)';

  @override
  String get optimal => 'उत्तम';

  @override
  String get good => 'अच्छा';

  @override
  String get low => 'कम';

  @override
  String get growthStage => 'विकास चरण';

  @override
  String cases(int count) {
    return '$count मामले';
  }

  @override
  String get cropGrapes => 'अंगूर';

  @override
  String get cropCorn => 'मक्का';

  @override
  String get cropSugarcane => 'गन्ना';

  @override
  String get cropPepperBell => 'शिमला मिर्च';

  @override
  String get scatteredClouds => 'बिखरे बादल';

  @override
  String get humid => 'नम';
}
