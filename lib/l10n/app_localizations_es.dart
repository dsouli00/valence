// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get landingSubtitle =>
      'Seguimiento diario entre entrenadores y sus clientes, diseñado para lograr resultados reales.';

  @override
  String get roleCoach => 'Entrenador';

  @override
  String get roleClient => 'Cliente';

  @override
  String get getStarted => 'Empezar';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get logIn => 'Iniciar sesión';

  @override
  String get signUp => 'Registrarse';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta?';

  @override
  String get dontHaveAccount => '¿No tienes una cuenta?';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get remove => 'Quitar';

  @override
  String get edit => 'Editar';

  @override
  String get add => 'Añadir';

  @override
  String get done => 'Listo';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get next => 'Siguiente';

  @override
  String get back => 'Atrás';

  @override
  String get close => 'Cerrar';

  @override
  String get search => 'Buscar';

  @override
  String get navToday => 'Hoy';

  @override
  String get navWorkouts => 'Entrenamientos';

  @override
  String get navProgress => 'Progreso';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navClients => 'Clientes';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get sectionPreferences => 'PREFERENCIAS';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Elige el idioma de la app';

  @override
  String get languageSystemDefault => 'Predeterminado del sistema';

  @override
  String get chooseLanguage => 'Elegir idioma';

  @override
  String get welcomeBackTitle => 'Bienvenido de nuevo';

  @override
  String get welcomeBackToast => '¡Bienvenido de nuevo!';

  @override
  String get loginSubtitle => 'Inicia sesión para continuar tu camino.';

  @override
  String get emailRequired => 'El correo electrónico es obligatorio';

  @override
  String get passwordRequired => 'La contraseña es obligatoria';

  @override
  String get emailHint => 'Introduce tu correo electrónico';

  @override
  String get passwordHint => 'Introduce tu contraseña';

  @override
  String get forgotPasswordEnterEmail =>
      'Introduce tu correo arriba y luego toca ¿Olvidaste tu contraseña?';

  @override
  String resetLinkSent(String email) {
    return 'Enlace de restablecimiento enviado a $email';
  }

  @override
  String get inviteLinkRequired => 'El enlace de invitación es obligatorio';

  @override
  String get accountCreated => 'Cuenta creada correctamente';

  @override
  String get joinValence => 'Únete a Valence';

  @override
  String signupSubtitle(String role) {
    return 'Crea tu cuenta premium de $role.';
  }

  @override
  String get inviteCode => 'Código de invitación';

  @override
  String get fullNameRequired => 'El nombre completo es obligatorio';

  @override
  String get fullNameHint => 'Introduce tu nombre completo';

  @override
  String get emailInvalid => 'Introduce una dirección de correo válida';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get passwordCreateHint => 'Crea una contraseña segura';

  @override
  String get logOut => 'Cerrar sesión';

  @override
  String get linkCoachTitle =>
      'Introduce el código de invitación del entrenador';

  @override
  String get linkCoachSubtitle =>
      'Debes vincular un entrenador antes de usar la app.';

  @override
  String get obClientLogTitle => 'Regístralo en segundos';

  @override
  String get obClientLogBody =>
      'Fotografía una comida, marca un hábito, registra una serie. La IA de Valence calcula las calorías por ti.';

  @override
  String get obClientHabitsTitle => 'Crea tus hábitos diarios';

  @override
  String get obClientHabitsBody =>
      'Agua, sueño, peso y los hábitos que fija tu entrenador, todo en una tranquila lista diaria.';

  @override
  String get obClientCoachTitle => 'Tu entrenador te respalda';

  @override
  String get obClientCoachBody =>
      'Ve tu progreso y te anima cuando importa. Nunca lo haces solo.';

  @override
  String get obCoachRosterTitle => 'Ve quién te necesita';

  @override
  String get obCoachRosterBody =>
      'Toda tu lista de un vistazo: quién va bien y quién flaquea, actualizado en cuanto un cliente registra.';

  @override
  String get obCoachProgramTitle => 'Programa una vez, sigue a diario';

  @override
  String get obCoachProgramBody =>
      'Crea entrenamientos y hábitos, asígnalos y observa cómo se completan: se acabaron WhatsApp y las hojas de cálculo.';

  @override
  String get obCoachGrowTitle => 'Crece sin agobios';

  @override
  String get obCoachGrowBody =>
      'Mantén el trato personal de 5 a 50 clientes. Valence se encarga del seguimiento para que tú entrenes.';

  @override
  String get intakeSaveError =>
      'No se pudo guardar tu plan. Inténtalo de nuevo.';

  @override
  String get intakeGoalTitle => '¿Cuál es tu objetivo?';

  @override
  String get intakeGoalSubtitle =>
      'Ajustaremos tus calorías diarias en consecuencia.';

  @override
  String get goalLoseTitle => 'Perder peso';

  @override
  String get goalLoseSubtitle => 'Pérdida de grasa gradual';

  @override
  String get goalMaintainTitle => 'Mantener';

  @override
  String get goalMaintainSubtitle => 'Quédate donde estás';

  @override
  String get goalGainTitle => 'Ganar músculo';

  @override
  String get goalGainSubtitle => 'Volumen limpio';

  @override
  String get intakeSexTitle => '¿Qué te describe mejor?';

  @override
  String get intakeSexSubtitle =>
      'El sexo biológico cambia el cálculo de calorías.';

  @override
  String get sexMale => 'Hombre';

  @override
  String get sexFemale => 'Mujer';

  @override
  String get intakeAgeTitle => '¿Cuántos años tienes?';

  @override
  String get intakeAgeSubtitle =>
      'Influye en tu metabolismo y tus necesidades calóricas.';

  @override
  String get unitYears => 'años';

  @override
  String get intakeHeightTitle => '¿Cuánto mides?';

  @override
  String get intakeHeightSubtitle => 'Se usa para estimar tu energía diaria.';

  @override
  String get unitCm => 'cm';

  @override
  String get intakeWeightTitle => '¿Tu peso actual?';

  @override
  String get intakeWeightSubtitle =>
      'Solo nuestro punto de partida: seguimos desde aquí.';

  @override
  String get unitKg => 'kg';

  @override
  String get intakeTargetTitle => '¿Tu peso objetivo?';

  @override
  String get intakeTargetSubtitle =>
      'Fija el destino: nosotros planificamos el camino.';

  @override
  String get intakeActivityTitle => '¿Qué tan activo eres?';

  @override
  String get intakeActivitySubtitle =>
      'Fuera de los entrenamientos planificados, en tu día a día.';

  @override
  String get intakeAnalyzing1 => 'Analizando tu metabolismo';

  @override
  String get intakeAnalyzing2 => 'Calculando tus calorías';

  @override
  String get intakeAnalyzing3 => 'Equilibrando tus macros';

  @override
  String get intakeAnalyzing4 => 'Finalizando tu plan';

  @override
  String get intakePlanReady => 'Tu plan está listo';

  @override
  String intakePlanReadyNamed(String name) {
    return '$name, tu plan está listo';
  }

  @override
  String get intakePlanSubtitle =>
      'Calculado automáticamente a partir de tus respuestas; tu entrenador puede ajustarlo cuando quiera.';

  @override
  String get dailyCalories => 'Calorías diarias';

  @override
  String get kcal => 'kcal';

  @override
  String get macroProtein => 'Proteínas';

  @override
  String get macroCarbs => 'Carbohidratos';

  @override
  String get macroFat => 'Grasas';

  @override
  String get startTracking => 'Empezar a registrar';

  @override
  String get deltaMaintain => 'Mantén tu peso';

  @override
  String get activitySedentary => 'Sedentario';

  @override
  String get activitySedentaryHint => 'Trabajo de oficina, poco ejercicio';

  @override
  String get activityLight => 'Ligeramente activo';

  @override
  String get activityLightHint => 'Ejercicio ligero 1–3 días/sem';

  @override
  String get activityModerate => 'Moderadamente activo';

  @override
  String get activityModerateHint => 'Ejercicio 3–5 días/sem';

  @override
  String get activityActive => 'Muy activo';

  @override
  String get activityActiveHint => 'Ejercicio intenso 6–7 días/sem';

  @override
  String get activityVeryActive => 'Atleta';

  @override
  String get activityVeryActiveHint => 'Entrenamiento dos veces al día';

  @override
  String get specWeightLoss => 'Pérdida de peso';

  @override
  String get specMuscleGain => 'Ganancia muscular';

  @override
  String get specStrength => 'Fuerza';

  @override
  String get specNutrition => 'Nutrición';

  @override
  String get specRecomp => 'Recomposición corporal';

  @override
  String get specGeneralFitness => 'Fitness general';

  @override
  String get specEndurance => 'Resistencia';

  @override
  String get specMobility => 'Movilidad y rehabilitación';

  @override
  String get expJustStarting => 'Recién empiezo';

  @override
  String get expJustStartingHint => 'Nuevo en el coaching';

  @override
  String get expOneToThree => '1–3 años';

  @override
  String get expOneToThreeHint => 'Construyendo mi cartera';

  @override
  String get expThreeToFive => '3–5 años';

  @override
  String get expThreeToFiveHint => 'Entrenador consolidado';

  @override
  String get expFivePlus => 'Más de 5 años';

  @override
  String get expFivePlusHint => 'Profesional experimentado';

  @override
  String get rosterSolo => 'Solo yo, aún sin clientes';

  @override
  String get rosterSmall => '1–10 clientes';

  @override
  String get rosterGrowing => '11–25 clientes';

  @override
  String get rosterEstablished => 'Más de 25 clientes';

  @override
  String get priorWhatsapp => 'WhatsApp y chat';

  @override
  String get priorSpreadsheets => 'Hojas de cálculo';

  @override
  String get priorOtherApp => 'Otra app de coaching';

  @override
  String get priorPenPaper => 'Papel y lápiz';

  @override
  String get priorMix => 'Un poco de todo';

  @override
  String get coachIntakeSaveError =>
      'No se pudo guardar tu perfil. Inténtalo de nuevo.';

  @override
  String get ciSpecialtiesTitle => '¿En qué te especializas?';

  @override
  String get ciSpecialtiesSubtitle =>
      'Elige todo lo que aplique: define tu perfil de coaching.';

  @override
  String get ciExperienceTitle => '¿Cuánto tiempo llevas entrenando?';

  @override
  String get ciExperienceSubtitle => 'Para adaptar la experiencia a ti.';

  @override
  String get ciRosterTitle => '¿Cuántos clientes tienes hoy?';

  @override
  String get ciRosterSubtitle =>
      'Aproximadamente, solo para entender tu escala.';

  @override
  String get ciPriorTitle => '¿Cómo gestionas todo ahora?';

  @override
  String get ciPriorSubtitle => 'Te ayudaremos a sustituir el caos.';

  @override
  String get ciAnalyzing1 => 'Configurando tu estudio';

  @override
  String get ciAnalyzing2 => 'Preparando tu panel';

  @override
  String get ciAnalyzing3 => 'Adaptando a tus especialidades';

  @override
  String get ciAnalyzing4 => 'Casi listo';

  @override
  String get ciAllSet => 'Todo listo';

  @override
  String ciWelcomeName(String name) {
    return 'Bienvenido, $name';
  }

  @override
  String get ciYourFocus => 'Tu enfoque';

  @override
  String get enterValence => 'Entrar en Valence';

  @override
  String get settingsDisplayName => 'Nombre visible';

  @override
  String get settingsEnterName => 'Introduce tu nombre';

  @override
  String get profileUpdated => 'Perfil actualizado';

  @override
  String get profileUpdateError => 'No se pudo actualizar el perfil ahora';

  @override
  String get settingsSaved => 'Ajustes guardados';

  @override
  String get settingsSaveError => 'No se pudieron guardar los ajustes';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String changePasswordMsg(String email) {
    return 'Enviaremos un enlace de restablecimiento seguro a $email. Ábrelo para crear una nueva contraseña.';
  }

  @override
  String get sendLink => 'Enviar enlace';

  @override
  String get helpSupport => 'Ayuda y soporte';

  @override
  String supportBody(String role) {
    return 'Para soporte de cuenta o de la app, escribe a support@valence.app.\n\nIncluye tu rol ($role) y un breve resumen del problema.';
  }

  @override
  String get copyEmail => 'Copiar correo';

  @override
  String get supportEmailCopied => 'Correo de soporte copiado';

  @override
  String get aboutValence => 'Acerca de Valence';

  @override
  String aboutVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get aboutTaglineClient =>
      'Registra tus comidas, entrenamientos y hábitos, y mantente comprometido con tu entrenador cada día.';

  @override
  String get myCoach => 'Mi entrenador';

  @override
  String get coachLinkedLabel => 'Vinculado a tu cuenta';

  @override
  String get coachNotLinked => 'Aún no vinculado';

  @override
  String get connect => 'Conectar';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get darkModeSubtitle => 'Cambia la apariencia de la app';

  @override
  String get mealReminders => 'Recordatorios de comidas';

  @override
  String get mealRemindersSubtitle => 'Recuérdame registrar mis comidas';

  @override
  String get metricUnits => 'Unidades métricas (kg)';

  @override
  String get metricUnitsSubtitle => 'Muestra el peso en kilogramos o libras';

  @override
  String get logoutConfirmTitle => '¿Cerrar sesión?';

  @override
  String get logoutConfirmMsg =>
      'Tendrás que iniciar sesión de nuevo para continuar.';

  @override
  String get sectionAccount => 'CUENTA';

  @override
  String get sectionSupport => 'SOPORTE';

  @override
  String get badgeMember => 'MIEMBRO';

  @override
  String get badgeCoach => 'ENTRENADOR';

  @override
  String get inviteAClient => 'Invitar a un cliente';

  @override
  String get coachSupportTitle => 'Soporte para entrenadores';

  @override
  String get coachSupportBody =>
      'Para facturación, gestión de clientes o soporte técnico:\nsupport@valence.app';

  @override
  String get aboutTaglineCoach =>
      'La plataforma de seguimiento que mantiene a entrenadores y clientes en sintonía, cada día.';

  @override
  String get planLabel => 'Plan';

  @override
  String get planFree => 'Gratis';

  @override
  String get planPro => 'Pro';

  @override
  String get planStudio => 'Élite';

  @override
  String clientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clientes',
      one: '1 cliente',
    );
    return '$_temp0';
  }

  @override
  String get clientActivityAlerts => 'Alertas de actividad de clientes';

  @override
  String get clientActivityAlertsSubtitle =>
      'Recibe avisos cuando un cliente registra';

  @override
  String get inviteGenerateError =>
      'No se pudo generar el código de invitación';

  @override
  String get inviteCodeCopied => 'Código de invitación copiado';

  @override
  String get inviteLinkCopied => 'Enlace de invitación copiado';

  @override
  String get inviteSheetSubtitle => 'Añade a alguien a tu lista';

  @override
  String get inviteSheetBody =>
      'Genera un código de un solo uso (válido 7 días) y compártelo. Tu cliente lo introduce al registrarse: un código por cliente, sin compartir de más.';

  @override
  String get inviteNoCode => 'Aún no hay código: genera uno abajo';

  @override
  String get generateCode => 'Generar código';

  @override
  String get newCode => 'Nuevo código';

  @override
  String get copyCode => 'Copiar código';

  @override
  String get copyLink => 'Copiar enlace';

  @override
  String get todaysWorkout => 'Entrenamiento de hoy';

  @override
  String workoutExercisesSets(int exercises, int done, int total) {
    return '$exercises ejercicios · $done de $total series';
  }

  @override
  String get markComplete => 'Finalizar entrenamiento';

  @override
  String get markNotDone => 'Marcar como no hecho';

  @override
  String get pastWorkoutViewOnly => 'Entrenamiento pasado: solo lectura';

  @override
  String exerciseSetsTarget(int done, int sets, int reps) {
    return '$done/$sets series · objetivo $reps reps';
  }

  @override
  String get completeAllSets => 'Completar todas las series';

  @override
  String get resetExercise => 'Reiniciar ejercicio';

  @override
  String setNumberLabel(int n) {
    return 'Serie $n';
  }

  @override
  String get logged => 'Registrado';

  @override
  String get tapToLog => 'Toca para registrar';

  @override
  String get repsLabel => 'Reps';

  @override
  String get enterValidWeight => 'Introduce un peso válido';

  @override
  String get restDay => 'Día de descanso';

  @override
  String get restDayTodayBody =>
      'No hay entrenamiento para hoy. Disfruta la recuperación o revisa otro día.';

  @override
  String get restDayPastBody =>
      'No se asignó ningún entrenamiento para este día.';

  @override
  String get logWeightTitle => 'Registrar peso';

  @override
  String get enterWeightHint => 'Introduce tu peso';

  @override
  String get noteSentToCoach => 'Nota enviada al entrenador';

  @override
  String get noLogForDay => 'Aún no hay registro de este día';

  @override
  String get noteSaveFailed => 'No se pudo guardar la nota';

  @override
  String get editMeal => 'Editar comida';

  @override
  String get mealName => 'Nombre de la comida';

  @override
  String get caloriesLabel => 'Calorías';

  @override
  String get proteinG => 'Proteínas (g)';

  @override
  String get carbsG => 'Carbohidratos (g)';

  @override
  String get fatG => 'Grasas (g)';

  @override
  String get invalidMacros => 'Introduce valores de macros válidos';

  @override
  String get mealUpdated => 'Comida actualizada';

  @override
  String get deleteMealTitle => '¿Eliminar comida?';

  @override
  String deleteMealMsg(String meal) {
    return '¿Quitar “$meal” del historial de hoy?';
  }

  @override
  String get mealDeleted => 'Comida eliminada';

  @override
  String get noteOnlyToday => 'Solo puedes dejar una nota para hoy';

  @override
  String get hi => 'Hola,';

  @override
  String get noteButton => 'Nota';

  @override
  String get todaysCheckIn => 'Registro de hoy';

  @override
  String get noteToCoachBody =>
      'Cuéntale a tu entrenador cómo fue el día: energía, agujetas, antojos, lo que sea. Lo verá junto a tu registro.';

  @override
  String get noteToCoachHint =>
      'p. ej. “Hoy me sentí fuerte, dormí 8 h, sin energía tras el almuerzo…”';

  @override
  String get sendToCoach => 'Enviar al entrenador';

  @override
  String get viewingPastDay => 'Viendo un día pasado: solo lectura';

  @override
  String get dailyWinCopied => 'Logro del día copiado para compartir';

  @override
  String get shareDailyWin => 'Compartir logro del día';

  @override
  String get dailyHabits => 'Hábitos diarios';

  @override
  String get yourHabits => 'Tus hábitos';

  @override
  String get waterLabel => 'Agua';

  @override
  String get weightLabel => 'Peso';

  @override
  String get sleepQuality => 'Calidad del sueño';

  @override
  String get howRested => '¿Qué tan descansado te sientes hoy?';

  @override
  String get todaysMeals => 'Comidas de hoy';

  @override
  String get logMeal => 'Registrar comida';

  @override
  String get logNow => 'Registrar ahora';

  @override
  String get confHigh => 'Alta';

  @override
  String get confMedium => 'Media';

  @override
  String get confLow => 'Baja';

  @override
  String get deleteMeal => 'Eliminar comida';

  @override
  String get aiCameraError => 'No se pudo acceder a la cámara o la galería.';

  @override
  String get describeMealFirst => 'Describe primero tu comida.';

  @override
  String get fillMealAndMacros =>
      'Completa el nombre de la comida y todos los macros.';

  @override
  String get failedToSaveMeal => 'No se pudo guardar la comida.';

  @override
  String get readByValenceAI => 'Leído por Valence AI';

  @override
  String get manualEntry => 'Entrada manual';

  @override
  String get yourMeal => 'Tu comida';

  @override
  String get newMeal => 'Nueva comida';

  @override
  String get whatTheAiSaw => 'Lo que vio la IA';

  @override
  String get adjust => 'Ajustar';

  @override
  String get startOver => 'Empezar de nuevo';

  @override
  String get logAMeal => 'Registrar una comida';

  @override
  String get snapItLogged => 'Fotografía. Registrado.';

  @override
  String get aiReadsPlate => 'Valence AI lee tu plato en segundos.';

  @override
  String get scanAMeal => 'Escanear una comida';

  @override
  String get chooseFromGallery => 'Elegir de la galería';

  @override
  String get describeMealHint =>
      'p. ej. “2 huevos, tostada con mantequilla, zumo de naranja”';

  @override
  String get describeYourMeal => 'Describe tu comida';

  @override
  String get analyzeWithAI => 'Analizar con IA';

  @override
  String get enterMacrosManually => 'Introducir macros manualmente';

  @override
  String get readingYourPlate => 'Leyendo tu plato…';

  @override
  String get aiStatus1 => 'Identificando tu comida';

  @override
  String get aiStatus2 => 'Estimando porciones';

  @override
  String get aiStatus3 => 'Calculando los macros';

  @override
  String get aiStatus4 => 'Casi listo';

  @override
  String get mealBreakfast => 'Desayuno';

  @override
  String get mealLunch => 'Almuerzo';

  @override
  String get mealSnack => 'Tentempié';

  @override
  String get mealDinner => 'Cena';

  @override
  String get noProgressData => 'Aún no hay datos de progreso.';

  @override
  String chartCaloriesSubtitle(String avg, String target) {
    return 'Prom. $avg kcal • Objetivo $target';
  }

  @override
  String get weightTrendHint => 'Añade pesajes diarios para ver la tendencia';

  @override
  String get habitsScore => 'Puntuación de hábitos';

  @override
  String chartHabitsSubtitle(String water, String sleep) {
    return 'Agua prom. $water L • Sueño prom. $sleep/5';
  }

  @override
  String get notEnoughData => 'Datos insuficientes';

  @override
  String get chartWeekly => 'Semana';

  @override
  String get chartMonthly => 'Mes';

  @override
  String get chartYearly => 'Año';

  @override
  String get progressLoadError => 'No se pudo cargar el progreso ahora.';

  @override
  String get statusGood => 'Bien';

  @override
  String get statusWatch => 'Atención';

  @override
  String get statusAlert => 'Alerta';

  @override
  String get statusSetup => 'Config.';

  @override
  String get removeClientTitle => '¿Quitar cliente?';

  @override
  String removeClientMsg(String name) {
    return 'Esto quita a $name de tu lista, elimina sus datos y pone en cola la eliminación de su cuenta.';
  }

  @override
  String clientRemoved(String name) {
    return '$name eliminado; eliminación de cuenta en cola';
  }

  @override
  String get removeClientError => 'No se pudo quitar el cliente ahora';

  @override
  String get viewDetails => 'Ver detalles';

  @override
  String get configurePlan => 'Configurar plan';

  @override
  String get editMacros => 'Editar macros';

  @override
  String get removeClient => 'Quitar cliente';

  @override
  String get loadClientsError => 'No se pudieron cargar los clientes';

  @override
  String get checkConnection => 'Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get coachWord => 'Entrenador';

  @override
  String get noClientsYet => 'Aún no hay clientes';

  @override
  String get noClientsBody =>
      'Comparte un código de invitación desde la pestaña Perfil para sumar a tu primer cliente.';

  @override
  String noClientsMatch(String query) {
    return 'Ningún cliente coincide con “$query”.';
  }

  @override
  String get noClientsInGroup => 'Nadie en este grupo ahora mismo.';

  @override
  String get allOnTrack => 'Todos al día';

  @override
  String needsYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count te necesitan',
      one: '1 te necesita',
    );
    return '$_temp0';
  }

  @override
  String get searchClients => 'Buscar clientes';

  @override
  String get filterAll => 'Todos';

  @override
  String get metricFood => 'Comida';

  @override
  String get metricHabits => 'Hábitos';

  @override
  String get metricTraining => 'Entren.';

  @override
  String get awaitingLogs => 'Esperando registros recientes';

  @override
  String get setupMacrosPlan => 'Configura macros y plan para activar';

  @override
  String get noLogsYet => 'Sin registros';

  @override
  String lastLogOn(String date) {
    return 'Último registro · $date';
  }

  @override
  String get loggedToday => 'Registrado hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String daysAgo(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Hace $days días',
      one: 'Hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get deleteTemplateTitle => '¿Eliminar plantilla?';

  @override
  String deleteTemplateMsg(String name) {
    return 'Esto elimina permanentemente “$name” de tu biblioteca. Los entrenamientos ya asignados a clientes se mantienen.';
  }

  @override
  String get templateDeleted => 'Plantilla eliminada';

  @override
  String get deleteTemplateError =>
      'No se pudo eliminar la plantilla. Inténtalo de nuevo.';

  @override
  String get noClientsToAssign => 'Aún no hay clientes para asignar';

  @override
  String assignedDays(int count, String name) {
    return '$count días asignados a $name';
  }

  @override
  String assignedToName(String name) {
    return 'Asignado a $name';
  }

  @override
  String get assignError => 'No se pudo asignar ahora. Inténtalo de nuevo.';

  @override
  String noTemplatesMatch(String query) {
    return 'Ninguna plantilla coincide con “$query”.';
  }

  @override
  String get workoutPlansTitle => 'Planes de entrenamiento';

  @override
  String get statExercises => 'Ejercicios';

  @override
  String get statSets => 'Series';

  @override
  String get statReps => 'Repeticiones';

  @override
  String get assign => 'Asignar';

  @override
  String get newTemplate => 'Nueva plantilla';

  @override
  String get buildFirstPlan => 'Crea tu primer plan';

  @override
  String get buildFirstPlanBody =>
      'Crea un entrenamiento reutilizable una vez y asígnalo a cualquier cliente en segundos.';

  @override
  String get createTemplate => 'Crear plantilla';

  @override
  String get searchTemplates => 'Buscar plantillas';

  @override
  String get enterValidWeightBlank =>
      'Introduce un peso válido o déjalo en blanco';

  @override
  String get giveTemplateName => 'Ponle un nombre a tu plantilla';

  @override
  String get addAtLeastOneExercise => 'Añade al menos un ejercicio';

  @override
  String get templateUpdated => 'Plantilla actualizada';

  @override
  String get templateCreated => 'Plantilla creada';

  @override
  String get couldNotSaveNow => 'No se pudo guardar ahora';

  @override
  String get templateNameLabel => 'Nombre de la plantilla';

  @override
  String get templateNameHint => 'p. ej. Tren superior · Empuje';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get newLabel => 'Nuevo';

  @override
  String get workoutTemplateTitle => 'Plantilla de entrenamiento';

  @override
  String get exerciseNameHint => 'Nombre del ejercicio';

  @override
  String get targetWeightOptional => 'Peso objetivo · opcional';

  @override
  String get addExercise => 'Añadir ejercicio';

  @override
  String get whenLabel => 'Cuándo';

  @override
  String get todayLabel => 'Hoy';

  @override
  String get tomorrowLabel => 'Mañana';

  @override
  String get pickLabel => 'Elegir…';

  @override
  String get repeatLabel => 'Repetir';

  @override
  String get justOnce => 'Solo una vez';

  @override
  String get weeklyLabel => 'Semanal';

  @override
  String assignNWorkouts(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Asignar $count entrenamientos',
      one: 'Asignar 1 entrenamiento',
    );
    return '$_temp0';
  }

  @override
  String get assignWorkoutBtn => 'Asignar entrenamiento';

  @override
  String get durationLabel => 'Duración';

  @override
  String get noDaysInRange =>
      'No hay días en el rango: añade una semana o elige un día posterior';

  @override
  String schedulesDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Programa $count días de entrenamiento',
      one: 'Programa 1 día de entrenamiento',
    );
    return '$_temp0';
  }

  @override
  String weekDuration(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semanas',
      one: '1 semana',
    );
    return '$_temp0';
  }

  @override
  String get sleepPoor => 'Malo';

  @override
  String get sleepFair => 'Regular';

  @override
  String get sleepGreat => 'Excelente';

  @override
  String get sleepLabel => 'Sueño';

  @override
  String get noteSaved => 'Nota guardada';

  @override
  String get macroTargets => 'Objetivos de macros';

  @override
  String dailyGoalsName(String name) {
    return 'Objetivos diarios · $name';
  }

  @override
  String get saveTargets => 'Guardar objetivos';

  @override
  String get enterValidMacros => 'Introduce valores de macros válidos';

  @override
  String get macrosMustBePositive =>
      'Todos los valores de macros deben ser mayores que 0';

  @override
  String get macroTargetsUpdated => 'Objetivos de macros actualizados';

  @override
  String get failedSaveMacros => 'No se pudieron guardar los macros';

  @override
  String get clientDetailsTitle => 'Detalles del cliente';

  @override
  String get loadClientError => 'No se pudo cargar este cliente ahora.';

  @override
  String get loadDayError => 'No se pudieron cargar los datos de este día.';

  @override
  String get tabAnalytics => 'Analíticas';

  @override
  String get tabPlan => 'Plan';

  @override
  String get nutritionSummary => 'Resumen nutricional';

  @override
  String get editTargets => 'Editar objetivos';

  @override
  String get workoutLabel => 'Entrenamiento';

  @override
  String get swapWorkout => 'Cambiar entrenamiento';

  @override
  String get coachNoteLabel => 'Nota del entrenador';

  @override
  String get noMealsLogged => 'No hay comidas registradas este día.';

  @override
  String get noWorkoutAssignedLib =>
      'No hay entrenamiento asignado este día.\nAsigna uno desde la pestaña Biblioteca.';

  @override
  String pendingTarget(int reps) {
    return 'pendiente · objetivo $reps';
  }

  @override
  String get clientCheckIn => 'Registro del cliente';

  @override
  String get noCheckInNote => 'No hay nota de registro este día.';

  @override
  String get loadAnalyticsError => 'No se pudieron cargar las analíticas.';

  @override
  String get noCoachLinked => 'Este cliente no tiene entrenador vinculado.';

  @override
  String get noLibraryWorkouts =>
      'Aún no hay entrenamientos en tu biblioteca: crea uno en la pestaña Biblioteca.';

  @override
  String workoutAssignedName(String name) {
    return 'Entrenamiento asignado · $name';
  }

  @override
  String get assignWorkoutErr =>
      'No se pudo asignar el entrenamiento. Inténtalo de nuevo.';

  @override
  String get updateWorkout => 'Actualizar entrenamiento';

  @override
  String get workoutTitleLabel => 'Título del entrenamiento';

  @override
  String exerciseNumber(int n) {
    return 'Ejercicio $n';
  }

  @override
  String get targetWeightLabel => 'Peso objetivo';

  @override
  String get saveWorkout => 'Guardar entrenamiento';

  @override
  String get workoutTitleRequired => 'Se requieren el título y los ejercicios';

  @override
  String get workoutUpdated => 'Entrenamiento actualizado';

  @override
  String get updateWorkoutError =>
      'No se pudo actualizar el entrenamiento. Inténtalo de nuevo.';

  @override
  String get removeWorkoutTitle => '¿Quitar entrenamiento?';

  @override
  String get removeWorkoutMsg =>
      'Esto borra el entrenamiento asignado este día. Tu plantilla de biblioteca se mantiene.';

  @override
  String get workoutRemoved => 'Entrenamiento eliminado';

  @override
  String get removeWorkoutError =>
      'No se pudo quitar el entrenamiento. Inténtalo de nuevo.';

  @override
  String get noCustomHabitsBody =>
      'Aún no hay hábitos personalizados. Añade cosas como pasos, suplementos o un paseo diario: aparecen en el inicio del cliente, junto al agua, el sueño y el peso.';

  @override
  String get addHabits => 'Añadir';

  @override
  String get manageHabits => 'Gestionar';

  @override
  String get habitsUpdated => 'Hábitos actualizados';

  @override
  String get saveHabitsError => 'No se pudieron guardar los hábitos';

  @override
  String get configureMacros => 'Configurar macros';

  @override
  String get savingMacrosConfigures =>
      'Guardar los macros marca a este cliente como configurado.';

  @override
  String workoutLogTitle(String date) {
    return 'Registro de entrenamiento ($date)';
  }

  @override
  String get noWorkoutSelectedDay =>
      'No hay entrenamiento asignado para el día seleccionado.';

  @override
  String get updateBtn => 'Actualizar';

  @override
  String get yourNote => 'Tu nota';

  @override
  String get leaveANote => 'Deja una nota';

  @override
  String get savedLabel => 'Guardado';

  @override
  String writeFeedbackFor(String name) {
    return 'Escribe comentarios para $name…';
  }

  @override
  String get editingPastDay => 'Editando un día pasado';

  @override
  String get updateNote => 'Actualizar nota';

  @override
  String get saveNote => 'Guardar nota';

  @override
  String get relToday => 'hoy';

  @override
  String get relTomorrow => 'mañana';

  @override
  String get relYesterday => 'ayer';

  @override
  String forClientDate(String name, String date) {
    return 'Para $name · $date';
  }

  @override
  String get chooseAWorkout => 'Elige un entrenamiento';

  @override
  String get includesLabel => 'Incluye';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ejercicios',
      one: '1 ejercicio',
    );
    return '$_temp0';
  }

  @override
  String get habitsManagerBody =>
      'Hábitos que este cliente marca cada día, junto al agua, el sueño y el peso.';

  @override
  String get addAHabit => 'Añadir un hábito';

  @override
  String get habitNameHint => 'p. ej. 10k pasos';

  @override
  String get saveHabits => 'Guardar hábitos';

  @override
  String get plansSubtitle => 'Elige el plan que se ajuste a tu cartera';

  @override
  String get planCurrent => 'Plan actual';

  @override
  String get planMostPopular => 'Más popular';

  @override
  String get planPerMonth => '/mes';

  @override
  String planChoose(String plan) {
    return 'Elegir $plan';
  }

  @override
  String planClientsUpTo(int count) {
    return 'Hasta $count clientes';
  }

  @override
  String get planClientsUnlimited => 'Clientes ilimitados';

  @override
  String planUsageLimited(int used, int total) {
    return '$used / $total clientes';
  }

  @override
  String get planFreeTagline => 'Empieza con unos pocos clientes';

  @override
  String get planProTagline => 'Para coaches en crecimiento';

  @override
  String get planStudioTagline => 'Para coaches consolidados, sin límites';

  @override
  String get featureMonitoring => 'Seguimiento diario de clientes';

  @override
  String get featureWorkoutLibrary =>
      'Biblioteca de entrenamientos y programación';

  @override
  String get featureAiMeal => 'Escaneo de comidas con IA incluido';

  @override
  String get featureRecurring => 'Programación semanal recurrente';

  @override
  String get featureCustomHabits => 'Seguimiento de hábitos personalizados';

  @override
  String get featureAnalytics => 'Analíticas de progreso';

  @override
  String get featurePrioritySupport => 'Soporte prioritario';

  @override
  String get featureEverythingFree => 'Todo lo del plan Gratis';

  @override
  String get featureEverythingPro => 'Todo lo del plan Pro';

  @override
  String get upgradeContactTitle => 'Mejora tu plan';

  @override
  String upgradeContactBody(String plan) {
    return 'El pago en línea llegará pronto. Contáctanos y activaremos tu plan $plan de inmediato.';
  }

  @override
  String get contactUs => 'Contáctanos';

  @override
  String get clientLimitTitle => 'Límite de clientes alcanzado';

  @override
  String clientLimitBody(int count) {
    return 'Has alcanzado el límite de $count clientes de tu plan. Mejóralo para añadir más.';
  }

  @override
  String get viewPlans => 'Ver planes';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountWarning =>
      'Esto borra permanentemente tu cuenta y todos tus datos. Esta acción no se puede deshacer.';

  @override
  String get deleteAccountConfirmPassword =>
      'Introduce tu contraseña para confirmar';

  @override
  String get reminderTitle => 'Hora de registrar tu día';

  @override
  String get reminderBody => 'Registra tus comidas y hábitos en Valence.';

  @override
  String get reminderTimeLabel => 'Hora del recordatorio';

  @override
  String get remindersPermissionDenied =>
      'Activa las notificaciones en los ajustes de tu dispositivo para recibir recordatorios.';

  @override
  String get intakePriorTitle => '¿Has hecho seguimiento antes?';

  @override
  String get intakePriorSubtitle =>
      'Sin juicios: solo nos ayuda a marcar el ritmo adecuado.';

  @override
  String get priorNever => 'Nunca';

  @override
  String get priorStopped => 'Lo intenté, no seguí';

  @override
  String get priorCurrent => 'Ya lo hago';

  @override
  String get onboardCommitTitle => '¿Listo para comprometerte?';

  @override
  String get onboardCommitSubtitle =>
      'Los pequeños registros diarios suman. Preséntate por ti y tu plan hará el resto.';

  @override
  String get onboardCommitCta => 'Me apunto';

  @override
  String get createAccountSavePlan => 'Crear cuenta para guardar mi plan';

  @override
  String get planGoalLabel => 'Tu objetivo';

  @override
  String planReachBy(String weight, String date) {
    return 'Alcanza $weight para $date';
  }

  @override
  String get roleCoachDesc =>
      'Gestiona a tus clientes, crea planes y sigue el progreso de todos.';

  @override
  String get roleClientDesc =>
      'Registra tus comidas con IA y sigue el plan de tu coach.';

  @override
  String get unitsMetric => 'Métrico';

  @override
  String get unitsImperial => 'Imperial';

  @override
  String get unitLb => 'lb';

  @override
  String weightToLoseU(String amount, String unit) {
    return '$amount $unit para perder';
  }

  @override
  String weightToGainU(String amount, String unit) {
    return '$amount $unit para ganar';
  }

  @override
  String get intakeAgeInsight =>
      'Tu edad influye en cuántas calorías quemas en reposo.';

  @override
  String get intakeHeightInsight =>
      'Tu altura se combina con tu peso para estimar tu metabolismo.';

  @override
  String get intakeWeightInsight =>
      'Este es tu punto de partida: seguiremos cada paso desde aquí.';

  @override
  String get intakeTargetInsight =>
      'Un ritmo gradual es la forma más sostenible de lograrlo.';

  @override
  String get intakeActivityInsight =>
      'Define tu gasto diario con el método Mifflin-St Jeor que usan los dietistas.';

  @override
  String get ciSpecialtiesInsight =>
      'Adaptamos las plantillas y los consejos que sugerimos a tu enfoque.';

  @override
  String get ciExperienceInsight =>
      'Esto establece valores predeterminados sensatos: puedes cambiar todo después.';

  @override
  String get ciRosterInsight =>
      'Valence crece contigo: empieza gratis con tus primeros 3 clientes.';

  @override
  String get ciPriorInsight =>
      'Te ayudaremos a reunirlo todo en un solo lugar.';

  @override
  String get purchaseSuccess => '¡Listo, ya tienes tu plan!';

  @override
  String get purchaseFailed => 'La compra no se completó. Inténtalo de nuevo.';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get authErrInviteRequired =>
      'Se necesita un código de invitación para registrarte';

  @override
  String get authErrInviteInvalid =>
      'Ese código de invitación no es válido, expiró o ya fue usado';

  @override
  String get authErrEmailInUse =>
      'Ese correo ya está registrado — intenta iniciar sesión';

  @override
  String get authErrWeakPassword =>
      'La contraseña es demasiado débil — usa al menos 6 caracteres';

  @override
  String get authErrInvalidEmail => 'Esa dirección de correo no es válida';

  @override
  String get authErrWrongCredentials =>
      'El correo o la contraseña son incorrectos';

  @override
  String get authErrTooManyRequests =>
      'Demasiados intentos — espera un momento y vuelve a intentarlo';

  @override
  String get authErrNetwork =>
      'Error de red — comprueba tu conexión e inténtalo de nuevo';

  @override
  String get authErrUserDataNotFound =>
      'No se encontraron los datos de tu cuenta';

  @override
  String get authErrNoEmailOnFile => 'No hay ningún correo registrado';

  @override
  String get authErrNotLoggedIn => 'Debes iniciar sesión';

  @override
  String get authErrClientsOnly =>
      'Solo las cuentas de cliente pueden vincular un entrenador';

  @override
  String get authErrLinkCoachFailed =>
      'No se pudo vincular tu entrenador — inténtalo de nuevo';

  @override
  String get authErrIncorrectPassword => 'Contraseña incorrecta';

  @override
  String get authErrRecentLogin =>
      'Cierra sesión, vuelve a iniciarla y reinténtalo';

  @override
  String get authErrResetFailed =>
      'No se pudo enviar el correo de restablecimiento';

  @override
  String get authErrSignupFailed =>
      'No se pudo crear tu cuenta — inténtalo de nuevo';

  @override
  String get authErrSigninFailed =>
      'No se pudo iniciar sesión — inténtalo de nuevo';

  @override
  String get authErrDeleteFailed =>
      'No se pudo eliminar tu cuenta — inténtalo de nuevo';

  @override
  String get authErrUnknown => 'Algo salió mal — vuelve a intentarlo';

  @override
  String quietForDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días sin actividad',
      one: '1 día sin actividad',
    );
    return '$_temp0';
  }

  @override
  String get statusNew => 'Nuevo';

  @override
  String get joinedRecently => 'Recién llegado — esperando su primer registro';

  @override
  String consistencyThisWeek(int pct) {
    return '$pct % de constancia esta semana';
  }

  @override
  String get coverRolePrompt => '¿Cómo usarás Valence?';

  @override
  String get welcomeTitle => 'Te damos la bienvenida a Valence';

  @override
  String get clientIntroTitle => 'Tu entrenador, en tu bolsillo';

  @override
  String get coachIntroTitle => 'Todo tu coaching, en un solo lugar';

  @override
  String get introSubtitle => 'Así funciona Valence para ti.';

  @override
  String get roleAthlete => 'Atleta';

  @override
  String get clientIntroCta => 'Crear mi plan';

  @override
  String get coachIntroCta => 'Configurar mi perfil';

  @override
  String get coachSetupReady =>
      'Tu espacio de coaching está listo. Invita a tu primer cliente para empezar.';

  @override
  String confidenceNote(String word, int score) {
    return 'Confianza $word ($score/100): toca Ajustar para afinar.';
  }

  @override
  String get centerYourPlate => 'Centra tu plato';

  @override
  String get portionLabel => 'Porción';

  @override
  String kcalLeftToday(int n) {
    return 'Quedan $n kcal hoy';
  }

  @override
  String kcalOverToday(int n) {
    return '$n kcal por encima hoy';
  }

  @override
  String get describeCardSub => 'Escríbelo y la IA hace el cálculo';

  @override
  String get manualCardSub => '¿Sabes los números? Ingrésalos tú';

  @override
  String get flashLabel => 'Flash';

  @override
  String get galleryCardSub => 'Elige una foto existente';

  @override
  String get scanCardSub => 'Apunta, dispara y listo';

  @override
  String get aiInsightsTitle => 'Análisis con IA';

  @override
  String get aiInsightsTease =>
      'Descubre qué funciona y qué falla esta semana, comparado con la semana pasada.';

  @override
  String get aiInsightsUnlock => 'Desbloquear con Pro';

  @override
  String get aiInsightsWins => 'Qué funciona';

  @override
  String get aiInsightsRisks => 'Requiere atención';

  @override
  String get aiInsightsActions => 'Qué puedes hacer';

  @override
  String get aiInsightsReading => 'Leyendo los registros de esta semana…';

  @override
  String get aiInsightsRefresh => 'Volver a analizar';

  @override
  String get aiInsightsUpToDate =>
      'Nada nuevo registrado desde el último análisis.';

  @override
  String get aiInsightsNoData =>
      'Aún no hay datos suficientes. Vuelve tras unos días más de registro.';

  @override
  String get aiInsightsError =>
      'No se pudo analizar ahora. Inténtalo de nuevo.';

  @override
  String get aiInsightsDisclaimer =>
      'Observaciones a partir de los datos registrados — no es consejo médico. Confírmalo antes de actuar.';

  @override
  String get aiAnalyzedToday => 'Analizado hoy';

  @override
  String get aiAnalyzedYesterday => 'Analizado ayer';

  @override
  String aiAnalyzedDaysAgo(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Analizado hace $days días',
    );
    return '$_temp0';
  }

  @override
  String aiInsightsConfidence(String word) {
    return 'Confianza $word';
  }

  @override
  String get aiInsightsOutdated =>
      'Esto cubre una semana que ya pasó. Vuelve a analizar para la semana actual.';

  @override
  String aiInsightsOtherLanguage(String language) {
    return 'Escrito en otro idioma. Vuelve a analizar para obtenerlo en $language.';
  }

  @override
  String get shareWinCta => 'Compartir mi progreso';

  @override
  String get shareWinTitle => 'Tu progreso';

  @override
  String get shareWinNothingYet =>
      'Registra unos días más y tu tarjeta de progreso estará lista para compartir.';

  @override
  String shareWinLost(String amount, String unit) {
    return '$amount $unit menos';
  }

  @override
  String shareWinGained(String amount, String unit) {
    return '$amount $unit ganados';
  }

  @override
  String shareWinInWeeks(num weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'en $weeks semanas',
      one: 'en 1 semana',
    );
    return '$_temp0';
  }

  @override
  String shareWinStreakHero(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días seguidos',
      one: '1 día seguido',
    );
    return '$_temp0';
  }

  @override
  String get shareWinShowedUp => 'Constancia';

  @override
  String get shareWinStatStreak => 'Racha';

  @override
  String get shareWinStatDays => 'Días registrados';

  @override
  String get shareWinStatSessions => 'Sesiones';

  @override
  String shareWinCoachedBy(String name) {
    return 'Entrenado por $name';
  }

  @override
  String get shareWinFailed =>
      'No se pudo crear la imagen. Inténtalo de nuevo.';

  @override
  String get featureAiInsights =>
      'Análisis de clientes con IA, con los datos que los respaldan';

  @override
  String get featureLibraryRecurring =>
      'Biblioteca, programación y rutinas recurrentes';

  @override
  String get featureHabitsAnalytics =>
      'Hábitos personalizados y análisis de progreso';

  @override
  String get retry => 'Reintentar';

  @override
  String get undo => 'Deshacer';

  @override
  String get habitRemoved => 'Hábito eliminado';

  @override
  String assignSkippedPast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días de esta semana ya han pasado',
      one: '1 día de esta semana ya ha pasado',
    );
    return '$_temp0';
  }

  @override
  String get assignChooseClient => 'Elige un cliente';

  @override
  String get unitLiters => 'L';

  @override
  String get unitGrams => 'g';

  @override
  String get noWorkoutToday => 'No hay entrenamiento asignado para hoy.';

  @override
  String get noWorkoutSwapHint =>
      'No hay entrenamiento asignado para este día. Usa «Cambiar entrenamiento» arriba para asignar uno.';

  @override
  String get readingYourDescription => 'Leyendo tu descripción…';

  @override
  String get mealsOnDay => 'Comidas';

  @override
  String get planCurrentTag => 'Actual';

  @override
  String get featureAiCited =>
      'Cada conclusión cita los datos registrados del cliente';

  @override
  String get featureAiSpotsPatterns =>
      'Detecta patrones de varias semanas difíciles de ver a mano';

  @override
  String get buildingYourPlan => 'Creando tu plan';

  @override
  String get buildingYourSetup => 'Preparando tu espacio';
}
