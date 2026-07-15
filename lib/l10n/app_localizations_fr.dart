// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTagline => 'Le coaching, en phase';

  @override
  String get landingSubtitle =>
      'Un suivi quotidien entre les coachs et leurs clients — conçu pour de vrais résultats.';

  @override
  String get iAmA => 'JE SUIS';

  @override
  String get roleCoach => 'Coach';

  @override
  String get roleClient => 'Client';

  @override
  String get getStarted => 'Commencer';

  @override
  String get signIn => 'Se connecter';

  @override
  String get logIn => 'Se connecter';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte ?';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get fullName => 'Nom complet';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get remove => 'Retirer';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get done => 'Terminé';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get next => 'Suivant';

  @override
  String get back => 'Retour';

  @override
  String get retry => 'Réessayer';

  @override
  String get close => 'Fermer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get search => 'Rechercher';

  @override
  String get navToday => 'Aujourd\'hui';

  @override
  String get navWorkouts => 'Séances';

  @override
  String get navProgress => 'Progression';

  @override
  String get navProfile => 'Profil';

  @override
  String get navClients => 'Clients';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get sectionPreferences => 'PRÉFÉRENCES';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSubtitle =>
      'Choisissez la langue de l\'application';

  @override
  String get languageSystemDefault => 'Paramètre du système';

  @override
  String get chooseLanguage => 'Choisir la langue';

  @override
  String get welcomeBackTitle => 'Bon retour';

  @override
  String get welcomeBackToast => 'Bon retour !';

  @override
  String get loginSubtitle => 'Connectez-vous pour continuer votre parcours.';

  @override
  String get emailRequired => 'L\'e-mail est requis';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String get emailHint => 'Saisissez votre adresse e-mail';

  @override
  String get passwordHint => 'Saisissez votre mot de passe';

  @override
  String get orContinueWith => 'ou continuer avec';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get forgotPasswordEnterEmail =>
      'Saisissez votre e-mail ci-dessus, puis appuyez sur Mot de passe oublié.';

  @override
  String resetLinkSent(String email) {
    return 'Lien de réinitialisation envoyé à $email';
  }

  @override
  String get inviteLinkRequired => 'Le lien d\'invitation est requis';

  @override
  String get accountCreated => 'Compte créé avec succès';

  @override
  String get couldNotCreateAccount => 'Impossible de créer le compte';

  @override
  String get joinValence => 'Rejoignez Valence';

  @override
  String signupSubtitle(String role) {
    return 'Créez votre compte $role premium.';
  }

  @override
  String get inviteCodeRequired => 'Le code d\'invitation est requis';

  @override
  String get inviteCode => 'Code d\'invitation';

  @override
  String get inviteCodeHint => 'Saisissez le code de votre coach';

  @override
  String get fullNameRequired => 'Le nom complet est requis';

  @override
  String get fullNameHint => 'Saisissez votre nom complet';

  @override
  String get emailInvalid => 'Veuillez saisir une adresse e-mail valide';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit comporter au moins 6 caractères';

  @override
  String get passwordCreateHint => 'Créez un mot de passe sécurisé';

  @override
  String get logOut => 'Se déconnecter';

  @override
  String get linkCoachTitle => 'Saisissez le code d\'invitation du coach';

  @override
  String get linkCoachSubtitle =>
      'Vous devez associer un coach avant d\'utiliser l\'application.';

  @override
  String get skip => 'Passer';

  @override
  String get obClientLogTitle => 'Enregistrez en quelques secondes';

  @override
  String get obClientLogBody =>
      'Photographiez un repas, cochez une habitude, enregistrez une série. L\'IA de Valence calcule les calories à votre place.';

  @override
  String get obClientHabitsTitle => 'Créez vos habitudes quotidiennes';

  @override
  String get obClientHabitsBody =>
      'Eau, sommeil, poids et les habitudes définies par votre coach — le tout dans une liste quotidienne sereine.';

  @override
  String get obClientCoachTitle => 'Votre coach veille sur vous';

  @override
  String get obClientCoachBody =>
      'Il suit vos progrès et vous encourage au bon moment. Vous n\'êtes jamais seul.';

  @override
  String get obClientFinish => 'Créez votre compte';

  @override
  String get obCoachRosterTitle => 'Voyez qui a besoin de vous';

  @override
  String get obCoachRosterBody =>
      'Toute votre liste en un coup d\'œil — qui suit et qui décroche, mis à jour dès qu\'un client enregistre.';

  @override
  String get obCoachProgramTitle => 'Programmez une fois, suivez chaque jour';

  @override
  String get obCoachProgramBody =>
      'Créez des séances et des habitudes, attribuez-les et suivez leur réalisation — fini WhatsApp et les tableurs.';

  @override
  String get obCoachGrowTitle => 'Développez-vous sans vous épuiser';

  @override
  String get obCoachGrowBody =>
      'Gardez la touche personnelle, de 5 à 50 clients. Valence relance à votre place pour que vous puissiez coacher.';

  @override
  String get obCoachFinish => 'Créer un compte coach';

  @override
  String get intakeSaveError =>
      'Impossible d\'enregistrer votre plan. Veuillez réessayer.';

  @override
  String get intakeGoalTitle => 'Quel est votre objectif ?';

  @override
  String get intakeGoalSubtitle =>
      'Nous adapterons vos calories quotidiennes en conséquence.';

  @override
  String get goalLoseTitle => 'Perdre du poids';

  @override
  String get goalLoseSubtitle => 'Perte de graisse progressive';

  @override
  String get goalMaintainTitle => 'Maintenir';

  @override
  String get goalMaintainSubtitle => 'Restez où vous êtes';

  @override
  String get goalGainTitle => 'Prendre du muscle';

  @override
  String get goalGainSubtitle => 'Gains secs';

  @override
  String get intakeSexTitle => 'Qu\'est-ce qui vous décrit le mieux ?';

  @override
  String get intakeSexSubtitle =>
      'Le sexe biologique modifie le calcul des calories.';

  @override
  String get sexMale => 'Homme';

  @override
  String get sexFemale => 'Femme';

  @override
  String get intakeAgeTitle => 'Quel âge avez-vous ?';

  @override
  String get intakeAgeSubtitle =>
      'Cela influence votre métabolisme et vos besoins caloriques.';

  @override
  String get unitYears => 'ans';

  @override
  String get intakeHeightTitle => 'Quelle est votre taille ?';

  @override
  String get intakeHeightSubtitle =>
      'Utilisé pour estimer votre énergie quotidienne.';

  @override
  String get unitCm => 'cm';

  @override
  String get intakeWeightTitle => 'Votre poids actuel ?';

  @override
  String get intakeWeightSubtitle =>
      'Juste notre point de départ — on suit à partir d\'ici.';

  @override
  String get unitKg => 'kg';

  @override
  String get intakeTargetTitle => 'Votre poids cible ?';

  @override
  String get intakeTargetSubtitle =>
      'Fixez la destination — nous planifions le chemin.';

  @override
  String get intakeActivityTitle => 'Quel est votre niveau d\'activité ?';

  @override
  String get intakeActivitySubtitle =>
      'En dehors des séances prévues, au quotidien.';

  @override
  String get intakeAnalyzing1 => 'Analyse de votre métabolisme';

  @override
  String get intakeAnalyzing2 => 'Calcul de vos calories';

  @override
  String get intakeAnalyzing3 => 'Équilibrage de vos macros';

  @override
  String get intakeAnalyzing4 => 'Finalisation de votre plan';

  @override
  String get intakeBuildingPlan => 'Création de votre plan';

  @override
  String get intakePlanReady => 'Votre plan est prêt';

  @override
  String intakePlanReadyNamed(String name) {
    return '$name, votre plan est prêt';
  }

  @override
  String get intakePlanSubtitle =>
      'Calculé automatiquement à partir de vos réponses — votre coach peut l\'ajuster à tout moment.';

  @override
  String get dailyCalories => 'Calories quotidiennes';

  @override
  String get kcal => 'kcal';

  @override
  String get macroProtein => 'Protéines';

  @override
  String get macroCarbs => 'Glucides';

  @override
  String get macroFat => 'Lipides';

  @override
  String get startTracking => 'Commencer le suivi';

  @override
  String get deltaMaintain => 'Maintenez votre poids';

  @override
  String weightToLose(String kg) {
    return '$kg kg à perdre';
  }

  @override
  String weightToGain(String kg) {
    return '$kg kg à prendre';
  }

  @override
  String get activitySedentary => 'Sédentaire';

  @override
  String get activitySedentaryHint => 'Travail de bureau, peu d\'exercice';

  @override
  String get activityLight => 'Légèrement actif';

  @override
  String get activityLightHint => 'Exercice léger 1–3 j/sem';

  @override
  String get activityModerate => 'Modérément actif';

  @override
  String get activityModerateHint => 'Exercice 3–5 j/sem';

  @override
  String get activityActive => 'Très actif';

  @override
  String get activityActiveHint => 'Exercice intense 6–7 j/sem';

  @override
  String get activityVeryActive => 'Athlète';

  @override
  String get activityVeryActiveHint => 'Entraînement deux fois par jour';

  @override
  String get specWeightLoss => 'Perte de poids';

  @override
  String get specMuscleGain => 'Prise de muscle';

  @override
  String get specStrength => 'Force';

  @override
  String get specNutrition => 'Nutrition';

  @override
  String get specRecomp => 'Recomposition corporelle';

  @override
  String get specGeneralFitness => 'Forme générale';

  @override
  String get specEndurance => 'Endurance';

  @override
  String get specMobility => 'Mobilité et rééducation';

  @override
  String get expJustStarting => 'Je débute';

  @override
  String get expJustStartingHint => 'Nouveau dans le coaching';

  @override
  String get expOneToThree => '1–3 ans';

  @override
  String get expOneToThreeHint => 'Je développe ma clientèle';

  @override
  String get expThreeToFive => '3–5 ans';

  @override
  String get expThreeToFiveHint => 'Coach établi';

  @override
  String get expFivePlus => 'Plus de 5 ans';

  @override
  String get expFivePlusHint => 'Pro chevronné';

  @override
  String get rosterSolo => 'Juste moi, pas encore de clients';

  @override
  String get rosterSmall => '1–10 clients';

  @override
  String get rosterGrowing => '11–25 clients';

  @override
  String get rosterEstablished => 'Plus de 25 clients';

  @override
  String get priorWhatsapp => 'WhatsApp et messagerie';

  @override
  String get priorSpreadsheets => 'Tableurs';

  @override
  String get priorOtherApp => 'Une autre app de coaching';

  @override
  String get priorPenPaper => 'Papier et crayon';

  @override
  String get priorMix => 'Un peu de tout';

  @override
  String get coachIntakeSaveError =>
      'Impossible d\'enregistrer votre profil. Veuillez réessayer.';

  @override
  String get ciSpecialtiesTitle => 'Quelle est votre spécialité ?';

  @override
  String get ciSpecialtiesSubtitle =>
      'Sélectionnez tout ce qui s\'applique — cela façonne votre profil.';

  @override
  String get ciExperienceTitle => 'Depuis combien de temps coachez-vous ?';

  @override
  String get ciExperienceSubtitle =>
      'Pour adapter l\'expérience à votre profil.';

  @override
  String get ciRosterTitle => 'Combien de clients aujourd\'hui ?';

  @override
  String get ciRosterSubtitle =>
      'Approximativement — juste pour cerner votre échelle.';

  @override
  String get ciPriorTitle => 'Comment gérez-vous tout aujourd\'hui ?';

  @override
  String get ciPriorSubtitle => 'Nous vous aiderons à remplacer le chaos.';

  @override
  String get ciAnalyzing1 => 'Configuration de votre studio';

  @override
  String get ciAnalyzing2 => 'Préparation de votre tableau de bord';

  @override
  String get ciAnalyzing3 => 'Personnalisation selon vos spécialités';

  @override
  String get ciAnalyzing4 => 'Presque prêt';

  @override
  String get ciSettingUp => 'Configuration en cours';

  @override
  String get ciAllSet => 'Tout est prêt';

  @override
  String ciWelcomeName(String name) {
    return 'Bienvenue, $name';
  }

  @override
  String get ciStudioReady =>
      'Votre studio de coaching est prêt. Invitez votre premier client pour commencer.';

  @override
  String get ciYourFocus => 'Votre domaine';

  @override
  String get enterValence => 'Entrer dans Valence';

  @override
  String get settingsDisplayName => 'Nom affiché';

  @override
  String get settingsEnterName => 'Saisissez votre nom';

  @override
  String get profileUpdated => 'Profil mis à jour';

  @override
  String get profileUpdateError =>
      'Impossible de mettre à jour le profil pour le moment';

  @override
  String get settingsSaved => 'Paramètres enregistrés';

  @override
  String get settingsSaveError => 'Impossible d\'enregistrer les paramètres';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String changePasswordMsg(String email) {
    return 'Nous enverrons un lien de réinitialisation sécurisé à $email. Ouvrez-le pour définir un nouveau mot de passe.';
  }

  @override
  String get sendLink => 'Envoyer le lien';

  @override
  String get helpSupport => 'Aide et assistance';

  @override
  String supportBody(String role) {
    return 'Pour toute assistance compte ou application, contactez support@valence.app.\n\nIndiquez votre rôle ($role) et un bref résumé du problème.';
  }

  @override
  String get copyEmail => 'Copier l\'e-mail';

  @override
  String get supportEmailCopied => 'E-mail d\'assistance copié';

  @override
  String get aboutValence => 'À propos de Valence';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutTaglineClient =>
      'Suivez vos repas, vos séances et vos habitudes — et restez responsable avec votre coach, chaque jour.';

  @override
  String get myCoach => 'Mon coach';

  @override
  String get coachLinkedLabel => 'Associé à votre compte';

  @override
  String get coachNotLinked => 'Pas encore associé';

  @override
  String get connect => 'Associer';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get darkModeSubtitle => 'Changer l\'apparence de l\'app';

  @override
  String get mealReminders => 'Rappels de repas';

  @override
  String get mealRemindersSubtitle => 'Me rappeler d\'enregistrer mes repas';

  @override
  String get metricUnits => 'Unités métriques (kg)';

  @override
  String get metricUnitsSubtitle =>
      'Afficher le poids en kilogrammes ou en livres';

  @override
  String get logoutConfirmTitle => 'Se déconnecter ?';

  @override
  String get logoutConfirmMsg => 'Vous devrez vous reconnecter pour continuer.';

  @override
  String get sectionAccount => 'COMPTE';

  @override
  String get sectionSupport => 'ASSISTANCE';

  @override
  String get badgeMember => 'MEMBRE';

  @override
  String get badgeCoach => 'COACH';

  @override
  String get inviteAClient => 'Inviter un client';

  @override
  String get coachSupportTitle => 'Assistance coach';

  @override
  String get coachSupportBody =>
      'Pour la facturation, la gestion des clients ou l\'assistance technique :\nsupport@valence.app';

  @override
  String get aboutTaglineCoach =>
      'La plateforme de suivi qui garde les coachs et leurs clients synchronisés — chaque jour.';

  @override
  String get planLabel => 'Forfait';

  @override
  String get planFree => 'Gratuit';

  @override
  String get planPro => 'Pro';

  @override
  String get planStudio => 'Élite';

  @override
  String clientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clients',
      one: '1 client',
    );
    return '$_temp0';
  }

  @override
  String get clientActivityAlerts => 'Alertes d\'activité des clients';

  @override
  String get clientActivityAlertsSubtitle =>
      'Soyez notifié quand un client enregistre';

  @override
  String get inviteGenerateError =>
      'Impossible de générer le code d\'invitation';

  @override
  String get inviteCodeCopied => 'Code d\'invitation copié';

  @override
  String get inviteLinkCopied => 'Lien d\'invitation copié';

  @override
  String get inviteSheetSubtitle => 'Ajoutez quelqu\'un à votre liste';

  @override
  String get inviteSheetBody =>
      'Générez un code à usage unique (valable 7 jours) et partagez-le. Votre client le saisit à l\'inscription — un code par client, sans partage excessif.';

  @override
  String get inviteNoCode => 'Pas encore de code — générez-en un ci-dessous';

  @override
  String get generating => 'Génération…';

  @override
  String get generateCode => 'Générer un code';

  @override
  String get newCode => 'Nouveau code';

  @override
  String get copyCode => 'Copier le code';

  @override
  String get copyLink => 'Copier le lien';

  @override
  String get workoutComplete => 'Terminé';

  @override
  String get todaysWorkout => 'Séance du jour';

  @override
  String get pctDone => '% effectué';

  @override
  String workoutExercisesSets(int exercises, int done, int total) {
    return '$exercises exercices · $done sur $total séries';
  }

  @override
  String get markComplete => 'Terminer la séance';

  @override
  String get markNotDone => 'Annuler la validation';

  @override
  String get pastWorkoutViewOnly => 'Séance passée — lecture seule';

  @override
  String exerciseSetsTarget(int done, int sets, int reps) {
    return '$done/$sets séries · objectif $reps reps';
  }

  @override
  String get completeAllSets => 'Terminer toutes les séries';

  @override
  String get resetExercise => 'Réinitialiser l\'exercice';

  @override
  String setNumberLabel(int n) {
    return 'Série $n';
  }

  @override
  String get logged => 'Enregistré';

  @override
  String get tapToLog => 'Appuyer pour enregistrer';

  @override
  String get repsLabel => 'Reps';

  @override
  String get enterValidWeight => 'Saisissez un poids valide';

  @override
  String get restDay => 'Jour de repos';

  @override
  String get restDayTodayBody =>
      'Aucune séance prévue aujourd\'hui. Profitez de la récupération — ou consultez un autre jour.';

  @override
  String get restDayPastBody =>
      'Aucune séance n\'a été attribuée pour ce jour.';

  @override
  String get logWeightTitle => 'Enregistrer le poids';

  @override
  String get enterWeightHint => 'Saisissez votre poids';

  @override
  String get noteSentToCoach => 'Note envoyée au coach';

  @override
  String get noLogForDay => 'Aucun journal pour ce jour';

  @override
  String get noteSaveFailed => 'Échec de l\'enregistrement de la note';

  @override
  String get editMeal => 'Modifier le repas';

  @override
  String get mealName => 'Nom du repas';

  @override
  String get caloriesLabel => 'Calories';

  @override
  String get proteinG => 'Protéines (g)';

  @override
  String get carbsG => 'Glucides (g)';

  @override
  String get fatG => 'Lipides (g)';

  @override
  String get invalidMacros => 'Veuillez saisir des valeurs de macros valides';

  @override
  String get mealUpdated => 'Repas mis à jour';

  @override
  String get deleteMealTitle => 'Supprimer le repas ?';

  @override
  String deleteMealMsg(String meal) {
    return 'Retirer « $meal » de l\'historique d\'aujourd\'hui ?';
  }

  @override
  String get mealDeleted => 'Repas supprimé';

  @override
  String get noteOnlyToday =>
      'Vous ne pouvez laisser une note que pour aujourd\'hui';

  @override
  String get hi => 'Salut,';

  @override
  String get noteButton => 'Note';

  @override
  String get todaysCheckIn => 'Bilan du jour';

  @override
  String get noteToCoach => 'Note au coach';

  @override
  String get noteToCoachBody =>
      'Dites à votre coach comment s\'est passée la journée — énergie, courbatures, envies, tout. Il la voit avec votre journal.';

  @override
  String get noteToCoachHint =>
      'ex. « En forme aujourd\'hui, dormi 8 h, baisse d\'énergie après le déjeuner… »';

  @override
  String get sendToCoach => 'Envoyer au coach';

  @override
  String get viewingPastDay => 'Jour passé — lecture seule';

  @override
  String get dailyWinCopied => 'Victoire du jour copiée à partager';

  @override
  String get shareDailyWin => 'Partager la victoire du jour';

  @override
  String get dailyHabits => 'Habitudes quotidiennes';

  @override
  String get yourHabits => 'Vos habitudes';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get waterLabel => 'Eau';

  @override
  String get weightLabel => 'Poids';

  @override
  String get sleepQuality => 'Qualité du sommeil';

  @override
  String get howRested => 'À quel point vous sentez-vous reposé aujourd\'hui ?';

  @override
  String get todaysMeals => 'Repas du jour';

  @override
  String get logMeal => 'Enregistrer un repas';

  @override
  String get logNow => 'Enregistrer';

  @override
  String get confHigh => 'Élevée';

  @override
  String get confMedium => 'Moyenne';

  @override
  String get confLow => 'Faible';

  @override
  String get confManual => 'Manuel';

  @override
  String get deleteMeal => 'Supprimer le repas';

  @override
  String get aiCameraError =>
      'Impossible d\'accéder à la caméra ou à la galerie.';

  @override
  String get describeMealFirst => 'Décrivez d\'abord votre repas.';

  @override
  String get noResultFromAI => 'Aucun résultat de l\'IA.';

  @override
  String get fillMealAndMacros =>
      'Veuillez renseigner le nom du repas et tous les macros.';

  @override
  String mealPhotoUploadFailed(String error) {
    return 'Échec de l\'envoi de la photo : $error';
  }

  @override
  String get failedToSaveMeal => 'Échec de l\'enregistrement du repas.';

  @override
  String get readByValenceAI => 'Lu par Valence AI';

  @override
  String get manualEntry => 'Saisie manuelle';

  @override
  String get yourMeal => 'Votre repas';

  @override
  String get newMeal => 'Nouveau repas';

  @override
  String get whatTheAiSaw => 'Ce que l\'IA a vu';

  @override
  String get adjust => 'Ajuster';

  @override
  String get startOver => 'Recommencer';

  @override
  String get logAMeal => 'Enregistrer un repas';

  @override
  String get snapItLogged => 'Photographiez. Enregistré.';

  @override
  String get aiReadsPlate =>
      'Valence AI lit votre assiette en quelques secondes.';

  @override
  String get scanAMeal => 'Scanner un repas';

  @override
  String get tapToOpenCamera => 'Appuyez pour ouvrir la caméra';

  @override
  String get chooseFromGallery => 'Choisir dans la galerie';

  @override
  String get describeMealHint => 'ex. « 2 œufs, toast beurré, jus d\'orange »';

  @override
  String get describeYourMeal => 'Décrivez votre repas';

  @override
  String get analyzeWithAI => 'Analyser avec l\'IA';

  @override
  String get enterMacrosManually => 'Saisir les macros manuellement';

  @override
  String get orDivider => 'ou';

  @override
  String get readingYourPlate => 'Lecture de votre assiette…';

  @override
  String get aiStatus1 => 'Identification de vos aliments';

  @override
  String get aiStatus2 => 'Estimation des portions';

  @override
  String get aiStatus3 => 'Calcul des macros';

  @override
  String get aiStatus4 => 'Presque fini';

  @override
  String get scoreLabel => 'Score';

  @override
  String get mealBreakfast => 'Petit-déjeuner';

  @override
  String get mealLunch => 'Déjeuner';

  @override
  String get mealSnack => 'Collation';

  @override
  String get mealDinner => 'Dîner';

  @override
  String get noProgressData => 'Pas encore de données de progression.';

  @override
  String chartCaloriesSubtitle(String avg, String target) {
    return 'Moy. $avg kcal • Objectif $target';
  }

  @override
  String get weightTrendHint =>
      'Ajoutez des pesées quotidiennes pour voir la tendance';

  @override
  String get habitsScore => 'Score d\'habitudes';

  @override
  String chartHabitsSubtitle(String water, String sleep) {
    return 'Eau moy. $water L • Sommeil moy. $sleep/5';
  }

  @override
  String get notEnoughData => 'Données insuffisantes';

  @override
  String get chartWeekly => 'Semaine';

  @override
  String get chartMonthly => 'Mois';

  @override
  String get chartYearly => 'Année';

  @override
  String get progressLoadError =>
      'Impossible de charger la progression pour le moment.';

  @override
  String get greetingMorning => 'Bonjour';

  @override
  String get greetingAfternoon => 'Bon après-midi';

  @override
  String get greetingEvening => 'Bonsoir';

  @override
  String get statusGood => 'Bon';

  @override
  String get statusWatch => 'À surveiller';

  @override
  String get statusAlert => 'Alerte';

  @override
  String get statusSetup => 'Config.';

  @override
  String get removeClientTitle => 'Retirer le client ?';

  @override
  String removeClientMsg(String name) {
    return 'Cela retire $name de votre liste, supprime ses données et programme la suppression de son compte.';
  }

  @override
  String clientRemoved(String name) {
    return '$name retiré ; suppression du compte en file';
  }

  @override
  String get removeClientError =>
      'Impossible de retirer le client pour le moment';

  @override
  String get viewDetails => 'Voir les détails';

  @override
  String get configurePlan => 'Configurer le plan';

  @override
  String get editMacros => 'Modifier les macros';

  @override
  String get removeClient => 'Retirer le client';

  @override
  String get loadClientsError => 'Impossible de charger les clients';

  @override
  String get checkConnection => 'Vérifiez votre connexion et réessayez.';

  @override
  String get coachWord => 'Coach';

  @override
  String get sortedByRisk => 'Trié par risque';

  @override
  String get noClientsYet => 'Pas encore de clients';

  @override
  String get noClientsBody =>
      'Partagez un code d\'invitation depuis l\'onglet Profil pour intégrer votre premier client.';

  @override
  String noClientsMatch(String query) {
    return 'Aucun client ne correspond à « $query ».';
  }

  @override
  String get noClientsInGroup => 'Personne dans ce groupe pour l\'instant.';

  @override
  String get rosterHealth => 'Santé de la liste';

  @override
  String get allOnTrack => 'Tous sur la bonne voie';

  @override
  String needsYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ont besoin de vous',
      one: '1 a besoin de vous',
    );
    return '$_temp0';
  }

  @override
  String get searchClients => 'Rechercher des clients';

  @override
  String get filterAll => 'Tous';

  @override
  String get last7Days => '7 derniers jours';

  @override
  String get metricFood => 'Alim.';

  @override
  String get metricHabits => 'Habitudes';

  @override
  String get metricTraining => 'Séances';

  @override
  String get awaitingLogs => 'En attente de journaux récents';

  @override
  String get setupMacrosPlan => 'Configurez macros et plan pour activer';

  @override
  String get noLogsYet => 'Aucun journal';

  @override
  String lastLogOn(String date) {
    return 'Dernier journal · $date';
  }

  @override
  String get loggedToday => 'Enregistré aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String daysAgo(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Il y a $days jours',
      one: 'Il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get deleteTemplateTitle => 'Supprimer le modèle ?';

  @override
  String deleteTemplateMsg(String name) {
    return 'Cela supprime définitivement « $name » de votre bibliothèque. Les séances déjà attribuées aux clients restent intactes.';
  }

  @override
  String get templateDeleted => 'Modèle supprimé';

  @override
  String get deleteTemplateError =>
      'Impossible de supprimer le modèle. Réessayez.';

  @override
  String get noClientsToAssign => 'Aucun client à qui attribuer';

  @override
  String assignedDays(int count, String name) {
    return '$count jours attribués à $name';
  }

  @override
  String assignedToName(String name) {
    return 'Attribué à $name';
  }

  @override
  String get assignError =>
      'Impossible d\'attribuer pour le moment. Réessayez.';

  @override
  String noTemplatesMatch(String query) {
    return 'Aucun modèle ne correspond à « $query ».';
  }

  @override
  String get yourLibrary => 'Votre bibliothèque';

  @override
  String get workoutPlansTitle => 'Plans d\'entraînement';

  @override
  String get workoutPlanLabel => 'Plan d\'entraînement';

  @override
  String get statExercises => 'Exercices';

  @override
  String get statSets => 'Séries';

  @override
  String get statReps => 'Répétitions';

  @override
  String get editTemplate => 'Modifier le modèle';

  @override
  String get deleteTemplate => 'Supprimer le modèle';

  @override
  String get assign => 'Attribuer';

  @override
  String get newTemplate => 'Nouveau modèle';

  @override
  String get buildFirstPlan => 'Créez votre premier plan';

  @override
  String get buildFirstPlanBody =>
      'Créez une séance réutilisable une fois, puis attribuez-la à n\'importe quel client en quelques secondes.';

  @override
  String get createTemplate => 'Créer un modèle';

  @override
  String get searchTemplates => 'Rechercher des modèles';

  @override
  String get enterValidWeightBlank =>
      'Saisissez un poids valide, ou laissez vide';

  @override
  String get giveTemplateName => 'Donnez un nom à votre modèle';

  @override
  String get addAtLeastOneExercise => 'Ajoutez au moins un exercice';

  @override
  String get templateUpdated => 'Modèle mis à jour';

  @override
  String get templateCreated => 'Modèle créé';

  @override
  String get couldNotSaveNow => 'Impossible d\'enregistrer pour le moment';

  @override
  String get templateNameLabel => 'Nom du modèle';

  @override
  String get templateNameHint => 'ex. Haut du corps · Poussée';

  @override
  String get saveChanges => 'Enregistrer';

  @override
  String get newLabel => 'Nouveau';

  @override
  String get workoutTemplateTitle => 'Modèle de séance';

  @override
  String get exerciseNameHint => 'Nom de l\'exercice';

  @override
  String get targetWeightOptional => 'Poids cible · facultatif';

  @override
  String get addExercise => 'Ajouter un exercice';

  @override
  String get assignWorkout => 'Attribuer la séance';

  @override
  String get whenLabel => 'Quand';

  @override
  String get todayLabel => 'Aujourd\'hui';

  @override
  String get tomorrowLabel => 'Demain';

  @override
  String get pickLabel => 'Choisir…';

  @override
  String get repeatLabel => 'Répéter';

  @override
  String get justOnce => 'Une seule fois';

  @override
  String get weeklyLabel => 'Hebdomadaire';

  @override
  String assignNWorkouts(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Attribuer $count séances',
      one: 'Attribuer 1 séance',
    );
    return '$_temp0';
  }

  @override
  String get assignWorkoutBtn => 'Attribuer la séance';

  @override
  String get durationLabel => 'Durée';

  @override
  String get noDaysInRange =>
      'Aucun jour dans la plage — ajoutez une semaine ou choisissez un jour ultérieur';

  @override
  String schedulesDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Programme $count jours d\'entraînement',
      one: 'Programme 1 jour d\'entraînement',
    );
    return '$_temp0';
  }

  @override
  String weekDuration(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines',
      one: '1 semaine',
    );
    return '$_temp0';
  }

  @override
  String get sleepPoor => 'Mauvais';

  @override
  String get sleepFair => 'Correct';

  @override
  String get sleepGreat => 'Excellent';

  @override
  String get sleepLabel => 'Sommeil';

  @override
  String get noteSaved => 'Note enregistrée';

  @override
  String get macroTargets => 'Objectifs de macros';

  @override
  String dailyGoalsName(String name) {
    return 'Objectifs quotidiens · $name';
  }

  @override
  String get saveTargets => 'Enregistrer les objectifs';

  @override
  String get enterValidMacros => 'Saisissez des valeurs de macros valides';

  @override
  String get macrosMustBePositive =>
      'Toutes les valeurs de macros doivent être supérieures à 0';

  @override
  String get macroTargetsUpdated => 'Objectifs de macros mis à jour';

  @override
  String get failedSaveMacros => 'Échec de l\'enregistrement des macros';

  @override
  String get clientDetailsTitle => 'Détails du client';

  @override
  String get loadClientError =>
      'Impossible de charger ce client pour le moment.';

  @override
  String get loadDayError => 'Impossible de charger les données de ce jour.';

  @override
  String get tabAnalytics => 'Analyses';

  @override
  String get tabPlan => 'Plan';

  @override
  String get nutritionSummary => 'Résumé nutritionnel';

  @override
  String get editTargets => 'Modifier les objectifs';

  @override
  String get workoutLabel => 'Séance';

  @override
  String get swapWorkout => 'Changer la séance';

  @override
  String get coachNoteLabel => 'Note du coach';

  @override
  String ofTarget(String target) {
    return 'sur $target';
  }

  @override
  String get noMealsLogged => 'Aucun repas enregistré pour ce jour.';

  @override
  String get noWorkoutAssignedLib =>
      'Aucune séance attribuée pour ce jour.\nAttribuez-en une depuis l\'onglet Bibliothèque.';

  @override
  String get inProgress => 'En cours';

  @override
  String pendingTarget(int reps) {
    return 'en attente · objectif $reps';
  }

  @override
  String get clientCheckIn => 'Bilan du client';

  @override
  String get noCheckInNote => 'Aucune note de bilan pour ce jour.';

  @override
  String get loadAnalyticsError => 'Impossible de charger les analyses.';

  @override
  String get noCoachLinked => 'Ce client n\'a pas de coach associé.';

  @override
  String get noLibraryWorkouts =>
      'Aucune séance dans votre bibliothèque — créez-en une dans l\'onglet Bibliothèque.';

  @override
  String workoutAssignedName(String name) {
    return 'Séance attribuée · $name';
  }

  @override
  String get assignWorkoutErr =>
      'Impossible d\'attribuer la séance. Réessayez.';

  @override
  String get updateWorkout => 'Mettre à jour la séance';

  @override
  String get workoutTitleLabel => 'Titre de la séance';

  @override
  String exerciseNumber(int n) {
    return 'Exercice $n';
  }

  @override
  String get targetWeightLabel => 'Poids cible';

  @override
  String get saveWorkout => 'Enregistrer la séance';

  @override
  String get workoutTitleRequired =>
      'Le titre de la séance et les exercices sont requis';

  @override
  String get workoutUpdated => 'Séance mise à jour';

  @override
  String get updateWorkoutError =>
      'Impossible de mettre à jour la séance. Réessayez.';

  @override
  String get removeWorkoutTitle => 'Retirer la séance ?';

  @override
  String get removeWorkoutMsg =>
      'Cela efface la séance attribuée pour ce jour. Votre modèle de bibliothèque reste intact.';

  @override
  String get workoutRemoved => 'Séance retirée';

  @override
  String get removeWorkoutError =>
      'Impossible de retirer la séance. Réessayez.';

  @override
  String get noCustomHabitsBody =>
      'Pas encore d\'habitudes personnalisées. Ajoutez des éléments comme les pas, les compléments ou une marche quotidienne — ils apparaissent sur l\'accueil du client, en plus de l\'eau, du sommeil et du poids.';

  @override
  String get addHabits => 'Ajouter des habitudes';

  @override
  String get manageHabits => 'Gérer les habitudes';

  @override
  String get habitsUpdated => 'Habitudes mises à jour';

  @override
  String get saveHabitsError => 'Impossible d\'enregistrer les habitudes';

  @override
  String get configureMacros => 'Configurer les macros';

  @override
  String get updateMacros => 'Mettre à jour les macros';

  @override
  String get savingMacrosConfigures =>
      'Enregistrer les macros marque ce client comme configuré.';

  @override
  String workoutLogTitle(String date) {
    return 'Journal de séance ($date)';
  }

  @override
  String get noWorkoutSelectedDay =>
      'Aucune séance attribuée pour le jour sélectionné.';

  @override
  String get updateBtn => 'Mettre à jour';

  @override
  String get yourNote => 'Votre note';

  @override
  String get leaveANote => 'Laisser une note';

  @override
  String get savedLabel => 'Enregistré';

  @override
  String writeFeedbackFor(String name) {
    return 'Écrivez un retour pour $name…';
  }

  @override
  String get editingPastDay => 'Modification d\'un jour passé';

  @override
  String get updateNote => 'Mettre à jour la note';

  @override
  String get saveNote => 'Enregistrer la note';

  @override
  String get relToday => 'aujourd\'hui';

  @override
  String get relTomorrow => 'demain';

  @override
  String get relYesterday => 'hier';

  @override
  String forClientDate(String name, String date) {
    return 'Pour $name · $date';
  }

  @override
  String get chooseAWorkout => 'Choisissez une séance';

  @override
  String get includesLabel => 'Comprend';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercices',
      one: '1 exercice',
    );
    return '$_temp0';
  }

  @override
  String get habitsManagerBody =>
      'Habitudes que ce client coche chaque jour, en plus de l\'eau, du sommeil et du poids.';

  @override
  String get addAHabit => 'Ajouter une habitude';

  @override
  String get habitNameHint => 'ex. 10 000 pas';

  @override
  String get saveHabits => 'Enregistrer les habitudes';

  @override
  String get plansTitle => 'Forfaits';

  @override
  String get plansSubtitle => 'Choisissez le forfait adapté à votre clientèle';

  @override
  String get planCurrent => 'Forfait actuel';

  @override
  String get planMostPopular => 'Le plus populaire';

  @override
  String get planPerMonth => '/mois';

  @override
  String planChoose(String plan) {
    return 'Choisir $plan';
  }

  @override
  String planClientsUpTo(int count) {
    return 'Jusqu\'à $count clients';
  }

  @override
  String get planClientsUnlimited => 'Clients illimités';

  @override
  String planUsageLimited(int used, int total) {
    return '$used / $total clients';
  }

  @override
  String get planFreeTagline => 'Démarrez avec quelques clients';

  @override
  String get planProTagline => 'Pour les coachs en croissance';

  @override
  String get planStudioTagline => 'Pour les coachs établis, sans limites';

  @override
  String get featureMonitoring => 'Suivi quotidien des clients';

  @override
  String get featureWorkoutLibrary =>
      'Bibliothèque d\'entraînements et programmation';

  @override
  String get featureAiMeal => 'Scan des repas par IA inclus';

  @override
  String get featureRecurring => 'Programmation hebdomadaire récurrente';

  @override
  String get featureCustomHabits => 'Suivi d\'habitudes personnalisées';

  @override
  String get featureAnalytics => 'Analyses de progression';

  @override
  String get featurePrioritySupport => 'Support prioritaire';

  @override
  String get featureEverythingFree => 'Tout ce qu\'inclut Gratuit';

  @override
  String get featureEverythingPro => 'Tout ce qu\'inclut Pro';

  @override
  String get upgradeContactTitle => 'Passer au forfait supérieur';

  @override
  String upgradeContactBody(String plan) {
    return 'Le paiement en ligne arrive bientôt. Contactez-nous et nous activerons votre forfait $plan immédiatement.';
  }

  @override
  String get contactUs => 'Nous contacter';

  @override
  String get clientLimitTitle => 'Limite de clients atteinte';

  @override
  String clientLimitBody(int count) {
    return 'Vous avez atteint la limite de $count clients de votre forfait. Passez au forfait supérieur pour en ajouter.';
  }

  @override
  String get viewPlans => 'Voir les forfaits';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountWarning =>
      'Cela efface définitivement votre compte et toutes vos données. Cette action est irréversible.';

  @override
  String get deleteAccountConfirmPassword =>
      'Saisissez votre mot de passe pour confirmer';

  @override
  String get reminderTitle => 'C\'est l\'heure de votre bilan';

  @override
  String get reminderBody => 'Enregistrez vos repas et habitudes dans Valence.';

  @override
  String get reminderTimeLabel => 'Heure du rappel';

  @override
  String get remindersPermissionDenied =>
      'Activez les notifications dans les réglages de votre appareil pour recevoir les rappels.';

  @override
  String get onboardHookTitle => 'Mangez mieux, chaque jour.';

  @override
  String get onboardHookSubtitle =>
      'Photographiez votre repas et Valence calcule les calories et les macros — pendant que votre coach vous garde sur la bonne voie.';

  @override
  String get onboardBenefit1Title => 'Photographiez. On s\'occupe des calculs.';

  @override
  String get onboardBenefit1Body =>
      'Pointez votre caméra sur n\'importe quel repas — Valence estime les calories et les macros en quelques secondes. Sans base de données, sans deviner.';

  @override
  String get onboardBenefit2Title => 'Votre coach, à vos côtés.';

  @override
  String get onboardBenefit2Body =>
      'Votre coach suit vos progrès et ajuste votre plan — fini les captures d\'écran et les discussions éparpillées.';

  @override
  String get intakePriorTitle => 'Avez-vous déjà fait un suivi ?';

  @override
  String get intakePriorSubtitle =>
      'Sans jugement — cela nous aide juste à définir le bon rythme.';

  @override
  String get priorNever => 'Jamais';

  @override
  String get priorStopped => 'Essayé, sans tenir';

  @override
  String get priorCurrent => 'Je le fais déjà';

  @override
  String get onboardCommitTitle => 'Prêt à vous engager ?';

  @override
  String get onboardCommitSubtitle =>
      'Les petits suivis quotidiens s\'additionnent. Soyez présent pour vous-même, votre plan fera le reste.';

  @override
  String get onboardCommitCta => 'Je me lance';

  @override
  String get createAccountSavePlan =>
      'Créer un compte pour enregistrer mon plan';

  @override
  String get planGoalLabel => 'Votre objectif';

  @override
  String planReachBy(String weight, String date) {
    return 'Atteindre $weight d\'ici $date';
  }

  @override
  String get roleCoachDesc =>
      'Gérez vos clients, créez des plans, suivez les progrès de chacun.';

  @override
  String get roleClientDesc =>
      'Enregistrez vos repas avec l\'IA et suivez le plan de votre coach.';

  @override
  String get unitsMetric => 'Métrique';

  @override
  String get unitsImperial => 'Impérial';

  @override
  String get unitLb => 'lb';

  @override
  String weightToLoseU(String amount, String unit) {
    return '$amount $unit à perdre';
  }

  @override
  String weightToGainU(String amount, String unit) {
    return '$amount $unit à prendre';
  }

  @override
  String get intakeAgeInsight =>
      'Votre âge influence le nombre de calories brûlées au repos.';

  @override
  String get intakeHeightInsight =>
      'Votre taille se combine à votre poids pour estimer votre métabolisme.';

  @override
  String get intakeWeightInsight =>
      'C\'est votre point de départ — nous suivrons chaque étape à partir d\'ici.';

  @override
  String get intakeTargetInsight =>
      'Un rythme progressif est le moyen le plus durable d\'y arriver.';

  @override
  String get intakeActivityInsight =>
      'Définit votre dépense quotidienne avec la méthode Mifflin-St Jeor utilisée par les diététiciens.';

  @override
  String get ciSpecialtiesInsight =>
      'Nous adaptons les modèles et les conseils proposés à votre spécialité.';

  @override
  String get ciExperienceInsight =>
      'Cela définit des réglages par défaut adaptés — vous pourrez tout modifier plus tard.';

  @override
  String get ciRosterInsight =>
      'Valence évolue avec vous — commencez gratuitement avec vos 3 premiers clients.';

  @override
  String get ciPriorInsight =>
      'Nous vous aiderons à tout rassembler au même endroit.';

  @override
  String get purchaseSuccess => 'Mise à niveau effectuée — profitez-en !';

  @override
  String get purchaseFailed => 'L\'achat n\'a pas abouti. Réessayez.';

  @override
  String get restorePurchases => 'Restaurer les achats';

  @override
  String get authErrInviteRequired =>
      'Un code d\'invitation est requis pour vous inscrire';

  @override
  String get authErrInviteInvalid =>
      'Ce code d\'invitation est invalide, expiré ou déjà utilisé';

  @override
  String get authErrEmailInUse =>
      'Cet e-mail est déjà enregistré — essayez de vous connecter';

  @override
  String get authErrWeakPassword =>
      'Mot de passe trop faible — utilisez au moins 6 caractères';

  @override
  String get authErrInvalidEmail => 'Cette adresse e-mail n\'est pas valide';

  @override
  String get authErrWrongCredentials => 'E-mail ou mot de passe incorrect';

  @override
  String get authErrTooManyRequests =>
      'Trop de tentatives — patientez un instant puis réessayez';

  @override
  String get authErrNetwork =>
      'Erreur réseau — vérifiez votre connexion puis réessayez';

  @override
  String get authErrUserDataNotFound =>
      'Les données de votre compte sont introuvables';

  @override
  String get authErrNoEmailOnFile => 'Aucune adresse e-mail enregistrée';

  @override
  String get authErrNotLoggedIn => 'Vous devez être connecté';

  @override
  String get authErrClientsOnly =>
      'Seuls les comptes clients peuvent se lier à un coach';

  @override
  String get authErrLinkCoachFailed =>
      'Impossible de lier votre coach — réessayez';

  @override
  String get authErrIncorrectPassword => 'Mot de passe incorrect';

  @override
  String get authErrRecentLogin =>
      'Déconnectez-vous, reconnectez-vous, puis réessayez';

  @override
  String get authErrResetFailed =>
      'Impossible d\'envoyer l\'e-mail de réinitialisation';

  @override
  String get authErrSignupFailed =>
      'Impossible de créer votre compte — réessayez';

  @override
  String get authErrSigninFailed => 'Connexion impossible — réessayez';

  @override
  String get authErrDeleteFailed =>
      'Impossible de supprimer votre compte — réessayez';

  @override
  String get authErrUnknown => 'Une erreur est survenue — veuillez réessayer';

  @override
  String quietForDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours sans activité',
      one: '1 jour sans activité',
    );
    return '$_temp0';
  }

  @override
  String get perfectWeek => 'Semaine parfaite';

  @override
  String dayStreak(int days) {
    return 'Série de $days jours';
  }

  @override
  String get obMockClientName => 'Sara';

  @override
  String get obMockWorkoutTitle => 'Séance Push';

  @override
  String get obMockSetsDone => '2/3 faites';

  @override
  String get obMockEx1 => 'Développé couché';

  @override
  String get obMockEx2 => 'Développé incliné';

  @override
  String get obMockEx3 => 'Écarté à la poulie';

  @override
  String get obMockHabitWater => 'Eau · 3 L';

  @override
  String get obMockHabitSteps => '10 000 pas';

  @override
  String get obMockHabitSugar => 'Pas de sucre après 20 h';

  @override
  String get obMockNoteHeader => 'Note de votre coach';

  @override
  String get obMockNoteBody =>
      'Belle semaine, Sara. Tes protéines sont parfaites — ajoute une marche ce week-end et c\'est impeccable.';

  @override
  String get statusNew => 'Nouveau';

  @override
  String get joinedRecently =>
      'Vient de rejoindre — en attente du premier journal';

  @override
  String consistencyThisWeek(int pct) {
    return '$pct % de régularité cette semaine';
  }

  @override
  String get coverStatement1 => 'Chaque repas, compris.';

  @override
  String get coverStatement2 => 'Tout votre suivi, d\'un coup d\'œil.';

  @override
  String get coverRolePrompt => 'Comment allez-vous utiliser Valence ?';

  @override
  String get welcomeTitle => 'Bienvenue sur Valence';

  @override
  String get clientIntroTitle => 'Votre coach, dans votre poche';

  @override
  String get coachIntroTitle => 'Tout votre coaching, au même endroit';

  @override
  String get introSubtitle => 'Voici comment Valence fonctionne pour vous.';

  @override
  String get roleAthlete => 'Athlète';

  @override
  String get clientIntroCta => 'Créer mon plan';

  @override
  String get coachIntroCta => 'Configurer mon profil';

  @override
  String get coachSetupReady =>
      'Votre espace de coaching est prêt. Invitez votre premier client pour commencer.';

  @override
  String get intakeBodyTitle => 'À propos de vous';

  @override
  String get intakeBodySubtitle =>
      'Quelques chiffres pour que votre plan vous corresponde.';

  @override
  String get intakeBodyInsight =>
      'Ils définissent vos objectifs quotidiens de calories et de macros.';

  @override
  String confidenceNote(String word, int score) {
    return 'Confiance $word ($score/100) — touchez Ajuster pour affiner.';
  }

  @override
  String get centerYourPlate => 'Centrez votre assiette';

  @override
  String get recentsLabel => 'Récents';

  @override
  String get portionLabel => 'Portion';

  @override
  String kcalLeftToday(int n) {
    return '$n kcal restantes aujourd’hui';
  }

  @override
  String kcalOverToday(int n) {
    return '$n kcal au-dessus aujourd’hui';
  }

  @override
  String get describeCardSub => 'Décrivez — l’IA fait le calcul';

  @override
  String get manualCardSub => 'Vous connaissez les chiffres ? Saisissez-les';

  @override
  String get flashLabel => 'Flash';

  @override
  String get galleryCardSub => 'Choisir une photo existante';

  @override
  String get scanCardSub => 'Visez, capturez — c’est noté';
}
