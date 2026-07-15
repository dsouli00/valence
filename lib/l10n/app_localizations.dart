import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
  ];

  /// Subtitle on the get-started landing screen
  ///
  /// In en, this message translates to:
  /// **'Daily accountability between coaches and their clients — built for real results.'**
  String get landingSubtitle;

  /// No description provided for @roleCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get roleCoach;

  /// No description provided for @roleClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get roleClient;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get navWorkouts;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get navClients;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get sectionPreferences;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your app language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @languageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @welcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBackTitle;

  /// No description provided for @welcomeBackToast.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBackToast;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your journey.'**
  String get loginSubtitle;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @forgotPasswordEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email above, then tap Forgot Password.'**
  String get forgotPasswordEnterEmail;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to {email}'**
  String resetLinkSent(String email);

  /// No description provided for @inviteLinkRequired.
  ///
  /// In en, this message translates to:
  /// **'Invite link is required'**
  String get inviteLinkRequired;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get accountCreated;

  /// No description provided for @joinValence.
  ///
  /// In en, this message translates to:
  /// **'Join Valence'**
  String get joinValence;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your premium {role} account.'**
  String signupSubtitle(String role);

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordCreateHint.
  ///
  /// In en, this message translates to:
  /// **'Create a secure password'**
  String get passwordCreateHint;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @linkCoachTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter coach invite code'**
  String get linkCoachTitle;

  /// No description provided for @linkCoachSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You must link a coach before using the app.'**
  String get linkCoachSubtitle;

  /// No description provided for @obClientLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Log it in seconds'**
  String get obClientLogTitle;

  /// No description provided for @obClientLogBody.
  ///
  /// In en, this message translates to:
  /// **'Snap a meal, tick a habit, log a set. Valence\'s AI does the calorie maths so you don\'t have to.'**
  String get obClientLogBody;

  /// No description provided for @obClientHabitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Build the daily habits'**
  String get obClientHabitsTitle;

  /// No description provided for @obClientHabitsBody.
  ///
  /// In en, this message translates to:
  /// **'Water, sleep, weight and the habits your coach sets — all in one calm daily checklist.'**
  String get obClientHabitsBody;

  /// No description provided for @obClientCoachTitle.
  ///
  /// In en, this message translates to:
  /// **'Your coach has your back'**
  String get obClientCoachTitle;

  /// No description provided for @obClientCoachBody.
  ///
  /// In en, this message translates to:
  /// **'They see your progress and nudge you when it counts. You are never doing this alone.'**
  String get obClientCoachBody;

  /// No description provided for @obCoachRosterTitle.
  ///
  /// In en, this message translates to:
  /// **'See who needs you'**
  String get obCoachRosterTitle;

  /// No description provided for @obCoachRosterBody.
  ///
  /// In en, this message translates to:
  /// **'Your whole roster at a glance — who\'s on track and who\'s slipping, updated the moment a client logs.'**
  String get obCoachRosterBody;

  /// No description provided for @obCoachProgramTitle.
  ///
  /// In en, this message translates to:
  /// **'Program once, track daily'**
  String get obCoachProgramTitle;

  /// No description provided for @obCoachProgramBody.
  ///
  /// In en, this message translates to:
  /// **'Build workouts and habits, assign them, and watch completion roll in — no more WhatsApp and spreadsheets.'**
  String get obCoachProgramBody;

  /// No description provided for @obCoachGrowTitle.
  ///
  /// In en, this message translates to:
  /// **'Grow without the grind'**
  String get obCoachGrowTitle;

  /// No description provided for @obCoachGrowBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the personal touch from 5 clients to 50. Valence does the chasing so you can focus on coaching.'**
  String get obCoachGrowBody;

  /// No description provided for @intakeSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your plan. Please try again.'**
  String get intakeSaveError;

  /// No description provided for @intakeGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your goal?'**
  String get intakeGoalTitle;

  /// No description provided for @intakeGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll tailor your daily calories to match.'**
  String get intakeGoalSubtitle;

  /// No description provided for @goalLoseTitle.
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get goalLoseTitle;

  /// No description provided for @goalLoseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gradual fat loss'**
  String get goalLoseSubtitle;

  /// No description provided for @goalMaintainTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get goalMaintainTitle;

  /// No description provided for @goalMaintainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay where you are'**
  String get goalMaintainSubtitle;

  /// No description provided for @goalGainTitle.
  ///
  /// In en, this message translates to:
  /// **'Build muscle'**
  String get goalGainTitle;

  /// No description provided for @goalGainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lean gains'**
  String get goalGainSubtitle;

  /// No description provided for @intakeSexTitle.
  ///
  /// In en, this message translates to:
  /// **'Which best describes you?'**
  String get intakeSexTitle;

  /// No description provided for @intakeSexSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Biological sex changes the calorie maths.'**
  String get intakeSexSubtitle;

  /// No description provided for @sexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get sexMale;

  /// No description provided for @sexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get sexFemale;

  /// No description provided for @intakeAgeTitle.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get intakeAgeTitle;

  /// No description provided for @intakeAgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'It shapes your metabolism and calorie needs.'**
  String get intakeAgeSubtitle;

  /// No description provided for @unitYears.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get unitYears;

  /// No description provided for @intakeHeightTitle.
  ///
  /// In en, this message translates to:
  /// **'How tall are you?'**
  String get intakeHeightTitle;

  /// No description provided for @intakeHeightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used to estimate your daily energy.'**
  String get intakeHeightSubtitle;

  /// No description provided for @unitCm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get unitCm;

  /// No description provided for @intakeWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Your current weight?'**
  String get intakeWeightTitle;

  /// No description provided for @intakeWeightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Just our starting point — we track from here.'**
  String get intakeWeightSubtitle;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @intakeTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Your goal weight?'**
  String get intakeTargetTitle;

  /// No description provided for @intakeTargetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the destination — we\'ll plan the path.'**
  String get intakeTargetSubtitle;

  /// No description provided for @intakeActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'How active are you?'**
  String get intakeActivityTitle;

  /// No description provided for @intakeActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Outside of planned workouts, day to day.'**
  String get intakeActivitySubtitle;

  /// No description provided for @intakeAnalyzing1.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your metabolism'**
  String get intakeAnalyzing1;

  /// No description provided for @intakeAnalyzing2.
  ///
  /// In en, this message translates to:
  /// **'Calculating your calories'**
  String get intakeAnalyzing2;

  /// No description provided for @intakeAnalyzing3.
  ///
  /// In en, this message translates to:
  /// **'Balancing your macros'**
  String get intakeAnalyzing3;

  /// No description provided for @intakeAnalyzing4.
  ///
  /// In en, this message translates to:
  /// **'Finalizing your plan'**
  String get intakeAnalyzing4;

  /// No description provided for @intakePlanReady.
  ///
  /// In en, this message translates to:
  /// **'Your plan is ready'**
  String get intakePlanReady;

  /// No description provided for @intakePlanReadyNamed.
  ///
  /// In en, this message translates to:
  /// **'{name}, your plan is ready'**
  String intakePlanReadyNamed(String name);

  /// No description provided for @intakePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-calculated from your answers — your coach can fine-tune it anytime.'**
  String get intakePlanSubtitle;

  /// No description provided for @dailyCalories.
  ///
  /// In en, this message translates to:
  /// **'Daily calories'**
  String get dailyCalories;

  /// No description provided for @kcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcal;

  /// No description provided for @macroProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get macroProtein;

  /// No description provided for @macroCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get macroCarbs;

  /// No description provided for @macroFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get macroFat;

  /// No description provided for @startTracking.
  ///
  /// In en, this message translates to:
  /// **'Start tracking'**
  String get startTracking;

  /// No description provided for @deltaMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain your weight'**
  String get deltaMaintain;

  /// No description provided for @activitySedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get activitySedentary;

  /// No description provided for @activitySedentaryHint.
  ///
  /// In en, this message translates to:
  /// **'Desk job, little exercise'**
  String get activitySedentaryHint;

  /// No description provided for @activityLight.
  ///
  /// In en, this message translates to:
  /// **'Lightly active'**
  String get activityLight;

  /// No description provided for @activityLightHint.
  ///
  /// In en, this message translates to:
  /// **'Light exercise 1–3 days/wk'**
  String get activityLightHint;

  /// No description provided for @activityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderately active'**
  String get activityModerate;

  /// No description provided for @activityModerateHint.
  ///
  /// In en, this message translates to:
  /// **'Exercise 3–5 days/wk'**
  String get activityModerateHint;

  /// No description provided for @activityActive.
  ///
  /// In en, this message translates to:
  /// **'Very active'**
  String get activityActive;

  /// No description provided for @activityActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Hard exercise 6–7 days/wk'**
  String get activityActiveHint;

  /// No description provided for @activityVeryActive.
  ///
  /// In en, this message translates to:
  /// **'Athlete'**
  String get activityVeryActive;

  /// No description provided for @activityVeryActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Training twice a day'**
  String get activityVeryActiveHint;

  /// No description provided for @specWeightLoss.
  ///
  /// In en, this message translates to:
  /// **'Weight loss'**
  String get specWeightLoss;

  /// No description provided for @specMuscleGain.
  ///
  /// In en, this message translates to:
  /// **'Muscle building'**
  String get specMuscleGain;

  /// No description provided for @specStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get specStrength;

  /// No description provided for @specNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get specNutrition;

  /// No description provided for @specRecomp.
  ///
  /// In en, this message translates to:
  /// **'Body recomp'**
  String get specRecomp;

  /// No description provided for @specGeneralFitness.
  ///
  /// In en, this message translates to:
  /// **'General fitness'**
  String get specGeneralFitness;

  /// No description provided for @specEndurance.
  ///
  /// In en, this message translates to:
  /// **'Endurance'**
  String get specEndurance;

  /// No description provided for @specMobility.
  ///
  /// In en, this message translates to:
  /// **'Mobility & rehab'**
  String get specMobility;

  /// No description provided for @expJustStarting.
  ///
  /// In en, this message translates to:
  /// **'Just starting out'**
  String get expJustStarting;

  /// No description provided for @expJustStartingHint.
  ///
  /// In en, this message translates to:
  /// **'New to coaching'**
  String get expJustStartingHint;

  /// No description provided for @expOneToThree.
  ///
  /// In en, this message translates to:
  /// **'1–3 years'**
  String get expOneToThree;

  /// No description provided for @expOneToThreeHint.
  ///
  /// In en, this message translates to:
  /// **'Building my book'**
  String get expOneToThreeHint;

  /// No description provided for @expThreeToFive.
  ///
  /// In en, this message translates to:
  /// **'3–5 years'**
  String get expThreeToFive;

  /// No description provided for @expThreeToFiveHint.
  ///
  /// In en, this message translates to:
  /// **'Established coach'**
  String get expThreeToFiveHint;

  /// No description provided for @expFivePlus.
  ///
  /// In en, this message translates to:
  /// **'5+ years'**
  String get expFivePlus;

  /// No description provided for @expFivePlusHint.
  ///
  /// In en, this message translates to:
  /// **'Seasoned pro'**
  String get expFivePlusHint;

  /// No description provided for @rosterSolo.
  ///
  /// In en, this message translates to:
  /// **'Just me, no clients yet'**
  String get rosterSolo;

  /// No description provided for @rosterSmall.
  ///
  /// In en, this message translates to:
  /// **'1–10 clients'**
  String get rosterSmall;

  /// No description provided for @rosterGrowing.
  ///
  /// In en, this message translates to:
  /// **'11–25 clients'**
  String get rosterGrowing;

  /// No description provided for @rosterEstablished.
  ///
  /// In en, this message translates to:
  /// **'25+ clients'**
  String get rosterEstablished;

  /// No description provided for @priorWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp & chat'**
  String get priorWhatsapp;

  /// No description provided for @priorSpreadsheets.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheets'**
  String get priorSpreadsheets;

  /// No description provided for @priorOtherApp.
  ///
  /// In en, this message translates to:
  /// **'Another coaching app'**
  String get priorOtherApp;

  /// No description provided for @priorPenPaper.
  ///
  /// In en, this message translates to:
  /// **'Pen & paper'**
  String get priorPenPaper;

  /// No description provided for @priorMix.
  ///
  /// In en, this message translates to:
  /// **'A bit of everything'**
  String get priorMix;

  /// No description provided for @coachIntakeSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile. Please try again.'**
  String get coachIntakeSaveError;

  /// No description provided for @ciSpecialtiesTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you specialise in?'**
  String get ciSpecialtiesTitle;

  /// No description provided for @ciSpecialtiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick all that apply — it shapes your coaching profile.'**
  String get ciSpecialtiesSubtitle;

  /// No description provided for @ciExperienceTitle.
  ///
  /// In en, this message translates to:
  /// **'How long have you coached?'**
  String get ciExperienceTitle;

  /// No description provided for @ciExperienceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'So we can tailor the experience to you.'**
  String get ciExperienceSubtitle;

  /// No description provided for @ciRosterTitle.
  ///
  /// In en, this message translates to:
  /// **'How many clients today?'**
  String get ciRosterTitle;

  /// No description provided for @ciRosterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Roughly — just to understand your scale.'**
  String get ciRosterSubtitle;

  /// No description provided for @ciPriorTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you run things now?'**
  String get ciPriorTitle;

  /// No description provided for @ciPriorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll help you replace the chaos.'**
  String get ciPriorSubtitle;

  /// No description provided for @ciAnalyzing1.
  ///
  /// In en, this message translates to:
  /// **'Setting up your studio'**
  String get ciAnalyzing1;

  /// No description provided for @ciAnalyzing2.
  ///
  /// In en, this message translates to:
  /// **'Preparing your dashboard'**
  String get ciAnalyzing2;

  /// No description provided for @ciAnalyzing3.
  ///
  /// In en, this message translates to:
  /// **'Tailoring to your specialties'**
  String get ciAnalyzing3;

  /// No description provided for @ciAnalyzing4.
  ///
  /// In en, this message translates to:
  /// **'Almost ready'**
  String get ciAnalyzing4;

  /// No description provided for @ciAllSet.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set'**
  String get ciAllSet;

  /// No description provided for @ciWelcomeName.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String ciWelcomeName(String name);

  /// No description provided for @ciYourFocus.
  ///
  /// In en, this message translates to:
  /// **'Your focus'**
  String get ciYourFocus;

  /// No description provided for @enterValence.
  ///
  /// In en, this message translates to:
  /// **'Enter Valence'**
  String get enterValence;

  /// No description provided for @settingsDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get settingsDisplayName;

  /// No description provided for @settingsEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get settingsEnterName;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profileUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Could not update profile right now'**
  String get profileUpdateError;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @settingsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save settings'**
  String get settingsSaveError;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @changePasswordMsg.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email a secure reset link to {email}. Open it to set a new password.'**
  String changePasswordMsg(String email);

  /// No description provided for @sendLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get sendLink;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpSupport;

  /// No description provided for @supportBody.
  ///
  /// In en, this message translates to:
  /// **'For account or app support, contact support@valence.app.\n\nInclude your role ({role}) and a short issue summary.'**
  String supportBody(String role);

  /// No description provided for @copyEmail.
  ///
  /// In en, this message translates to:
  /// **'Copy email'**
  String get copyEmail;

  /// No description provided for @supportEmailCopied.
  ///
  /// In en, this message translates to:
  /// **'Support email copied'**
  String get supportEmailCopied;

  /// No description provided for @aboutValence.
  ///
  /// In en, this message translates to:
  /// **'About Valence'**
  String get aboutValence;

  /// App version line in the About dialog
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutTaglineClient.
  ///
  /// In en, this message translates to:
  /// **'Track your meals, workouts, and habits — and stay accountable with your coach, every day.'**
  String get aboutTaglineClient;

  /// No description provided for @myCoach.
  ///
  /// In en, this message translates to:
  /// **'My coach'**
  String get myCoach;

  /// No description provided for @coachLinkedLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked to your account'**
  String get coachLinkedLabel;

  /// No description provided for @coachNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked yet'**
  String get coachNotLinked;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch the app appearance'**
  String get darkModeSubtitle;

  /// No description provided for @mealReminders.
  ///
  /// In en, this message translates to:
  /// **'Meal reminders'**
  String get mealReminders;

  /// No description provided for @mealRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nudge me to log my meals'**
  String get mealRemindersSubtitle;

  /// No description provided for @metricUnits.
  ///
  /// In en, this message translates to:
  /// **'Metric units (kg)'**
  String get metricUnits;

  /// No description provided for @metricUnitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show weight in kilograms or pounds'**
  String get metricUnitsSubtitle;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to continue.'**
  String get logoutConfirmMsg;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get sectionAccount;

  /// No description provided for @sectionSupport.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get sectionSupport;

  /// No description provided for @badgeMember.
  ///
  /// In en, this message translates to:
  /// **'MEMBER'**
  String get badgeMember;

  /// No description provided for @badgeCoach.
  ///
  /// In en, this message translates to:
  /// **'COACH'**
  String get badgeCoach;

  /// No description provided for @inviteAClient.
  ///
  /// In en, this message translates to:
  /// **'Invite a client'**
  String get inviteAClient;

  /// No description provided for @coachSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Coach support'**
  String get coachSupportTitle;

  /// No description provided for @coachSupportBody.
  ///
  /// In en, this message translates to:
  /// **'For billing, client-management, or technical support:\nsupport@valence.app'**
  String get coachSupportBody;

  /// No description provided for @aboutTaglineCoach.
  ///
  /// In en, this message translates to:
  /// **'The accountability platform that keeps coaches and their clients in sync — every day.'**
  String get aboutTaglineCoach;

  /// No description provided for @planLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planLabel;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFree;

  /// No description provided for @planPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get planPro;

  /// No description provided for @planStudio.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get planStudio;

  /// No description provided for @clientsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 client} other{{count} clients}}'**
  String clientsCount(int count);

  /// No description provided for @clientActivityAlerts.
  ///
  /// In en, this message translates to:
  /// **'Client activity alerts'**
  String get clientActivityAlerts;

  /// No description provided for @clientActivityAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified when a client logs'**
  String get clientActivityAlertsSubtitle;

  /// No description provided for @inviteGenerateError.
  ///
  /// In en, this message translates to:
  /// **'Could not generate invite code'**
  String get inviteGenerateError;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied'**
  String get inviteCodeCopied;

  /// No description provided for @inviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied'**
  String get inviteLinkCopied;

  /// No description provided for @inviteSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add someone to your roster'**
  String get inviteSheetSubtitle;

  /// No description provided for @inviteSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Generate a single-use code (valid 7 days) and share it. Your client enters it when they sign up — one code per client, no oversharing.'**
  String get inviteSheetBody;

  /// No description provided for @inviteNoCode.
  ///
  /// In en, this message translates to:
  /// **'No code yet — generate one below'**
  String get inviteNoCode;

  /// No description provided for @generateCode.
  ///
  /// In en, this message translates to:
  /// **'Generate code'**
  String get generateCode;

  /// No description provided for @newCode.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get newCode;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @todaysWorkout.
  ///
  /// In en, this message translates to:
  /// **'Today\'s workout'**
  String get todaysWorkout;

  /// No description provided for @workoutExercisesSets.
  ///
  /// In en, this message translates to:
  /// **'{exercises} exercises · {done} of {total} sets'**
  String workoutExercisesSets(int exercises, int done, int total);

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark workout complete'**
  String get markComplete;

  /// No description provided for @markNotDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as not done'**
  String get markNotDone;

  /// No description provided for @pastWorkoutViewOnly.
  ///
  /// In en, this message translates to:
  /// **'Past workout — view only'**
  String get pastWorkoutViewOnly;

  /// No description provided for @exerciseSetsTarget.
  ///
  /// In en, this message translates to:
  /// **'{done}/{sets} sets · target {reps} reps'**
  String exerciseSetsTarget(int done, int sets, int reps);

  /// No description provided for @completeAllSets.
  ///
  /// In en, this message translates to:
  /// **'Complete all sets'**
  String get completeAllSets;

  /// No description provided for @resetExercise.
  ///
  /// In en, this message translates to:
  /// **'Reset exercise'**
  String get resetExercise;

  /// No description provided for @setNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Set {n}'**
  String setNumberLabel(int n);

  /// No description provided for @logged.
  ///
  /// In en, this message translates to:
  /// **'Logged'**
  String get logged;

  /// No description provided for @tapToLog.
  ///
  /// In en, this message translates to:
  /// **'Tap to log'**
  String get tapToLog;

  /// No description provided for @repsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsLabel;

  /// No description provided for @enterValidWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid weight'**
  String get enterValidWeight;

  /// No description provided for @restDay.
  ///
  /// In en, this message translates to:
  /// **'Rest day'**
  String get restDay;

  /// No description provided for @restDayTodayBody.
  ///
  /// In en, this message translates to:
  /// **'No workout planned for today. Enjoy the recovery — or check another day.'**
  String get restDayTodayBody;

  /// No description provided for @restDayPastBody.
  ///
  /// In en, this message translates to:
  /// **'No workout was assigned for this day.'**
  String get restDayPastBody;

  /// No description provided for @logWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Weight'**
  String get logWeightTitle;

  /// No description provided for @enterWeightHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your weight'**
  String get enterWeightHint;

  /// No description provided for @noteSentToCoach.
  ///
  /// In en, this message translates to:
  /// **'Note sent to coach'**
  String get noteSentToCoach;

  /// No description provided for @noLogForDay.
  ///
  /// In en, this message translates to:
  /// **'No log exists for this day yet'**
  String get noLogForDay;

  /// No description provided for @noteSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save note'**
  String get noteSaveFailed;

  /// No description provided for @editMeal.
  ///
  /// In en, this message translates to:
  /// **'Edit meal'**
  String get editMeal;

  /// No description provided for @mealName.
  ///
  /// In en, this message translates to:
  /// **'Meal name'**
  String get mealName;

  /// No description provided for @caloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get caloriesLabel;

  /// No description provided for @proteinG.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get proteinG;

  /// No description provided for @carbsG.
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get carbsG;

  /// No description provided for @fatG.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get fatG;

  /// No description provided for @invalidMacros.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid macro values'**
  String get invalidMacros;

  /// No description provided for @mealUpdated.
  ///
  /// In en, this message translates to:
  /// **'Meal updated'**
  String get mealUpdated;

  /// No description provided for @deleteMealTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete meal?'**
  String get deleteMealTitle;

  /// No description provided for @deleteMealMsg.
  ///
  /// In en, this message translates to:
  /// **'Remove “{meal}” from today\'s history?'**
  String deleteMealMsg(String meal);

  /// No description provided for @mealDeleted.
  ///
  /// In en, this message translates to:
  /// **'Meal deleted'**
  String get mealDeleted;

  /// No description provided for @noteOnlyToday.
  ///
  /// In en, this message translates to:
  /// **'You can only leave a note for today'**
  String get noteOnlyToday;

  /// No description provided for @hi.
  ///
  /// In en, this message translates to:
  /// **'Hi,'**
  String get hi;

  /// No description provided for @noteButton.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteButton;

  /// No description provided for @todaysCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Today\'s check-in'**
  String get todaysCheckIn;

  /// No description provided for @noteToCoachBody.
  ///
  /// In en, this message translates to:
  /// **'Tell your coach how today went — energy, soreness, cravings, anything. They see it with your log.'**
  String get noteToCoachBody;

  /// No description provided for @noteToCoachHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"Felt strong today, slept 8h, low on energy after lunch…\"'**
  String get noteToCoachHint;

  /// No description provided for @sendToCoach.
  ///
  /// In en, this message translates to:
  /// **'Send to coach'**
  String get sendToCoach;

  /// No description provided for @viewingPastDay.
  ///
  /// In en, this message translates to:
  /// **'Viewing past day — read only'**
  String get viewingPastDay;

  /// No description provided for @dailyWinCopied.
  ///
  /// In en, this message translates to:
  /// **'Daily win copied for sharing'**
  String get dailyWinCopied;

  /// No description provided for @shareDailyWin.
  ///
  /// In en, this message translates to:
  /// **'Share Daily Win'**
  String get shareDailyWin;

  /// No description provided for @dailyHabits.
  ///
  /// In en, this message translates to:
  /// **'Daily habits'**
  String get dailyHabits;

  /// No description provided for @yourHabits.
  ///
  /// In en, this message translates to:
  /// **'Your habits'**
  String get yourHabits;

  /// No description provided for @waterLabel.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get waterLabel;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// No description provided for @sleepQuality.
  ///
  /// In en, this message translates to:
  /// **'Sleep quality'**
  String get sleepQuality;

  /// No description provided for @howRested.
  ///
  /// In en, this message translates to:
  /// **'How rested do you feel today?'**
  String get howRested;

  /// No description provided for @todaysMeals.
  ///
  /// In en, this message translates to:
  /// **'Today\'s meals'**
  String get todaysMeals;

  /// No description provided for @logMeal.
  ///
  /// In en, this message translates to:
  /// **'Log Meal'**
  String get logMeal;

  /// No description provided for @logNow.
  ///
  /// In en, this message translates to:
  /// **'Log Now'**
  String get logNow;

  /// No description provided for @confHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get confHigh;

  /// No description provided for @confMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get confMedium;

  /// No description provided for @confLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get confLow;

  /// No description provided for @deleteMeal.
  ///
  /// In en, this message translates to:
  /// **'Delete meal'**
  String get deleteMeal;

  /// No description provided for @aiCameraError.
  ///
  /// In en, this message translates to:
  /// **'Could not access the camera or gallery.'**
  String get aiCameraError;

  /// No description provided for @describeMealFirst.
  ///
  /// In en, this message translates to:
  /// **'Describe your meal first.'**
  String get describeMealFirst;

  /// No description provided for @fillMealAndMacros.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the meal name and all macros.'**
  String get fillMealAndMacros;

  /// No description provided for @failedToSaveMeal.
  ///
  /// In en, this message translates to:
  /// **'Failed to save the meal.'**
  String get failedToSaveMeal;

  /// No description provided for @readByValenceAI.
  ///
  /// In en, this message translates to:
  /// **'Read by Valence AI'**
  String get readByValenceAI;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get manualEntry;

  /// No description provided for @yourMeal.
  ///
  /// In en, this message translates to:
  /// **'Your meal'**
  String get yourMeal;

  /// No description provided for @newMeal.
  ///
  /// In en, this message translates to:
  /// **'New meal'**
  String get newMeal;

  /// No description provided for @whatTheAiSaw.
  ///
  /// In en, this message translates to:
  /// **'What the AI saw'**
  String get whatTheAiSaw;

  /// No description provided for @adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get adjust;

  /// No description provided for @startOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get startOver;

  /// No description provided for @logAMeal.
  ///
  /// In en, this message translates to:
  /// **'Log a meal'**
  String get logAMeal;

  /// No description provided for @snapItLogged.
  ///
  /// In en, this message translates to:
  /// **'Snap it. Logged.'**
  String get snapItLogged;

  /// No description provided for @aiReadsPlate.
  ///
  /// In en, this message translates to:
  /// **'Valence AI reads your plate in seconds.'**
  String get aiReadsPlate;

  /// No description provided for @scanAMeal.
  ///
  /// In en, this message translates to:
  /// **'Scan a meal'**
  String get scanAMeal;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @describeMealHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"2 eggs, toast with butter, orange juice\"'**
  String get describeMealHint;

  /// No description provided for @describeYourMeal.
  ///
  /// In en, this message translates to:
  /// **'Describe your meal'**
  String get describeYourMeal;

  /// No description provided for @analyzeWithAI.
  ///
  /// In en, this message translates to:
  /// **'Analyze with AI'**
  String get analyzeWithAI;

  /// No description provided for @enterMacrosManually.
  ///
  /// In en, this message translates to:
  /// **'Enter macros manually'**
  String get enterMacrosManually;

  /// No description provided for @readingYourPlate.
  ///
  /// In en, this message translates to:
  /// **'Reading your plate…'**
  String get readingYourPlate;

  /// No description provided for @aiStatus1.
  ///
  /// In en, this message translates to:
  /// **'Identifying your food'**
  String get aiStatus1;

  /// No description provided for @aiStatus2.
  ///
  /// In en, this message translates to:
  /// **'Estimating portions'**
  String get aiStatus2;

  /// No description provided for @aiStatus3.
  ///
  /// In en, this message translates to:
  /// **'Crunching the macros'**
  String get aiStatus3;

  /// No description provided for @aiStatus4.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get aiStatus4;

  /// No description provided for @mealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealLunch;

  /// No description provided for @mealSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealSnack;

  /// No description provided for @mealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealDinner;

  /// No description provided for @noProgressData.
  ///
  /// In en, this message translates to:
  /// **'No progress data yet.'**
  String get noProgressData;

  /// No description provided for @chartCaloriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Avg {avg} kcal • Target {target}'**
  String chartCaloriesSubtitle(String avg, String target);

  /// No description provided for @weightTrendHint.
  ///
  /// In en, this message translates to:
  /// **'Add daily weigh-ins to see trend'**
  String get weightTrendHint;

  /// No description provided for @habitsScore.
  ///
  /// In en, this message translates to:
  /// **'Habits Score'**
  String get habitsScore;

  /// No description provided for @chartHabitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Water avg {water}L • Sleep avg {sleep}/5'**
  String chartHabitsSubtitle(String water, String sleep);

  /// No description provided for @notEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data'**
  String get notEnoughData;

  /// No description provided for @chartWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get chartWeekly;

  /// No description provided for @chartMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get chartMonthly;

  /// No description provided for @chartYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get chartYearly;

  /// No description provided for @progressLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load progress right now.'**
  String get progressLoadError;

  /// No description provided for @statusGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get statusGood;

  /// No description provided for @statusWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get statusWatch;

  /// No description provided for @statusAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get statusAlert;

  /// No description provided for @statusSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get statusSetup;

  /// No description provided for @removeClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove client?'**
  String get removeClientTitle;

  /// No description provided for @removeClientMsg.
  ///
  /// In en, this message translates to:
  /// **'This removes {name} from your roster, deletes their app data, and queues auth-account removal.'**
  String removeClientMsg(String name);

  /// No description provided for @clientRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed; auth removal queued'**
  String clientRemoved(String name);

  /// No description provided for @removeClientError.
  ///
  /// In en, this message translates to:
  /// **'Could not remove client right now'**
  String get removeClientError;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @configurePlan.
  ///
  /// In en, this message translates to:
  /// **'Configure plan'**
  String get configurePlan;

  /// No description provided for @editMacros.
  ///
  /// In en, this message translates to:
  /// **'Edit macros'**
  String get editMacros;

  /// No description provided for @removeClient.
  ///
  /// In en, this message translates to:
  /// **'Remove client'**
  String get removeClient;

  /// No description provided for @loadClientsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load clients'**
  String get loadClientsError;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkConnection;

  /// No description provided for @coachWord.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get coachWord;

  /// No description provided for @noClientsYet.
  ///
  /// In en, this message translates to:
  /// **'No clients yet'**
  String get noClientsYet;

  /// No description provided for @noClientsBody.
  ///
  /// In en, this message translates to:
  /// **'Share an invite code from your Profile tab to bring your first client on board.'**
  String get noClientsBody;

  /// No description provided for @noClientsMatch.
  ///
  /// In en, this message translates to:
  /// **'No clients match “{query}”.'**
  String noClientsMatch(String query);

  /// No description provided for @noClientsInGroup.
  ///
  /// In en, this message translates to:
  /// **'No one in this group right now.'**
  String get noClientsInGroup;

  /// No description provided for @allOnTrack.
  ///
  /// In en, this message translates to:
  /// **'All on track'**
  String get allOnTrack;

  /// No description provided for @needsYou.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 needs you} other{{count} need you}}'**
  String needsYou(int count);

  /// No description provided for @searchClients.
  ///
  /// In en, this message translates to:
  /// **'Search clients'**
  String get searchClients;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @metricFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get metricFood;

  /// No description provided for @metricHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get metricHabits;

  /// No description provided for @metricTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get metricTraining;

  /// No description provided for @awaitingLogs.
  ///
  /// In en, this message translates to:
  /// **'Awaiting recent logs'**
  String get awaitingLogs;

  /// No description provided for @setupMacrosPlan.
  ///
  /// In en, this message translates to:
  /// **'Set up macros & plan to activate'**
  String get setupMacrosPlan;

  /// No description provided for @noLogsYet.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get noLogsYet;

  /// No description provided for @lastLogOn.
  ///
  /// In en, this message translates to:
  /// **'Last log · {date}'**
  String lastLogOn(String date);

  /// No description provided for @loggedToday.
  ///
  /// In en, this message translates to:
  /// **'Logged today'**
  String get loggedToday;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day ago} other{{days} days ago}}'**
  String daysAgo(num days);

  /// No description provided for @deleteTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete template?'**
  String get deleteTemplateTitle;

  /// No description provided for @deleteTemplateMsg.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes “{name}” from your library. Workouts already assigned to clients stay intact.'**
  String deleteTemplateMsg(String name);

  /// No description provided for @templateDeleted.
  ///
  /// In en, this message translates to:
  /// **'Template deleted'**
  String get templateDeleted;

  /// No description provided for @deleteTemplateError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the template. Please try again.'**
  String get deleteTemplateError;

  /// No description provided for @noClientsToAssign.
  ///
  /// In en, this message translates to:
  /// **'No clients to assign yet'**
  String get noClientsToAssign;

  /// No description provided for @assignedDays.
  ///
  /// In en, this message translates to:
  /// **'Assigned {count} days to {name}'**
  String assignedDays(int count, String name);

  /// No description provided for @assignedToName.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}'**
  String assignedToName(String name);

  /// No description provided for @assignError.
  ///
  /// In en, this message translates to:
  /// **'Could not assign right now. Please try again.'**
  String get assignError;

  /// No description provided for @noTemplatesMatch.
  ///
  /// In en, this message translates to:
  /// **'No templates match “{query}”.'**
  String noTemplatesMatch(String query);

  /// No description provided for @workoutPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Plans'**
  String get workoutPlansTitle;

  /// No description provided for @statExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get statExercises;

  /// No description provided for @statSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get statSets;

  /// No description provided for @statReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get statReps;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @newTemplate.
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get newTemplate;

  /// No description provided for @buildFirstPlan.
  ///
  /// In en, this message translates to:
  /// **'Build your first plan'**
  String get buildFirstPlan;

  /// No description provided for @buildFirstPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Create a reusable workout once, then assign it to any client in seconds.'**
  String get buildFirstPlanBody;

  /// No description provided for @createTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create template'**
  String get createTemplate;

  /// No description provided for @searchTemplates.
  ///
  /// In en, this message translates to:
  /// **'Search templates'**
  String get searchTemplates;

  /// No description provided for @enterValidWeightBlank.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid weight, or leave it blank'**
  String get enterValidWeightBlank;

  /// No description provided for @giveTemplateName.
  ///
  /// In en, this message translates to:
  /// **'Give your template a name'**
  String get giveTemplateName;

  /// No description provided for @addAtLeastOneExercise.
  ///
  /// In en, this message translates to:
  /// **'Add at least one exercise'**
  String get addAtLeastOneExercise;

  /// No description provided for @templateUpdated.
  ///
  /// In en, this message translates to:
  /// **'Template updated'**
  String get templateUpdated;

  /// No description provided for @templateCreated.
  ///
  /// In en, this message translates to:
  /// **'Template created'**
  String get templateCreated;

  /// No description provided for @couldNotSaveNow.
  ///
  /// In en, this message translates to:
  /// **'Could not save right now'**
  String get couldNotSaveNow;

  /// No description provided for @templateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get templateNameLabel;

  /// No description provided for @templateNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Upper Body · Push'**
  String get templateNameHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @workoutTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Template'**
  String get workoutTemplateTitle;

  /// No description provided for @exerciseNameHint.
  ///
  /// In en, this message translates to:
  /// **'Exercise name'**
  String get exerciseNameHint;

  /// No description provided for @targetWeightOptional.
  ///
  /// In en, this message translates to:
  /// **'Target weight · optional'**
  String get targetWeightOptional;

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get addExercise;

  /// No description provided for @whenLabel.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get whenLabel;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @tomorrowLabel.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrowLabel;

  /// No description provided for @pickLabel.
  ///
  /// In en, this message translates to:
  /// **'Pick…'**
  String get pickLabel;

  /// No description provided for @repeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatLabel;

  /// No description provided for @justOnce.
  ///
  /// In en, this message translates to:
  /// **'Just once'**
  String get justOnce;

  /// No description provided for @weeklyLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyLabel;

  /// No description provided for @assignNWorkouts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Assign 1 Workout} other{Assign {count} Workouts}}'**
  String assignNWorkouts(num count);

  /// No description provided for @assignWorkoutBtn.
  ///
  /// In en, this message translates to:
  /// **'Assign Workout'**
  String get assignWorkoutBtn;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @noDaysInRange.
  ///
  /// In en, this message translates to:
  /// **'No days in range — add a week or pick a later day'**
  String get noDaysInRange;

  /// No description provided for @schedulesDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Schedules 1 training day} other{Schedules {count} training days}}'**
  String schedulesDays(int count);

  /// No description provided for @weekDuration.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String weekDuration(int count);

  /// No description provided for @sleepPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get sleepPoor;

  /// No description provided for @sleepFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get sleepFair;

  /// No description provided for @sleepGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get sleepGreat;

  /// No description provided for @sleepLabel.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepLabel;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteSaved;

  /// No description provided for @macroTargets.
  ///
  /// In en, this message translates to:
  /// **'Macro targets'**
  String get macroTargets;

  /// No description provided for @dailyGoalsName.
  ///
  /// In en, this message translates to:
  /// **'Daily goals · {name}'**
  String dailyGoalsName(String name);

  /// No description provided for @saveTargets.
  ///
  /// In en, this message translates to:
  /// **'Save targets'**
  String get saveTargets;

  /// No description provided for @enterValidMacros.
  ///
  /// In en, this message translates to:
  /// **'Enter valid macro values'**
  String get enterValidMacros;

  /// No description provided for @macrosMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'All macro values must be greater than 0'**
  String get macrosMustBePositive;

  /// No description provided for @macroTargetsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Macro targets updated'**
  String get macroTargetsUpdated;

  /// No description provided for @failedSaveMacros.
  ///
  /// In en, this message translates to:
  /// **'Failed to save macros'**
  String get failedSaveMacros;

  /// No description provided for @clientDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Client Details'**
  String get clientDetailsTitle;

  /// No description provided for @loadClientError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this client right now.'**
  String get loadClientError;

  /// No description provided for @loadDayError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this day\'s data.'**
  String get loadDayError;

  /// No description provided for @tabAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get tabAnalytics;

  /// No description provided for @tabPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get tabPlan;

  /// No description provided for @nutritionSummary.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Summary'**
  String get nutritionSummary;

  /// No description provided for @editTargets.
  ///
  /// In en, this message translates to:
  /// **'Edit Targets'**
  String get editTargets;

  /// No description provided for @workoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workoutLabel;

  /// No description provided for @swapWorkout.
  ///
  /// In en, this message translates to:
  /// **'Swap Workout'**
  String get swapWorkout;

  /// No description provided for @coachNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Coach Note'**
  String get coachNoteLabel;

  /// No description provided for @noMealsLogged.
  ///
  /// In en, this message translates to:
  /// **'No meals logged for this day.'**
  String get noMealsLogged;

  /// No description provided for @noWorkoutAssignedLib.
  ///
  /// In en, this message translates to:
  /// **'No workout assigned for this day.\nAssign one from the Library tab.'**
  String get noWorkoutAssignedLib;

  /// No description provided for @pendingTarget.
  ///
  /// In en, this message translates to:
  /// **'pending · target {reps}'**
  String pendingTarget(int reps);

  /// No description provided for @clientCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Client check-in'**
  String get clientCheckIn;

  /// No description provided for @noCheckInNote.
  ///
  /// In en, this message translates to:
  /// **'No check-in note for this day.'**
  String get noCheckInNote;

  /// No description provided for @loadAnalyticsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load analytics.'**
  String get loadAnalyticsError;

  /// No description provided for @noCoachLinked.
  ///
  /// In en, this message translates to:
  /// **'This client has no coach linked.'**
  String get noCoachLinked;

  /// No description provided for @noLibraryWorkouts.
  ///
  /// In en, this message translates to:
  /// **'No workouts in your library yet — create one in the Library tab.'**
  String get noLibraryWorkouts;

  /// No description provided for @workoutAssignedName.
  ///
  /// In en, this message translates to:
  /// **'Workout assigned · {name}'**
  String workoutAssignedName(String name);

  /// No description provided for @assignWorkoutErr.
  ///
  /// In en, this message translates to:
  /// **'Could not assign the workout. Please try again.'**
  String get assignWorkoutErr;

  /// No description provided for @updateWorkout.
  ///
  /// In en, this message translates to:
  /// **'Update Workout'**
  String get updateWorkout;

  /// No description provided for @workoutTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Workout title'**
  String get workoutTitleLabel;

  /// No description provided for @exerciseNumber.
  ///
  /// In en, this message translates to:
  /// **'Exercise {n}'**
  String exerciseNumber(int n);

  /// No description provided for @targetWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Target weight'**
  String get targetWeightLabel;

  /// No description provided for @saveWorkout.
  ///
  /// In en, this message translates to:
  /// **'Save workout'**
  String get saveWorkout;

  /// No description provided for @workoutTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Workout title and exercises are required'**
  String get workoutTitleRequired;

  /// No description provided for @workoutUpdated.
  ///
  /// In en, this message translates to:
  /// **'Workout updated'**
  String get workoutUpdated;

  /// No description provided for @updateWorkoutError.
  ///
  /// In en, this message translates to:
  /// **'Could not update the workout. Please try again.'**
  String get updateWorkoutError;

  /// No description provided for @removeWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove workout?'**
  String get removeWorkoutTitle;

  /// No description provided for @removeWorkoutMsg.
  ///
  /// In en, this message translates to:
  /// **'This clears the assigned workout for this day. Your library template stays intact.'**
  String get removeWorkoutMsg;

  /// No description provided for @workoutRemoved.
  ///
  /// In en, this message translates to:
  /// **'Workout removed'**
  String get workoutRemoved;

  /// No description provided for @removeWorkoutError.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the workout. Please try again.'**
  String get removeWorkoutError;

  /// No description provided for @noCustomHabitsBody.
  ///
  /// In en, this message translates to:
  /// **'No custom habits yet. Add things like steps, supplements, or a daily walk — they appear on the client\'s home, on top of water, sleep & weight.'**
  String get noCustomHabitsBody;

  /// No description provided for @addHabits.
  ///
  /// In en, this message translates to:
  /// **'Add habits'**
  String get addHabits;

  /// No description provided for @manageHabits.
  ///
  /// In en, this message translates to:
  /// **'Manage habits'**
  String get manageHabits;

  /// No description provided for @habitsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Habits updated'**
  String get habitsUpdated;

  /// No description provided for @saveHabitsError.
  ///
  /// In en, this message translates to:
  /// **'Could not save habits'**
  String get saveHabitsError;

  /// No description provided for @configureMacros.
  ///
  /// In en, this message translates to:
  /// **'Configure Macros'**
  String get configureMacros;

  /// No description provided for @savingMacrosConfigures.
  ///
  /// In en, this message translates to:
  /// **'Saving macros marks this client as configured.'**
  String get savingMacrosConfigures;

  /// No description provided for @workoutLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Log ({date})'**
  String workoutLogTitle(String date);

  /// No description provided for @noWorkoutSelectedDay.
  ///
  /// In en, this message translates to:
  /// **'No workout assigned for selected day.'**
  String get noWorkoutSelectedDay;

  /// No description provided for @updateBtn.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateBtn;

  /// No description provided for @yourNote.
  ///
  /// In en, this message translates to:
  /// **'Your note'**
  String get yourNote;

  /// No description provided for @leaveANote.
  ///
  /// In en, this message translates to:
  /// **'Leave a note'**
  String get leaveANote;

  /// No description provided for @savedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedLabel;

  /// No description provided for @writeFeedbackFor.
  ///
  /// In en, this message translates to:
  /// **'Write feedback for {name}…'**
  String writeFeedbackFor(String name);

  /// No description provided for @editingPastDay.
  ///
  /// In en, this message translates to:
  /// **'Editing a past day'**
  String get editingPastDay;

  /// No description provided for @updateNote.
  ///
  /// In en, this message translates to:
  /// **'Update note'**
  String get updateNote;

  /// No description provided for @saveNote.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get saveNote;

  /// No description provided for @relToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get relToday;

  /// No description provided for @relTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get relTomorrow;

  /// No description provided for @relYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get relYesterday;

  /// No description provided for @forClientDate.
  ///
  /// In en, this message translates to:
  /// **'For {name} · {date}'**
  String forClientDate(String name, String date);

  /// No description provided for @chooseAWorkout.
  ///
  /// In en, this message translates to:
  /// **'Choose a workout'**
  String get chooseAWorkout;

  /// No description provided for @includesLabel.
  ///
  /// In en, this message translates to:
  /// **'Includes'**
  String get includesLabel;

  /// No description provided for @exerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}}'**
  String exerciseCount(int count);

  /// No description provided for @habitsManagerBody.
  ///
  /// In en, this message translates to:
  /// **'Habits this client ticks off each day, alongside water, sleep & weight.'**
  String get habitsManagerBody;

  /// No description provided for @addAHabit.
  ///
  /// In en, this message translates to:
  /// **'Add a habit'**
  String get addAHabit;

  /// No description provided for @habitNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10k steps'**
  String get habitNameHint;

  /// No description provided for @saveHabits.
  ///
  /// In en, this message translates to:
  /// **'Save habits'**
  String get saveHabits;

  /// No description provided for @plansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the plan that fits your roster'**
  String get plansSubtitle;

  /// No description provided for @planCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get planCurrent;

  /// No description provided for @planMostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get planMostPopular;

  /// No description provided for @planPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get planPerMonth;

  /// CTA button to pick a plan
  ///
  /// In en, this message translates to:
  /// **'Choose {plan}'**
  String planChoose(String plan);

  /// Client limit line on a plan card
  ///
  /// In en, this message translates to:
  /// **'Up to {count} clients'**
  String planClientsUpTo(int count);

  /// No description provided for @planClientsUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited clients'**
  String get planClientsUnlimited;

  /// Plan usage shown in settings, e.g. 12 / 30 clients
  ///
  /// In en, this message translates to:
  /// **'{used} / {total} clients'**
  String planUsageLimited(int used, int total);

  /// No description provided for @planFreeTagline.
  ///
  /// In en, this message translates to:
  /// **'Get started with a few clients'**
  String get planFreeTagline;

  /// No description provided for @planProTagline.
  ///
  /// In en, this message translates to:
  /// **'For growing coaches'**
  String get planProTagline;

  /// No description provided for @planStudioTagline.
  ///
  /// In en, this message translates to:
  /// **'For established coaches, no limits'**
  String get planStudioTagline;

  /// No description provided for @featureMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Daily client monitoring'**
  String get featureMonitoring;

  /// No description provided for @featureWorkoutLibrary.
  ///
  /// In en, this message translates to:
  /// **'Workout library & programming'**
  String get featureWorkoutLibrary;

  /// No description provided for @featureAiMeal.
  ///
  /// In en, this message translates to:
  /// **'AI meal scan included'**
  String get featureAiMeal;

  /// No description provided for @featureRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring weekly programming'**
  String get featureRecurring;

  /// No description provided for @featureCustomHabits.
  ///
  /// In en, this message translates to:
  /// **'Custom habit tracking'**
  String get featureCustomHabits;

  /// No description provided for @featureAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Progress analytics'**
  String get featureAnalytics;

  /// No description provided for @featurePrioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get featurePrioritySupport;

  /// No description provided for @featureEverythingFree.
  ///
  /// In en, this message translates to:
  /// **'Everything in Free'**
  String get featureEverythingFree;

  /// No description provided for @featureEverythingPro.
  ///
  /// In en, this message translates to:
  /// **'Everything in Pro'**
  String get featureEverythingPro;

  /// No description provided for @upgradeContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade your plan'**
  String get upgradeContactTitle;

  /// Body of the interim upgrade-via-contact dialog
  ///
  /// In en, this message translates to:
  /// **'Online checkout is launching soon. Contact us and we\'ll set up your {plan} plan right away.'**
  String upgradeContactBody(String plan);

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @clientLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Client limit reached'**
  String get clientLimitTitle;

  /// Message when a coach hits the client cap
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your plan\'s limit of {count} clients. Upgrade to add more.'**
  String clientLimitBody(int count);

  /// No description provided for @viewPlans.
  ///
  /// In en, this message translates to:
  /// **'View plans'**
  String get viewPlans;

  /// Destructive delete-account row/button label
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This permanently erases your account and all your data. This action cannot be undone.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get deleteAccountConfirmPassword;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to check in'**
  String get reminderTitle;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'Log your meals and habits in Valence.'**
  String get reminderBody;

  /// No description provided for @reminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTimeLabel;

  /// No description provided for @remindersPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications in your device settings to get reminders.'**
  String get remindersPermissionDenied;

  /// No description provided for @intakePriorTitle.
  ///
  /// In en, this message translates to:
  /// **'Have you tracked before?'**
  String get intakePriorTitle;

  /// No description provided for @intakePriorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No judgment — it just helps us set the right pace.'**
  String get intakePriorSubtitle;

  /// No description provided for @priorNever.
  ///
  /// In en, this message translates to:
  /// **'Never tracked'**
  String get priorNever;

  /// No description provided for @priorStopped.
  ///
  /// In en, this message translates to:
  /// **'Tried, didn\'t stick'**
  String get priorStopped;

  /// No description provided for @priorCurrent.
  ///
  /// In en, this message translates to:
  /// **'I track already'**
  String get priorCurrent;

  /// No description provided for @onboardCommitTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to commit?'**
  String get onboardCommitTitle;

  /// No description provided for @onboardCommitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Small daily logs add up. Show up for yourself and your plan will do the rest.'**
  String get onboardCommitSubtitle;

  /// No description provided for @onboardCommitCta.
  ///
  /// In en, this message translates to:
  /// **'I\'m in'**
  String get onboardCommitCta;

  /// No description provided for @createAccountSavePlan.
  ///
  /// In en, this message translates to:
  /// **'Create account to save my plan'**
  String get createAccountSavePlan;

  /// No description provided for @planGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Your goal'**
  String get planGoalLabel;

  /// No description provided for @planReachBy.
  ///
  /// In en, this message translates to:
  /// **'Reach {weight} by {date}'**
  String planReachBy(String weight, String date);

  /// No description provided for @roleCoachDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage clients, build plans, track everyone\'s progress.'**
  String get roleCoachDesc;

  /// No description provided for @roleClientDesc.
  ///
  /// In en, this message translates to:
  /// **'Log meals with AI and follow your coach\'s plan.'**
  String get roleClientDesc;

  /// No description provided for @unitsMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get unitsMetric;

  /// No description provided for @unitsImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get unitsImperial;

  /// No description provided for @unitLb.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get unitLb;

  /// No description provided for @weightToLoseU.
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit} to lose'**
  String weightToLoseU(String amount, String unit);

  /// No description provided for @weightToGainU.
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit} to gain'**
  String weightToGainU(String amount, String unit);

  /// No description provided for @intakeAgeInsight.
  ///
  /// In en, this message translates to:
  /// **'Your age affects how many calories you burn at rest.'**
  String get intakeAgeInsight;

  /// No description provided for @intakeHeightInsight.
  ///
  /// In en, this message translates to:
  /// **'Height pairs with your weight to estimate your metabolism.'**
  String get intakeHeightInsight;

  /// No description provided for @intakeWeightInsight.
  ///
  /// In en, this message translates to:
  /// **'This is your starting line — we\'ll track every step from here.'**
  String get intakeWeightInsight;

  /// No description provided for @intakeTargetInsight.
  ///
  /// In en, this message translates to:
  /// **'A gradual pace is the most sustainable way to get there.'**
  String get intakeTargetInsight;

  /// No description provided for @intakeActivityInsight.
  ///
  /// In en, this message translates to:
  /// **'Sets your daily burn using the Mifflin-St Jeor method dietitians trust.'**
  String get intakeActivityInsight;

  /// No description provided for @ciSpecialtiesInsight.
  ///
  /// In en, this message translates to:
  /// **'We tailor the templates and tips we suggest to your focus.'**
  String get ciSpecialtiesInsight;

  /// No description provided for @ciExperienceInsight.
  ///
  /// In en, this message translates to:
  /// **'This sets sensible defaults — you can change anything later.'**
  String get ciExperienceInsight;

  /// No description provided for @ciRosterInsight.
  ///
  /// In en, this message translates to:
  /// **'Valence grows with you — start free with your first 3 clients.'**
  String get ciRosterInsight;

  /// No description provided for @ciPriorInsight.
  ///
  /// In en, this message translates to:
  /// **'We\'ll help you bring it all into one place.'**
  String get ciPriorInsight;

  /// No description provided for @purchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'You\'re upgraded — enjoy!'**
  String get purchaseSuccess;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase didn\'t go through. Please try again.'**
  String get purchaseFailed;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @authErrInviteRequired.
  ///
  /// In en, this message translates to:
  /// **'An invite code is required to join'**
  String get authErrInviteRequired;

  /// No description provided for @authErrInviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'That invite code is invalid, expired, or already used'**
  String get authErrInviteInvalid;

  /// No description provided for @authErrEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'That email is already registered — try logging in'**
  String get authErrEmailInUse;

  /// No description provided for @authErrWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak — use at least 6 characters'**
  String get authErrWeakPassword;

  /// No description provided for @authErrInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address is not valid'**
  String get authErrInvalidEmail;

  /// No description provided for @authErrWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect'**
  String get authErrWrongCredentials;

  /// No description provided for @authErrTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts — wait a moment and try again'**
  String get authErrTooManyRequests;

  /// No description provided for @authErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error — check your connection and try again'**
  String get authErrNetwork;

  /// No description provided for @authErrUserDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Your account data could not be found'**
  String get authErrUserDataNotFound;

  /// No description provided for @authErrNoEmailOnFile.
  ///
  /// In en, this message translates to:
  /// **'No email address on file'**
  String get authErrNoEmailOnFile;

  /// No description provided for @authErrNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in'**
  String get authErrNotLoggedIn;

  /// No description provided for @authErrClientsOnly.
  ///
  /// In en, this message translates to:
  /// **'Only client accounts can link a coach'**
  String get authErrClientsOnly;

  /// No description provided for @authErrLinkCoachFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not link your coach — try again'**
  String get authErrLinkCoachFailed;

  /// No description provided for @authErrIncorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get authErrIncorrectPassword;

  /// No description provided for @authErrRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign out, sign in again, then retry'**
  String get authErrRecentLogin;

  /// No description provided for @authErrResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the reset email'**
  String get authErrResetFailed;

  /// No description provided for @authErrSignupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create your account — try again'**
  String get authErrSignupFailed;

  /// No description provided for @authErrSigninFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign you in — try again'**
  String get authErrSigninFailed;

  /// No description provided for @authErrDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account — try again'**
  String get authErrDeleteFailed;

  /// No description provided for @authErrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong — please try again'**
  String get authErrUnknown;

  /// Coach roster card summary line: client has been silent for N days
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Quiet for 1 day} other{Quiet for {days} days}}'**
  String quietForDays(int days);

  /// No description provided for @statusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statusNew;

  /// No description provided for @joinedRecently.
  ///
  /// In en, this message translates to:
  /// **'Just joined — awaiting first log'**
  String get joinedRecently;

  /// Roster subline when status is driven by weak 7-day consistency rather than silence
  ///
  /// In en, this message translates to:
  /// **'{pct}% consistency this week'**
  String consistencyThisWeek(int pct);

  /// Cover role-split serif prompt above the coach/client option cards
  ///
  /// In en, this message translates to:
  /// **'How will you use Valence?'**
  String get coverRolePrompt;

  /// Cover hero greeting on get_started, speaks to both coaches and clients
  ///
  /// In en, this message translates to:
  /// **'Welcome to Valence'**
  String get welcomeTitle;

  /// Client onboarding intro screen headline
  ///
  /// In en, this message translates to:
  /// **'Your coach, in your pocket'**
  String get clientIntroTitle;

  /// Coach onboarding intro screen headline
  ///
  /// In en, this message translates to:
  /// **'Your coaching, all in one place'**
  String get coachIntroTitle;

  /// Shared subtitle on the role onboarding intro screens
  ///
  /// In en, this message translates to:
  /// **'Here\'s how Valence works for you.'**
  String get introSubtitle;

  /// Client role label on the role picker (warmer, aspirational). Coach-facing UI still uses roleClient='Client'.
  ///
  /// In en, this message translates to:
  /// **'Athlete'**
  String get roleAthlete;

  /// CTA on the client onboarding intro, entering the intake
  ///
  /// In en, this message translates to:
  /// **'Build my plan'**
  String get clientIntroCta;

  /// CTA on the coach onboarding intro, entering the intake
  ///
  /// In en, this message translates to:
  /// **'Set up my profile'**
  String get coachIntroCta;

  /// Coach intake reveal subtitle (replaces ciStudioReady — avoids 'studio')
  ///
  /// In en, this message translates to:
  /// **'Your coaching space is ready. Invite your first client to get started.'**
  String get coachSetupReady;

  /// Meal-result confidence line. {word} is the localized high/medium/low word, {score} is 0-100.
  ///
  /// In en, this message translates to:
  /// **'{word} confidence ({score}/100) — tap Adjust to fine-tune.'**
  String confidenceNote(String word, int score);

  /// No description provided for @centerYourPlate.
  ///
  /// In en, this message translates to:
  /// **'Center your plate'**
  String get centerYourPlate;

  /// No description provided for @portionLabel.
  ///
  /// In en, this message translates to:
  /// **'Portion'**
  String get portionLabel;

  /// Toast after logging a meal; n = remaining calories.
  ///
  /// In en, this message translates to:
  /// **'{n} kcal left today'**
  String kcalLeftToday(int n);

  /// Toast after logging a meal when over target; n = calories over.
  ///
  /// In en, this message translates to:
  /// **'{n} kcal over today'**
  String kcalOverToday(int n);

  /// No description provided for @describeCardSub.
  ///
  /// In en, this message translates to:
  /// **'Type it — the AI does the math'**
  String get describeCardSub;

  /// No description provided for @manualCardSub.
  ///
  /// In en, this message translates to:
  /// **'Know the numbers? Enter them yourself'**
  String get manualCardSub;

  /// No description provided for @flashLabel.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get flashLabel;

  /// No description provided for @galleryCardSub.
  ///
  /// In en, this message translates to:
  /// **'Pick an existing photo'**
  String get galleryCardSub;

  /// No description provided for @scanCardSub.
  ///
  /// In en, this message translates to:
  /// **'Point, shoot — logged'**
  String get scanCardSub;

  /// No description provided for @aiInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI analysis'**
  String get aiInsightsTitle;

  /// No description provided for @aiInsightsTease.
  ///
  /// In en, this message translates to:
  /// **'See what\'s working and what\'s slipping, read from the last 14 days of logs.'**
  String get aiInsightsTease;

  /// No description provided for @aiInsightsUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Pro'**
  String get aiInsightsUnlock;

  /// No description provided for @aiInsightsWins.
  ///
  /// In en, this message translates to:
  /// **'What\'s working'**
  String get aiInsightsWins;

  /// No description provided for @aiInsightsRisks.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get aiInsightsRisks;

  /// No description provided for @aiInsightsActions.
  ///
  /// In en, this message translates to:
  /// **'What you could do'**
  String get aiInsightsActions;

  /// No description provided for @aiInsightsReading.
  ///
  /// In en, this message translates to:
  /// **'Reading the last 14 days…'**
  String get aiInsightsReading;

  /// No description provided for @aiInsightsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Re-analyze'**
  String get aiInsightsRefresh;

  /// No description provided for @aiInsightsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Nothing new logged since the last analysis.'**
  String get aiInsightsUpToDate;

  /// No description provided for @aiInsightsNoData.
  ///
  /// In en, this message translates to:
  /// **'Not enough logged data yet. Come back after a few more days of logging.'**
  String get aiInsightsNoData;

  /// No description provided for @aiInsightsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t analyze right now. Try again.'**
  String get aiInsightsError;

  /// No description provided for @aiInsightsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Observations from logged data — not medical advice. Confirm before acting.'**
  String get aiInsightsDisclaimer;

  /// No description provided for @aiAnalyzedToday.
  ///
  /// In en, this message translates to:
  /// **'Analyzed today'**
  String get aiAnalyzedToday;

  /// No description provided for @aiAnalyzedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Analyzed yesterday'**
  String get aiAnalyzedYesterday;

  /// Freshness line on the coach's AI analysis card, for 2+ days old. Today/yesterday use their own keys so no apostrophe lands inside an ICU plural (where ' is an escape character).
  ///
  /// In en, this message translates to:
  /// **'{days, plural, other{Analyzed {days} days ago}}'**
  String aiAnalyzedDaysAgo(num days);

  /// Confidence line under the AI analysis. {word} is the localized confHigh/confMedium/confLow word.
  ///
  /// In en, this message translates to:
  /// **'{word} confidence'**
  String aiInsightsConfidence(String word);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
