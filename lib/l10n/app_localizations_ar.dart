// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTagline => 'تدريب مُتزامن';

  @override
  String get landingSubtitle =>
      'متابعة يومية بين المدربين وعملائهم — صُمِّمت لتحقيق نتائج حقيقية.';

  @override
  String get iAmA => 'أنا';

  @override
  String get roleCoach => 'مدرب';

  @override
  String get roleClient => 'عميل';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get logIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get remove => 'إزالة';

  @override
  String get edit => 'تعديل';

  @override
  String get add => 'إضافة';

  @override
  String get done => 'تم';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get next => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get close => 'إغلاق';

  @override
  String get confirm => 'تأكيد';

  @override
  String get search => 'بحث';

  @override
  String get navToday => 'اليوم';

  @override
  String get navWorkouts => 'التمارين';

  @override
  String get navProgress => 'التقدّم';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get navClients => 'العملاء';

  @override
  String get navLibrary => 'المكتبة';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get sectionPreferences => 'التفضيلات';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageSubtitle => 'اختر لغة التطبيق';

  @override
  String get languageSystemDefault => 'إعداد النظام الافتراضي';

  @override
  String get chooseLanguage => 'اختر اللغة';

  @override
  String get welcomeBackTitle => 'مرحبًا بعودتك';

  @override
  String get welcomeBackToast => 'مرحبًا بعودتك!';

  @override
  String get loginSubtitle => 'سجّل الدخول لمواصلة رحلتك.';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get emailHint => 'أدخل بريدك الإلكتروني';

  @override
  String get passwordHint => 'أدخل كلمة المرور';

  @override
  String get orContinueWith => 'أو تابع باستخدام';

  @override
  String get continueWithApple => 'المتابعة عبر Apple';

  @override
  String get continueWithGoogle => 'المتابعة عبر Google';

  @override
  String get forgotPasswordEnterEmail =>
      'أدخل بريدك الإلكتروني أعلاه، ثم اضغط على نسيت كلمة المرور.';

  @override
  String resetLinkSent(String email) {
    return 'تم إرسال رابط إعادة التعيين إلى $email';
  }

  @override
  String get inviteLinkRequired => 'رابط الدعوة مطلوب';

  @override
  String get accountCreated => 'تم إنشاء الحساب بنجاح';

  @override
  String get couldNotCreateAccount => 'تعذّر إنشاء الحساب';

  @override
  String get joinValence => 'انضم إلى Valence';

  @override
  String signupSubtitle(String role) {
    return 'أنشئ حسابك كـ$role.';
  }

  @override
  String get inviteCodeRequired => 'رمز الدعوة مطلوب';

  @override
  String get inviteCode => 'رمز الدعوة';

  @override
  String get inviteCodeHint => 'أدخل رمز مدرّبك';

  @override
  String get fullNameRequired => 'الاسم الكامل مطلوب';

  @override
  String get fullNameHint => 'أدخل اسمك الكامل';

  @override
  String get emailInvalid => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String get passwordTooShort =>
      'يجب أن تتكوّن كلمة المرور من 6 أحرف على الأقل';

  @override
  String get passwordCreateHint => 'أنشئ كلمة مرور آمنة';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String get linkCoachTitle => 'أدخل رمز دعوة المدرب';

  @override
  String get linkCoachSubtitle => 'يجب ربط مدرب قبل استخدام التطبيق.';

  @override
  String get skip => 'تخطّي';

  @override
  String get obClientLogTitle => 'سجّل خلال ثوانٍ';

  @override
  String get obClientLogBody =>
      'صوّر وجبة، أكمل عادة، سجّل مجموعة. ذكاء Valence يحسب السعرات نيابةً عنك.';

  @override
  String get obClientHabitsTitle => 'ابنِ عاداتك اليومية';

  @override
  String get obClientHabitsBody =>
      'الماء والنوم والوزن والعادات التي يحدّدها مدرّبك — كلها في قائمة يومية واحدة هادئة.';

  @override
  String get obClientCoachTitle => 'مدرّبك إلى جانبك';

  @override
  String get obClientCoachBody =>
      'يرى تقدّمك ويحفّزك في الوقت المناسب. لن تفعل هذا وحدك أبدًا.';

  @override
  String get obClientFinish => 'أنشئ حسابك';

  @override
  String get obCoachRosterTitle => 'اعرف من يحتاجك';

  @override
  String get obCoachRosterBody =>
      'كل عملائك في لمحة — من ملتزم ومن يتراجع، يُحدَّث فور تسجيل العميل.';

  @override
  String get obCoachProgramTitle => 'برمِج مرة، وتابِع يوميًا';

  @override
  String get obCoachProgramBody =>
      'أنشئ التمارين والعادات، عيّنها، وشاهد الإنجاز يتدفّق — لا مزيد من واتساب وجداول البيانات.';

  @override
  String get obCoachGrowTitle => 'انمُ دون عناء';

  @override
  String get obCoachGrowBody =>
      'حافظ على اللمسة الشخصية من 5 عملاء إلى 50. Valence يتولّى المتابعة لتركّز على التدريب.';

  @override
  String get obCoachFinish => 'أنشئ حساب مدرب';

  @override
  String get intakeSaveError => 'تعذّر حفظ خطتك. يرجى المحاولة مرة أخرى.';

  @override
  String get intakeGoalTitle => 'ما هدفك؟';

  @override
  String get intakeGoalSubtitle => 'سنُخصّص سعراتك اليومية لتناسبه.';

  @override
  String get goalLoseTitle => 'إنقاص الوزن';

  @override
  String get goalLoseSubtitle => 'خسارة دهون تدريجية';

  @override
  String get goalMaintainTitle => 'المحافظة';

  @override
  String get goalMaintainSubtitle => 'ابقَ على وضعك الحالي';

  @override
  String get goalGainTitle => 'بناء العضلات';

  @override
  String get goalGainSubtitle => 'زيادة صافية';

  @override
  String get intakeSexTitle => 'ما الذي يصفك أكثر؟';

  @override
  String get intakeSexSubtitle => 'الجنس البيولوجي يغيّر حساب السعرات.';

  @override
  String get sexMale => 'ذكر';

  @override
  String get sexFemale => 'أنثى';

  @override
  String get intakeAgeTitle => 'كم عمرك؟';

  @override
  String get intakeAgeSubtitle => 'يؤثّر في الأيض واحتياجك من السعرات.';

  @override
  String get unitYears => 'سنة';

  @override
  String get intakeHeightTitle => 'كم طولك؟';

  @override
  String get intakeHeightSubtitle => 'تُستخدم لتقدير طاقتك اليومية.';

  @override
  String get unitCm => 'سم';

  @override
  String get intakeWeightTitle => 'وزنك الحالي؟';

  @override
  String get intakeWeightSubtitle => 'مجرد نقطة بداية — نتابع من هنا.';

  @override
  String get unitKg => 'كجم';

  @override
  String get intakeTargetTitle => 'وزنك المستهدف؟';

  @override
  String get intakeTargetSubtitle => 'حدّد الوجهة — وسنخطّط الطريق.';

  @override
  String get intakeActivityTitle => 'ما مدى نشاطك؟';

  @override
  String get intakeActivitySubtitle =>
      'خارج التمارين المخطّطة، في يومك العادي.';

  @override
  String get intakeAnalyzing1 => 'تحليل الأيض لديك';

  @override
  String get intakeAnalyzing2 => 'حساب سعراتك';

  @override
  String get intakeAnalyzing3 => 'موازنة الماكروز';

  @override
  String get intakeAnalyzing4 => 'إنهاء خطتك';

  @override
  String get intakeBuildingPlan => 'نُجهّز خطتك';

  @override
  String get intakePlanReady => 'خطتك جاهزة';

  @override
  String intakePlanReadyNamed(String name) {
    return '$name، خطتك جاهزة';
  }

  @override
  String get intakePlanSubtitle =>
      'محسوبة تلقائيًا من إجاباتك — يمكن لمدرّبك تعديلها في أي وقت.';

  @override
  String get dailyCalories => 'السعرات اليومية';

  @override
  String get kcal => 'سعرة';

  @override
  String get macroProtein => 'بروتين';

  @override
  String get macroCarbs => 'كربوهيدرات';

  @override
  String get macroFat => 'دهون';

  @override
  String get startTracking => 'ابدأ التتبّع';

  @override
  String get deltaMaintain => 'حافظ على وزنك';

  @override
  String weightToLose(String kg) {
    return '$kg كجم للخسارة';
  }

  @override
  String weightToGain(String kg) {
    return '$kg كجم للزيادة';
  }

  @override
  String get activitySedentary => 'خامل';

  @override
  String get activitySedentaryHint => 'عمل مكتبي، تمرين قليل';

  @override
  String get activityLight => 'نشاط خفيف';

  @override
  String get activityLightHint => 'تمرين خفيف 1–3 أيام/أسبوع';

  @override
  String get activityModerate => 'نشاط معتدل';

  @override
  String get activityModerateHint => 'تمرين 3–5 أيام/أسبوع';

  @override
  String get activityActive => 'نشيط جدًا';

  @override
  String get activityActiveHint => 'تمرين شاق 6–7 أيام/أسبوع';

  @override
  String get activityVeryActive => 'رياضي محترف';

  @override
  String get activityVeryActiveHint => 'تدريب مرتين يوميًا';

  @override
  String get specWeightLoss => 'إنقاص الوزن';

  @override
  String get specMuscleGain => 'بناء العضلات';

  @override
  String get specStrength => 'القوة';

  @override
  String get specNutrition => 'التغذية';

  @override
  String get specRecomp => 'إعادة تكوين الجسم';

  @override
  String get specGeneralFitness => 'اللياقة العامة';

  @override
  String get specEndurance => 'التحمّل';

  @override
  String get specMobility => 'الحركة وإعادة التأهيل';

  @override
  String get expJustStarting => 'في البداية';

  @override
  String get expJustStartingHint => 'جديد في التدريب';

  @override
  String get expOneToThree => '1–3 سنوات';

  @override
  String get expOneToThreeHint => 'أبني قاعدة عملائي';

  @override
  String get expThreeToFive => '3–5 سنوات';

  @override
  String get expThreeToFiveHint => 'مدرّب راسخ';

  @override
  String get expFivePlus => 'أكثر من 5 سنوات';

  @override
  String get expFivePlusHint => 'محترف متمرّس';

  @override
  String get rosterSolo => 'أنا فقط، لا عملاء بعد';

  @override
  String get rosterSmall => '1–10 عملاء';

  @override
  String get rosterGrowing => '11–25 عميلًا';

  @override
  String get rosterEstablished => 'أكثر من 25 عميلًا';

  @override
  String get priorWhatsapp => 'واتساب والمحادثات';

  @override
  String get priorSpreadsheets => 'جداول البيانات';

  @override
  String get priorOtherApp => 'تطبيق تدريب آخر';

  @override
  String get priorPenPaper => 'قلم وورق';

  @override
  String get priorMix => 'خليط من كل شيء';

  @override
  String get coachIntakeSaveError => 'تعذّر حفظ ملفك. يرجى المحاولة مرة أخرى.';

  @override
  String get ciSpecialtiesTitle => 'ما تخصصك؟';

  @override
  String get ciSpecialtiesSubtitle => 'اختر كل ما ينطبق — يحدّد ملف تدريبك.';

  @override
  String get ciExperienceTitle => 'منذ متى وأنت تدرّب؟';

  @override
  String get ciExperienceSubtitle => 'حتى نخصّص التجربة لك.';

  @override
  String get ciRosterTitle => 'كم عميلًا لديك اليوم؟';

  @override
  String get ciRosterSubtitle => 'تقريبًا — فقط لفهم حجم عملك.';

  @override
  String get ciPriorTitle => 'كيف تدير عملك حاليًا؟';

  @override
  String get ciPriorSubtitle => 'سنساعدك على استبدال الفوضى.';

  @override
  String get ciAnalyzing1 => 'إعداد استوديو التدريب';

  @override
  String get ciAnalyzing2 => 'تجهيز لوحة التحكم';

  @override
  String get ciAnalyzing3 => 'تخصيص حسب مجالاتك';

  @override
  String get ciAnalyzing4 => 'أوشكنا على الانتهاء';

  @override
  String get ciSettingUp => 'نُجهّز حسابك';

  @override
  String get ciAllSet => 'كل شيء جاهز';

  @override
  String ciWelcomeName(String name) {
    return 'مرحبًا، $name';
  }

  @override
  String get ciStudioReady => 'استوديو التدريب جاهز. ادعُ أول عميل للبدء.';

  @override
  String get ciYourFocus => 'تركيزك';

  @override
  String get enterValence => 'ادخل إلى Valence';

  @override
  String get settingsDisplayName => 'الاسم المعروض';

  @override
  String get settingsEnterName => 'أدخل اسمك';

  @override
  String get profileUpdated => 'تم تحديث الملف';

  @override
  String get profileUpdateError => 'تعذّر تحديث الملف الآن';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات';

  @override
  String get settingsSaveError => 'تعذّر حفظ الإعدادات';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String changePasswordMsg(String email) {
    return 'سنرسل رابط إعادة تعيين آمن إلى $email. افتحه لتعيين كلمة مرور جديدة.';
  }

  @override
  String get sendLink => 'إرسال الرابط';

  @override
  String get helpSupport => 'المساعدة والدعم';

  @override
  String supportBody(String role) {
    return 'للحصول على دعم الحساب أو التطبيق، تواصل عبر support@valence.app.\n\nاذكر دورك ($role) وملخصًا موجزًا للمشكلة.';
  }

  @override
  String get copyEmail => 'نسخ البريد';

  @override
  String get supportEmailCopied => 'تم نسخ بريد الدعم';

  @override
  String get aboutValence => 'حول Valence';

  @override
  String aboutVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get aboutTaglineClient =>
      'تابع وجباتك وتمارينك وعاداتك — وابقَ ملتزمًا مع مدرّبك كل يوم.';

  @override
  String get myCoach => 'مدرّبي';

  @override
  String get coachLinkedLabel => 'مرتبط بحسابك';

  @override
  String get coachNotLinked => 'غير مرتبط بعد';

  @override
  String get connect => 'ربط';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get darkModeSubtitle => 'غيّر مظهر التطبيق';

  @override
  String get mealReminders => 'تذكيرات الوجبات';

  @override
  String get mealRemindersSubtitle => 'ذكّرني بتسجيل وجباتي';

  @override
  String get metricUnits => 'وحدات مترية (كجم)';

  @override
  String get metricUnitsSubtitle => 'عرض الوزن بالكيلوجرام أو الباوند';

  @override
  String get logoutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get logoutConfirmMsg => 'ستحتاج إلى تسجيل الدخول مجددًا للمتابعة.';

  @override
  String get sectionAccount => 'الحساب';

  @override
  String get sectionSupport => 'الدعم';

  @override
  String get badgeMember => 'عضو';

  @override
  String get badgeCoach => 'مدرب';

  @override
  String get inviteAClient => 'دعوة عميل';

  @override
  String get coachSupportTitle => 'دعم المدربين';

  @override
  String get coachSupportBody =>
      'للفوترة أو إدارة العملاء أو الدعم الفني:\nsupport@valence.app';

  @override
  String get aboutTaglineCoach =>
      'منصّة المتابعة التي تُبقي المدربين وعملاءهم متناغمين — كل يوم.';

  @override
  String get planLabel => 'الباقة';

  @override
  String get planFree => 'مجاني';

  @override
  String get planPro => 'احترافي';

  @override
  String get planStudio => 'استوديو';

  @override
  String clientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عميل',
      many: '$count عميلًا',
      few: '$count عملاء',
      two: 'عميلان',
      one: 'عميل واحد',
      zero: 'بدون عملاء',
    );
    return '$_temp0';
  }

  @override
  String get clientActivityAlerts => 'تنبيهات نشاط العملاء';

  @override
  String get clientActivityAlertsSubtitle => 'تلقَّ إشعارًا عند تسجيل العميل';

  @override
  String get inviteGenerateError => 'تعذّر إنشاء رمز الدعوة';

  @override
  String get inviteCodeCopied => 'تم نسخ رمز الدعوة';

  @override
  String get inviteLinkCopied => 'تم نسخ رابط الدعوة';

  @override
  String get inviteSheetSubtitle => 'أضف شخصًا إلى قائمتك';

  @override
  String get inviteSheetBody =>
      'أنشئ رمزًا للاستخدام مرة واحدة (صالح 7 أيام) وشاركه. يُدخله عميلك عند التسجيل — رمز واحد لكل عميل، دون إفراط في المشاركة.';

  @override
  String get inviteNoCode => 'لا يوجد رمز بعد — أنشئ واحدًا أدناه';

  @override
  String get generating => 'جارٍ الإنشاء…';

  @override
  String get generateCode => 'إنشاء رمز';

  @override
  String get newCode => 'رمز جديد';

  @override
  String get copyCode => 'نسخ الرمز';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get workoutComplete => 'مكتمل';

  @override
  String get todaysWorkout => 'تمرين اليوم';

  @override
  String get pctDone => '% مكتمل';

  @override
  String workoutExercisesSets(int exercises, int done, int total) {
    return '$exercises تمارين · $done من $total مجموعات';
  }

  @override
  String get markComplete => 'إنهاء التمرين';

  @override
  String get markNotDone => 'إلغاء الإكمال';

  @override
  String get pastWorkoutViewOnly => 'تمرين سابق — للعرض فقط';

  @override
  String exerciseSetsTarget(int done, int sets, int reps) {
    return '$done/$sets مجموعات · الهدف $reps تكرار';
  }

  @override
  String get completeAllSets => 'إكمال كل المجموعات';

  @override
  String get resetExercise => 'إعادة تعيين التمرين';

  @override
  String setNumberLabel(int n) {
    return 'المجموعة $n';
  }

  @override
  String get logged => 'مُسجّل';

  @override
  String get tapToLog => 'اضغط للتسجيل';

  @override
  String get repsLabel => 'تكرار';

  @override
  String get enterValidWeight => 'أدخل وزنًا صالحًا';

  @override
  String get restDay => 'يوم راحة';

  @override
  String get restDayTodayBody =>
      'لا يوجد تمرين مخطّط لليوم. استمتع بالتعافي — أو تحقّق من يوم آخر.';

  @override
  String get restDayPastBody => 'لم يُسنَد أي تمرين لهذا اليوم.';

  @override
  String get logWeightTitle => 'تسجيل الوزن';

  @override
  String get enterWeightHint => 'أدخل وزنك';

  @override
  String get noteSentToCoach => 'تم إرسال الملاحظة إلى المدرب';

  @override
  String get noLogForDay => 'لا يوجد سجل لهذا اليوم بعد';

  @override
  String get noteSaveFailed => 'تعذّر حفظ الملاحظة';

  @override
  String get editMeal => 'تعديل الوجبة';

  @override
  String get mealName => 'اسم الوجبة';

  @override
  String get caloriesLabel => 'السعرات';

  @override
  String get proteinG => 'البروتين (جم)';

  @override
  String get carbsG => 'الكربوهيدرات (جم)';

  @override
  String get fatG => 'الدهون (جم)';

  @override
  String get invalidMacros => 'يرجى إدخال قيم ماكروز صالحة';

  @override
  String get mealUpdated => 'تم تحديث الوجبة';

  @override
  String get deleteMealTitle => 'حذف الوجبة؟';

  @override
  String deleteMealMsg(String meal) {
    return 'إزالة “$meal” من سجل اليوم؟';
  }

  @override
  String get mealDeleted => 'تم حذف الوجبة';

  @override
  String get noteOnlyToday => 'يمكنك ترك ملاحظة لليوم فقط';

  @override
  String get hi => 'مرحبًا،';

  @override
  String get noteButton => 'ملاحظة';

  @override
  String get todaysCheckIn => 'متابعة اليوم';

  @override
  String get noteToCoach => 'ملاحظة للمدرب';

  @override
  String get noteToCoachBody =>
      'أخبر مدرّبك كيف كان يومك — الطاقة، الألم، الرغبة في الطعام، أي شيء. سيراها مع سجلك.';

  @override
  String get noteToCoachHint =>
      'مثال: «شعرت بقوة اليوم، نمت 8 ساعات، طاقة منخفضة بعد الغداء…»';

  @override
  String get sendToCoach => 'إرسال إلى المدرب';

  @override
  String get viewingPastDay => 'عرض يوم سابق — للقراءة فقط';

  @override
  String get dailyWinCopied => 'تم نسخ إنجاز اليوم للمشاركة';

  @override
  String get shareDailyWin => 'شارك إنجاز اليوم';

  @override
  String get dailyHabits => 'العادات اليومية';

  @override
  String get yourHabits => 'عاداتك';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get waterLabel => 'الماء';

  @override
  String get weightLabel => 'الوزن';

  @override
  String get sleepQuality => 'جودة النوم';

  @override
  String get howRested => 'ما مدى شعورك بالراحة اليوم؟';

  @override
  String get todaysMeals => 'وجبات اليوم';

  @override
  String get logMeal => 'سجّل وجبة';

  @override
  String get logNow => 'سجّل الآن';

  @override
  String get confHigh => 'عالية';

  @override
  String get confMedium => 'متوسطة';

  @override
  String get confLow => 'منخفضة';

  @override
  String get confManual => 'يدوي';

  @override
  String get deleteMeal => 'حذف الوجبة';

  @override
  String get aiCameraError => 'تعذّر الوصول إلى الكاميرا أو المعرض.';

  @override
  String get describeMealFirst => 'صِف وجبتك أولًا.';

  @override
  String get noResultFromAI => 'لا توجد نتيجة من الذكاء الاصطناعي.';

  @override
  String get fillMealAndMacros => 'يرجى إدخال اسم الوجبة وكل الماكروز.';

  @override
  String mealPhotoUploadFailed(String error) {
    return 'فشل رفع صورة الوجبة: $error';
  }

  @override
  String get failedToSaveMeal => 'تعذّر حفظ الوجبة.';

  @override
  String get readByValenceAI => 'قراءة بواسطة Valence AI';

  @override
  String get manualEntry => 'إدخال يدوي';

  @override
  String get yourMeal => 'وجبتك';

  @override
  String get newMeal => 'وجبة جديدة';

  @override
  String get whatTheAiSaw => 'ما رآه الذكاء الاصطناعي';

  @override
  String get adjust => 'تعديل';

  @override
  String get startOver => 'البدء من جديد';

  @override
  String get logAMeal => 'تسجيل وجبة';

  @override
  String get snapItLogged => 'صوّرها. سُجِّلت.';

  @override
  String get aiReadsPlate => 'يقرأ Valence AI طبقك في ثوانٍ.';

  @override
  String get scanAMeal => 'صوّر وجبتك';

  @override
  String get tapToOpenCamera => 'اضغط لفتح الكاميرا';

  @override
  String get chooseFromGallery => 'اختر من المعرض';

  @override
  String get describeMealHint =>
      'مثال: «بيضتان، خبز محمّص بالزبدة، عصير برتقال»';

  @override
  String get describeYourMeal => 'صِف وجبتك';

  @override
  String get analyzeWithAI => 'تحليل بالذكاء الاصطناعي';

  @override
  String get enterMacrosManually => 'إدخال الماكروز يدويًا';

  @override
  String get orDivider => 'أو';

  @override
  String get readingYourPlate => 'جارٍ قراءة طبقك…';

  @override
  String get aiStatus1 => 'تحديد طعامك';

  @override
  String get aiStatus2 => 'تقدير الحصص';

  @override
  String get aiStatus3 => 'حساب الماكروز';

  @override
  String get aiStatus4 => 'اقتربنا';

  @override
  String get scoreLabel => 'النتيجة';

  @override
  String get mealBreakfast => 'فطور';

  @override
  String get mealLunch => 'غداء';

  @override
  String get mealSnack => 'وجبة خفيفة';

  @override
  String get mealDinner => 'عشاء';

  @override
  String get noProgressData => 'لا توجد بيانات تقدّم بعد.';

  @override
  String chartCaloriesSubtitle(String avg, String target) {
    return 'المتوسط $avg سعرة • الهدف $target';
  }

  @override
  String get weightTrendHint => 'أضف وزنًا يوميًا لرؤية الاتجاه';

  @override
  String get habitsScore => 'نقاط العادات';

  @override
  String chartHabitsSubtitle(String water, String sleep) {
    return 'متوسط الماء $water لتر • متوسط النوم $sleep/5';
  }

  @override
  String get notEnoughData => 'بيانات غير كافية';

  @override
  String get chartWeekly => 'أسبوعي';

  @override
  String get chartMonthly => 'شهري';

  @override
  String get chartYearly => 'سنوي';

  @override
  String get progressLoadError => 'تعذّر تحميل التقدّم الآن.';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingAfternoon => 'مساء الخير';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String get statusGood => 'جيد';

  @override
  String get statusWatch => 'مراقبة';

  @override
  String get statusAlert => 'خطر';

  @override
  String get statusSetup => 'إعداد';

  @override
  String get removeClientTitle => 'إزالة العميل؟';

  @override
  String removeClientMsg(String name) {
    return 'يؤدي هذا إلى إزالة $name من قائمتك وحذف بياناته وجدولة إزالة حسابه.';
  }

  @override
  String clientRemoved(String name) {
    return 'تمت إزالة $name؛ تمت جدولة إزالة الحساب';
  }

  @override
  String get removeClientError => 'تعذّر إزالة العميل الآن';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get configurePlan => 'إعداد الخطة';

  @override
  String get editMacros => 'تعديل الماكروز';

  @override
  String get removeClient => 'إزالة العميل';

  @override
  String get loadClientsError => 'تعذّر تحميل العملاء';

  @override
  String get checkConnection => 'تحقّق من اتصالك وحاول مجددًا.';

  @override
  String get coachWord => 'المدرب';

  @override
  String get sortedByRisk => 'مرتّب حسب الخطورة';

  @override
  String get noClientsYet => 'لا يوجد عملاء بعد';

  @override
  String get noClientsBody =>
      'شارك رمز دعوة من علامة تبويب الملف الشخصي لإضافة أول عميل.';

  @override
  String noClientsMatch(String query) {
    return 'لا يوجد عملاء يطابقون “$query”.';
  }

  @override
  String get noClientsInGroup => 'لا أحد في هذه المجموعة حاليًا.';

  @override
  String get rosterHealth => 'صحة القائمة';

  @override
  String get allOnTrack => 'الجميع على المسار';

  @override
  String needsYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عميل يحتاجك',
      many: '$count عميلًا يحتاجونك',
      few: '$count عملاء يحتاجونك',
      two: 'عميلان يحتاجانك',
      one: 'عميل واحد يحتاجك',
    );
    return '$_temp0';
  }

  @override
  String get searchClients => 'ابحث عن العملاء';

  @override
  String get filterAll => 'الكل';

  @override
  String get last7Days => 'آخر 7 أيام';

  @override
  String get metricFood => 'الطعام';

  @override
  String get metricHabits => 'العادات';

  @override
  String get metricTraining => 'التدريب';

  @override
  String get awaitingLogs => 'بانتظار سجلات حديثة';

  @override
  String get setupMacrosPlan => 'أعدّ الماكروز والخطة للتفعيل';

  @override
  String get noLogsYet => 'لا سجلات بعد';

  @override
  String lastLogOn(String date) {
    return 'آخر سجل · $date';
  }

  @override
  String get loggedToday => 'سُجّل اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String daysAgo(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'منذ $days يوم',
      many: 'منذ $days يومًا',
      few: 'منذ $days أيام',
      two: 'منذ يومين',
      one: 'منذ يوم',
    );
    return '$_temp0';
  }

  @override
  String get deleteTemplateTitle => 'حذف القالب؟';

  @override
  String deleteTemplateMsg(String name) {
    return 'يؤدي هذا إلى حذف “$name” نهائيًا من مكتبتك. التمارين المُسندة بالفعل للعملاء تبقى كما هي.';
  }

  @override
  String get templateDeleted => 'تم حذف القالب';

  @override
  String get deleteTemplateError => 'تعذّر حذف القالب. حاول مجددًا.';

  @override
  String get noClientsToAssign => 'لا يوجد عملاء للإسناد بعد';

  @override
  String assignedDays(int count, String name) {
    return 'تم إسناد $count أيام إلى $name';
  }

  @override
  String assignedToName(String name) {
    return 'تم الإسناد إلى $name';
  }

  @override
  String get assignError => 'تعذّر الإسناد الآن. حاول مجددًا.';

  @override
  String noTemplatesMatch(String query) {
    return 'لا توجد قوالب تطابق “$query”.';
  }

  @override
  String get yourLibrary => 'مكتبتك';

  @override
  String get workoutPlansTitle => 'خطط التمارين';

  @override
  String get workoutPlanLabel => 'خطة تمرين';

  @override
  String get statExercises => 'تمارين';

  @override
  String get statSets => 'مجموعات';

  @override
  String get statReps => 'تكرارات';

  @override
  String get editTemplate => 'تعديل القالب';

  @override
  String get deleteTemplate => 'حذف القالب';

  @override
  String get assign => 'إسناد';

  @override
  String get newTemplate => 'قالب جديد';

  @override
  String get buildFirstPlan => 'أنشئ خطتك الأولى';

  @override
  String get buildFirstPlanBody =>
      'أنشئ تمرينًا قابلًا لإعادة الاستخدام مرة واحدة، ثم أسنده لأي عميل في ثوانٍ.';

  @override
  String get createTemplate => 'إنشاء قالب';

  @override
  String get searchTemplates => 'ابحث في القوالب';

  @override
  String get enterValidWeightBlank => 'أدخل وزنًا صالحًا أو اتركه فارغًا';

  @override
  String get giveTemplateName => 'امنح قالبك اسمًا';

  @override
  String get addAtLeastOneExercise => 'أضف تمرينًا واحدًا على الأقل';

  @override
  String get templateUpdated => 'تم تحديث القالب';

  @override
  String get templateCreated => 'تم إنشاء القالب';

  @override
  String get couldNotSaveNow => 'تعذّر الحفظ الآن';

  @override
  String get templateNameLabel => 'اسم القالب';

  @override
  String get templateNameHint => 'مثال: الجزء العلوي · دفع';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get newLabel => 'جديد';

  @override
  String get workoutTemplateTitle => 'قالب التمرين';

  @override
  String get exerciseNameHint => 'اسم التمرين';

  @override
  String get targetWeightOptional => 'الوزن المستهدف (كغ) · اختياري';

  @override
  String get addExercise => 'إضافة تمرين';

  @override
  String get assignWorkout => 'إسناد تمرين';

  @override
  String get whenLabel => 'متى';

  @override
  String get todayLabel => 'اليوم';

  @override
  String get tomorrowLabel => 'غدًا';

  @override
  String get pickLabel => 'اختر…';

  @override
  String get repeatLabel => 'تكرار';

  @override
  String get justOnce => 'مرة واحدة';

  @override
  String get weeklyLabel => 'أسبوعيًا';

  @override
  String assignNWorkouts(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إسناد $count تمرين',
      many: 'إسناد $count تمرينًا',
      few: 'إسناد $count تمارين',
      two: 'إسناد تمرينين',
      one: 'إسناد تمرين واحد',
    );
    return '$_temp0';
  }

  @override
  String get assignWorkoutBtn => 'إسناد التمرين';

  @override
  String get durationLabel => 'المدة';

  @override
  String get noDaysInRange =>
      'لا أيام ضمن النطاق — أضف أسبوعًا أو اختر يومًا لاحقًا';

  @override
  String schedulesDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يجدول $count يوم تدريب',
      many: 'يجدول $count يوم تدريب',
      few: 'يجدول $count أيام تدريب',
      two: 'يجدول يومي تدريب',
      one: 'يجدول يوم تدريب واحد',
    );
    return '$_temp0';
  }

  @override
  String weekDuration(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أسبوع',
      many: '$count أسبوعًا',
      few: '$count أسابيع',
      two: 'أسبوعان',
      one: 'أسبوع واحد',
    );
    return '$_temp0';
  }

  @override
  String get sleepPoor => 'سيئ';

  @override
  String get sleepFair => 'مقبول';

  @override
  String get sleepGreat => 'ممتاز';

  @override
  String get sleepLabel => 'النوم';

  @override
  String get noteSaved => 'تم حفظ الملاحظة';

  @override
  String get macroTargets => 'أهداف الماكروز';

  @override
  String dailyGoalsName(String name) {
    return 'الأهداف اليومية · $name';
  }

  @override
  String get saveTargets => 'حفظ الأهداف';

  @override
  String get enterValidMacros => 'أدخل قيم ماكروز صالحة';

  @override
  String get macrosMustBePositive => 'يجب أن تكون كل قيم الماكروز أكبر من 0';

  @override
  String get macroTargetsUpdated => 'تم تحديث أهداف الماكروز';

  @override
  String get failedSaveMacros => 'تعذّر حفظ الماكروز';

  @override
  String get clientDetailsTitle => 'تفاصيل العميل';

  @override
  String get loadClientError => 'تعذّر تحميل هذا العميل الآن.';

  @override
  String get loadDayError => 'تعذّر تحميل بيانات هذا اليوم.';

  @override
  String get tabAnalytics => 'التحليلات';

  @override
  String get tabPlan => 'الخطة';

  @override
  String get nutritionSummary => 'ملخص التغذية';

  @override
  String get editTargets => 'تعديل الأهداف';

  @override
  String get workoutLabel => 'التمرين';

  @override
  String get swapWorkout => 'تبديل التمرين';

  @override
  String get coachNoteLabel => 'ملاحظة المدرب';

  @override
  String ofTarget(String target) {
    return 'من $target';
  }

  @override
  String get noMealsLogged => 'لا توجد وجبات مسجلة لهذا اليوم.';

  @override
  String get noWorkoutAssignedLib =>
      'لم يُسنَد تمرين لهذا اليوم.\nأسنِد واحدًا من علامة تبويب المكتبة.';

  @override
  String get inProgress => 'قيد التنفيذ';

  @override
  String pendingTarget(int reps) {
    return 'معلّق · الهدف $reps';
  }

  @override
  String get clientCheckIn => 'متابعة العميل';

  @override
  String get noCheckInNote => 'لا توجد ملاحظة من العميل لهذا اليوم.';

  @override
  String get loadAnalyticsError => 'تعذّر تحميل التحليلات.';

  @override
  String get noCoachLinked => 'هذا العميل غير مرتبط بمدرب.';

  @override
  String get noLibraryWorkouts =>
      'لا توجد تمارين في مكتبتك بعد — أنشئ واحدًا في علامة تبويب المكتبة.';

  @override
  String workoutAssignedName(String name) {
    return 'تم إسناد التمرين · $name';
  }

  @override
  String get assignWorkoutErr => 'تعذّر إسناد التمرين. حاول مجددًا.';

  @override
  String get updateWorkout => 'تحديث التمرين';

  @override
  String get workoutTitleLabel => 'عنوان التمرين';

  @override
  String exerciseNumber(int n) {
    return 'التمرين $n';
  }

  @override
  String get targetWeightLabel => 'الوزن المستهدف';

  @override
  String get saveWorkout => 'حفظ التمرين';

  @override
  String get workoutTitleRequired => 'عنوان التمرين والتمارين مطلوبة';

  @override
  String get workoutUpdated => 'تم تحديث التمرين';

  @override
  String get updateWorkoutError => 'تعذّر تحديث التمرين. حاول مجددًا.';

  @override
  String get removeWorkoutTitle => 'إزالة التمرين؟';

  @override
  String get removeWorkoutMsg =>
      'يؤدي هذا إلى مسح التمرين المُسنَد لهذا اليوم. قالب مكتبتك يبقى كما هو.';

  @override
  String get workoutRemoved => 'تمت إزالة التمرين';

  @override
  String get removeWorkoutError => 'تعذّر إزالة التمرين. حاول مجددًا.';

  @override
  String get noCustomHabitsBody =>
      'لا توجد عادات مخصصة بعد. أضف أشياء مثل الخطوات أو المكملات أو مشي يومي — تظهر في الصفحة الرئيسية للعميل، فوق الماء والنوم والوزن.';

  @override
  String get addHabits => 'إضافة عادات';

  @override
  String get manageHabits => 'إدارة العادات';

  @override
  String get habitsUpdated => 'تم تحديث العادات';

  @override
  String get saveHabitsError => 'تعذّر حفظ العادات';

  @override
  String get configureMacros => 'إعداد الماكروز';

  @override
  String get updateMacros => 'تحديث الماكروز';

  @override
  String get savingMacrosConfigures =>
      'حفظ الماكروز يضع علامة على هذا العميل كمُهيأ.';

  @override
  String workoutLogTitle(String date) {
    return 'سجل التمرين ($date)';
  }

  @override
  String get noWorkoutSelectedDay => 'لم يُسنَد تمرين لليوم المحدد.';

  @override
  String get updateBtn => 'تحديث';

  @override
  String get yourNote => 'ملاحظتك';

  @override
  String get leaveANote => 'اترك ملاحظة';

  @override
  String get savedLabel => 'تم الحفظ';

  @override
  String writeFeedbackFor(String name) {
    return 'اكتب ملاحظات لـ $name…';
  }

  @override
  String get editingPastDay => 'تحرير يوم سابق';

  @override
  String get updateNote => 'تحديث الملاحظة';

  @override
  String get saveNote => 'حفظ الملاحظة';

  @override
  String get relToday => 'اليوم';

  @override
  String get relTomorrow => 'غدًا';

  @override
  String get relYesterday => 'أمس';

  @override
  String forClientDate(String name, String date) {
    return 'لـ $name · $date';
  }

  @override
  String get chooseAWorkout => 'اختر تمرينًا';

  @override
  String get includesLabel => 'يشمل';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تمرين',
      many: '$count تمرينًا',
      few: '$count تمارين',
      two: 'تمرينان',
      one: 'تمرين واحد',
    );
    return '$_temp0';
  }

  @override
  String get habitsManagerBody =>
      'عادات يكملها هذا العميل كل يوم، إلى جانب الماء والنوم والوزن.';

  @override
  String get addAHabit => 'إضافة عادة';

  @override
  String get habitNameHint => 'مثال: 10 آلاف خطوة';

  @override
  String get saveHabits => 'حفظ العادات';

  @override
  String get plansTitle => 'الباقات';

  @override
  String get plansSubtitle => 'اختر الباقة التي تناسب عدد عملائك';

  @override
  String get planCurrent => 'باقتك الحالية';

  @override
  String get planMostPopular => 'الأكثر شيوعًا';

  @override
  String get planPerMonth => '/شهر';

  @override
  String planChoose(String plan) {
    return 'اختر $plan';
  }

  @override
  String planClientsUpTo(int count) {
    return 'حتى $count عميل';
  }

  @override
  String get planClientsUnlimited => 'عملاء بلا حدود';

  @override
  String planUsageLimited(int used, int total) {
    return '$used / $total عميل';
  }

  @override
  String get planFreeTagline => 'ابدأ مع عدد قليل من العملاء';

  @override
  String get planProTagline => 'للمدربين الطموحين';

  @override
  String get planStudioTagline => 'للاستوديوهات الكاملة، بلا حدود';

  @override
  String get featureMonitoring => 'متابعة يومية للعملاء';

  @override
  String get featureWorkoutLibrary => 'مكتبة التمارين والبرمجة';

  @override
  String get featureAiMeal => 'تحليل الوجبات بالذكاء الاصطناعي';

  @override
  String get featureRecurring => 'برمجة أسبوعية متكررة';

  @override
  String get featureCustomHabits => 'تتبع عادات مخصصة';

  @override
  String get featureAnalytics => 'تحليلات التقدم';

  @override
  String get featurePrioritySupport => 'دعم ذو أولوية';

  @override
  String get featureEverythingFree => 'كل ما في الباقة المجانية';

  @override
  String get featureEverythingPro => 'كل ما في باقة Pro';

  @override
  String get upgradeContactTitle => 'ترقية باقتك';

  @override
  String upgradeContactBody(String plan) {
    return 'الدفع عبر الإنترنت قادم قريبًا. تواصل معنا وسنفعّل باقة $plan لك فورًا.';
  }

  @override
  String get contactUs => 'تواصل معنا';

  @override
  String get clientLimitTitle => 'تم بلوغ الحد الأقصى للعملاء';

  @override
  String clientLimitBody(int count) {
    return 'لقد بلغت الحد الأقصى لباقتك وهو $count عميل. قم بالترقية لإضافة المزيد.';
  }

  @override
  String get viewPlans => 'عرض الباقات';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountWarning =>
      'سيؤدي هذا إلى حذف حسابك وجميع بياناتك نهائيًا. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get deleteAccountConfirmPassword => 'أدخل كلمة المرور للتأكيد';

  @override
  String get reminderTitle => 'حان وقت تسجيل يومك';

  @override
  String get reminderBody => 'سجّل وجباتك وعاداتك في Valence.';

  @override
  String get reminderTimeLabel => 'وقت التذكير';

  @override
  String get remindersPermissionDenied =>
      'فعّل الإشعارات من إعدادات جهازك لتصلك التذكيرات.';

  @override
  String get onboardHookTitle => 'كُل بشكل أفضل، كل يوم.';

  @override
  String get onboardHookSubtitle =>
      'صوّر وجبتك ويحسب Valence السعرات والماكروز — بينما يبقيك مدربك على المسار الصحيح.';

  @override
  String get onboardBenefit1Title => 'صوّرها، ونحن نتكفّل بالحساب.';

  @override
  String get onboardBenefit1Body =>
      'وجّه الكاميرا نحو أي وجبة — يقدّر Valence السعرات والماكروز في ثوانٍ. بلا قواعد بيانات، بلا تخمين.';

  @override
  String get onboardBenefit2Title => 'مدربك، إلى جانبك.';

  @override
  String get onboardBenefit2Body =>
      'يرى مدربك تقدمك ويضبط خطتك — بلا لقطات شاشة ومحادثات متفرقة.';

  @override
  String get intakePriorTitle => 'هل سبق أن تتبّعت تغذيتك؟';

  @override
  String get intakePriorSubtitle =>
      'بلا أحكام — هذا فقط يساعدنا على ضبط الوتيرة المناسبة.';

  @override
  String get priorNever => 'لم أتتبّع من قبل';

  @override
  String get priorStopped => 'جرّبت ولم أستمر';

  @override
  String get priorCurrent => 'أتتبّع بالفعل';

  @override
  String get onboardCommitTitle => 'هل أنت مستعد للالتزام؟';

  @override
  String get onboardCommitSubtitle =>
      'التسجيلات اليومية الصغيرة تتراكم. التزم لنفسك وستتكفّل خطتك بالباقي.';

  @override
  String get onboardCommitCta => 'أنا مستعد';

  @override
  String get createAccountSavePlan => 'أنشئ حسابًا لحفظ خطتي';

  @override
  String get planGoalLabel => 'هدفك';

  @override
  String planReachBy(String weight, String date) {
    return 'الوصول إلى $weight بحلول $date';
  }

  @override
  String get roleCoachDesc => 'أدر عملاءك، ابنِ الخطط، وتابع تقدّم الجميع.';

  @override
  String get roleClientDesc => 'سجّل وجباتك بالذكاء الاصطناعي واتبع خطة مدربك.';

  @override
  String get unitsMetric => 'متري';

  @override
  String get unitsImperial => 'إمبريالي';

  @override
  String get unitLb => 'lb';

  @override
  String weightToLoseU(String amount, String unit) {
    return '$amount $unit للخسارة';
  }

  @override
  String weightToGainU(String amount, String unit) {
    return '$amount $unit للزيادة';
  }

  @override
  String get intakeAgeInsight =>
      'عمرك يؤثر في عدد السعرات التي تحرقها أثناء الراحة.';

  @override
  String get intakeHeightInsight =>
      'يُستعمل طولك مع وزنك لتقدير معدل الأيض لديك.';

  @override
  String get intakeWeightInsight => 'هذه نقطة انطلاقك — سنتابع كل خطوة من هنا.';

  @override
  String get intakeTargetInsight =>
      'الوتيرة التدريجية هي أكثر الطرق استدامةً للوصول.';

  @override
  String get intakeActivityInsight =>
      'يحدّد سعراتك اليومية باستخدام معادلة Mifflin-St Jeor التي يثق بها أخصائيو التغذية.';

  @override
  String get ciSpecialtiesInsight =>
      'نُخصّص القوالب والنصائح التي نقترحها بحسب تخصّصك.';

  @override
  String get ciExperienceInsight =>
      'يضبط هذا إعدادات افتراضية مناسبة — يمكنك تغيير أي شيء لاحقًا.';

  @override
  String get ciRosterInsight =>
      'ينمو Valence معك — ابدأ مجانًا مع أول 3 عملاء.';

  @override
  String get ciPriorInsight => 'سنساعدك على جمع كل شيء في مكان واحد.';

  @override
  String get purchaseSuccess => 'تمت الترقية — استمتع!';

  @override
  String get purchaseFailed => 'تعذّرت عملية الشراء. حاول مرة أخرى.';

  @override
  String get restorePurchases => 'استعادة المشتريات';

  @override
  String get authErrInviteRequired => 'رمز الدعوة مطلوب للانضمام';

  @override
  String get authErrInviteInvalid =>
      'رمز الدعوة غير صالح أو منتهي الصلاحية أو مستخدم من قبل';

  @override
  String get authErrEmailInUse =>
      'هذا البريد الإلكتروني مسجّل بالفعل — جرّب تسجيل الدخول';

  @override
  String get authErrWeakPassword =>
      'كلمة المرور ضعيفة جدًا — استخدم 6 أحرف على الأقل';

  @override
  String get authErrInvalidEmail => 'عنوان البريد الإلكتروني غير صالح';

  @override
  String get authErrWrongCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get authErrTooManyRequests =>
      'محاولات كثيرة جدًا — انتظر قليلاً ثم حاول مجددًا';

  @override
  String get authErrNetwork => 'خطأ في الشبكة — تحقق من اتصالك وحاول مجددًا';

  @override
  String get authErrUserDataNotFound => 'تعذر العثور على بيانات حسابك';

  @override
  String get authErrNoEmailOnFile => 'لا يوجد بريد إلكتروني مسجّل';

  @override
  String get authErrNotLoggedIn => 'يجب تسجيل الدخول أولاً';

  @override
  String get authErrClientsOnly => 'حسابات العملاء فقط يمكنها الارتباط بمدرب';

  @override
  String get authErrLinkCoachFailed => 'تعذر الارتباط بمدربك — حاول مجددًا';

  @override
  String get authErrIncorrectPassword => 'كلمة المرور غير صحيحة';

  @override
  String get authErrRecentLogin =>
      'يرجى تسجيل الخروج ثم الدخول مجددًا والمحاولة من جديد';

  @override
  String get authErrResetFailed => 'تعذر إرسال بريد إعادة التعيين';

  @override
  String get authErrSignupFailed => 'تعذر إنشاء حسابك — حاول مجددًا';

  @override
  String get authErrSigninFailed => 'تعذر تسجيل دخولك — حاول مجددًا';

  @override
  String get authErrDeleteFailed => 'تعذر حذف حسابك — حاول مجددًا';

  @override
  String get authErrUnknown => 'حدث خطأ ما — يرجى المحاولة مجددًا';

  @override
  String quietForDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم بدون نشاط',
      many: '$days يومًا بدون نشاط',
      few: '$days أيام بدون نشاط',
      two: 'يومان بدون نشاط',
      one: 'يوم واحد بدون نشاط',
    );
    return '$_temp0';
  }

  @override
  String get perfectWeek => 'أسبوع مثالي';

  @override
  String dayStreak(int days) {
    return 'سلسلة $days أيام';
  }

  @override
  String get obMockClientName => 'سارة';

  @override
  String get obMockWorkoutTitle => 'تمرين الصدر';

  @override
  String get obMockSetsDone => 'اكتمل 2/3';

  @override
  String get obMockEx1 => 'ضغط البنش';

  @override
  String get obMockEx2 => 'ضغط مائل بالدمبل';

  @override
  String get obMockEx3 => 'تجميع بالكابل';

  @override
  String get obMockHabitWater => 'الماء · 3 لتر';

  @override
  String get obMockHabitSteps => '10,000 خطوة';

  @override
  String get obMockHabitSugar => 'بلا سكر بعد 8 مساءً';

  @override
  String get obMockNoteHeader => 'ملاحظة من مدرّبك';

  @override
  String get obMockNoteBody =>
      'أسبوع قوي يا سارة. بروتينك مضبوط تمامًا — أضيفي نزهة مشي في نهاية الأسبوع وستكونين في أفضل حال.';

  @override
  String get statusNew => 'جديد';

  @override
  String get joinedRecently => 'انضم حديثًا — بانتظار أول تسجيل';

  @override
  String consistencyThisWeek(int pct) {
    return 'انتظام $pct% هذا الأسبوع';
  }

  @override
  String get coverStatement1 => 'كل وجبة، مفهومة.';

  @override
  String get coverStatement2 => 'كل عملائك في لمحة.';

  @override
  String get coverRolePrompt => 'كيف ستستخدم Valence؟';

  @override
  String get welcomeTitle => 'مرحبًا بك في Valence';

  @override
  String get clientIntroTitle => 'مدرّبك في جيبك';

  @override
  String get coachIntroTitle => 'تدريبك كله في مكان واحد';

  @override
  String get introSubtitle => 'إليك كيف يعمل Valence من أجلك.';

  @override
  String get roleAthlete => 'رياضي';

  @override
  String get clientIntroCta => 'ابنِ خطتي';

  @override
  String get coachIntroCta => 'إعداد ملفي الشخصي';

  @override
  String get coachSetupReady =>
      'مساحة التدريب الخاصة بك جاهزة. ادعُ أول عميل لك للبدء.';
}
