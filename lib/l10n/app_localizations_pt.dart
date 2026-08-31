// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get landingSubtitle =>
      'Acompanhamento diário entre treinadores e seus clientes — feito para resultados reais.';

  @override
  String get roleCoach => 'Treinador';

  @override
  String get roleClient => 'Cliente';

  @override
  String get getStarted => 'Começar';

  @override
  String get signIn => 'Entrar';

  @override
  String get logIn => 'Entrar';

  @override
  String get signUp => 'Cadastrar-se';

  @override
  String get alreadyHaveAccount => 'Já tem uma conta?';

  @override
  String get dontHaveAccount => 'Não tem uma conta?';

  @override
  String get createAccount => 'Criar conta';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Senha';

  @override
  String get fullName => 'Nome completo';

  @override
  String get forgotPassword => 'Esqueceu a senha?';

  @override
  String get save => 'Salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get remove => 'Remover';

  @override
  String get edit => 'Editar';

  @override
  String get add => 'Adicionar';

  @override
  String get done => 'Concluído';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get next => 'Próximo';

  @override
  String get back => 'Voltar';

  @override
  String get close => 'Fechar';

  @override
  String get search => 'Buscar';

  @override
  String get navToday => 'Hoje';

  @override
  String get navWorkouts => 'Treinos';

  @override
  String get navProgress => 'Progresso';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navClients => 'Clientes';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get sectionPreferences => 'PREFERÊNCIAS';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Escolha o idioma do app';

  @override
  String get languageSystemDefault => 'Padrão do sistema';

  @override
  String get chooseLanguage => 'Escolher idioma';

  @override
  String get welcomeBackTitle => 'Bem-vindo de volta';

  @override
  String get welcomeBackToast => 'Bem-vindo de volta!';

  @override
  String get loginSubtitle => 'Entre para continuar sua jornada.';

  @override
  String get emailRequired => 'O e-mail é obrigatório';

  @override
  String get passwordRequired => 'A senha é obrigatória';

  @override
  String get emailHint => 'Digite seu e-mail';

  @override
  String get passwordHint => 'Digite sua senha';

  @override
  String get forgotPasswordEnterEmail =>
      'Digite seu e-mail acima e toque em Esqueceu a senha.';

  @override
  String resetLinkSent(String email) {
    return 'Link de redefinição enviado para $email';
  }

  @override
  String get inviteLinkRequired => 'O link de convite é obrigatório';

  @override
  String get accountCreated => 'Conta criada com sucesso';

  @override
  String get joinValence => 'Junte-se ao Valence';

  @override
  String signupSubtitle(String role) {
    return 'Crie sua conta $role premium.';
  }

  @override
  String get inviteCode => 'Código de convite';

  @override
  String get fullNameRequired => 'O nome completo é obrigatório';

  @override
  String get fullNameHint => 'Digite seu nome completo';

  @override
  String get emailInvalid => 'Digite um endereço de e-mail válido';

  @override
  String get passwordTooShort => 'A senha deve ter pelo menos 6 caracteres';

  @override
  String get passwordCreateHint => 'Crie uma senha segura';

  @override
  String get logOut => 'Sair';

  @override
  String get linkCoachTitle => 'Digite o código de convite do treinador';

  @override
  String get linkCoachSubtitle =>
      'Você precisa vincular um treinador antes de usar o app.';

  @override
  String get obClientLogTitle => 'Registre em segundos';

  @override
  String get obClientLogBody =>
      'Fotografe uma refeição, marque um hábito, registre uma série. A IA da Valence calcula as calorias por você.';

  @override
  String get obClientHabitsTitle => 'Construa os hábitos diários';

  @override
  String get obClientHabitsBody =>
      'Água, sono, peso e os hábitos definidos pelo seu treinador — tudo em uma lista diária tranquila.';

  @override
  String get obClientCoachTitle => 'Seu treinador está com você';

  @override
  String get obClientCoachBody =>
      'Ele acompanha seu progresso e te incentiva na hora certa. Você nunca está sozinho.';

  @override
  String get obCoachRosterTitle => 'Veja quem precisa de você';

  @override
  String get obCoachRosterBody =>
      'Toda a sua lista num relance — quem está em dia e quem está falhando, atualizado assim que um cliente registra.';

  @override
  String get obCoachProgramTitle => 'Programe uma vez, acompanhe todo dia';

  @override
  String get obCoachProgramBody =>
      'Crie treinos e hábitos, atribua-os e veja a conclusão chegar — sem mais WhatsApp e planilhas.';

  @override
  String get obCoachGrowTitle => 'Cresça sem desgaste';

  @override
  String get obCoachGrowBody =>
      'Mantenha o toque pessoal de 5 a 50 clientes. A Valence faz a cobrança para você focar no coaching.';

  @override
  String get intakeSaveError =>
      'Não foi possível salvar seu plano. Tente novamente.';

  @override
  String get intakeGoalTitle => 'Qual é o seu objetivo?';

  @override
  String get intakeGoalSubtitle =>
      'Vamos ajustar suas calorias diárias para combinar.';

  @override
  String get goalLoseTitle => 'Perder peso';

  @override
  String get goalLoseSubtitle => 'Perda de gordura gradual';

  @override
  String get goalMaintainTitle => 'Manter';

  @override
  String get goalMaintainSubtitle => 'Fique onde está';

  @override
  String get goalGainTitle => 'Ganhar músculo';

  @override
  String get goalGainSubtitle => 'Massa magra';

  @override
  String get intakeSexTitle => 'O que descreve você melhor?';

  @override
  String get intakeSexSubtitle =>
      'O sexo biológico altera o cálculo de calorias.';

  @override
  String get sexMale => 'Masculino';

  @override
  String get sexFemale => 'Feminino';

  @override
  String get intakeAgeTitle => 'Quantos anos você tem?';

  @override
  String get intakeAgeSubtitle =>
      'Isso molda seu metabolismo e suas necessidades calóricas.';

  @override
  String get unitYears => 'anos';

  @override
  String get intakeHeightTitle => 'Qual é a sua altura?';

  @override
  String get intakeHeightSubtitle => 'Usada para estimar sua energia diária.';

  @override
  String get unitCm => 'cm';

  @override
  String get intakeWeightTitle => 'Seu peso atual?';

  @override
  String get intakeWeightSubtitle =>
      'Apenas nosso ponto de partida — acompanhamos a partir daqui.';

  @override
  String get unitKg => 'kg';

  @override
  String get intakeTargetTitle => 'Seu peso-meta?';

  @override
  String get intakeTargetSubtitle =>
      'Defina o destino — nós planejamos o caminho.';

  @override
  String get intakeActivityTitle => 'Quão ativo você é?';

  @override
  String get intakeActivitySubtitle =>
      'Fora dos treinos planejados, no dia a dia.';

  @override
  String get intakeAnalyzing1 => 'Analisando seu metabolismo';

  @override
  String get intakeAnalyzing2 => 'Calculando suas calorias';

  @override
  String get intakeAnalyzing3 => 'Equilibrando seus macros';

  @override
  String get intakeAnalyzing4 => 'Finalizando seu plano';

  @override
  String get intakePlanReady => 'Seu plano está pronto';

  @override
  String intakePlanReadyNamed(String name) {
    return '$name, seu plano está pronto';
  }

  @override
  String get intakePlanSubtitle =>
      'Calculado automaticamente a partir das suas respostas — seu treinador pode ajustar quando quiser.';

  @override
  String get dailyCalories => 'Calorias diárias';

  @override
  String get kcal => 'kcal';

  @override
  String get macroProtein => 'Proteínas';

  @override
  String get macroCarbs => 'Carboidratos';

  @override
  String get macroFat => 'Gorduras';

  @override
  String get startTracking => 'Começar a acompanhar';

  @override
  String get deltaMaintain => 'Mantenha seu peso';

  @override
  String get activitySedentary => 'Sedentário';

  @override
  String get activitySedentaryHint => 'Trabalho de escritório, pouco exercício';

  @override
  String get activityLight => 'Levemente ativo';

  @override
  String get activityLightHint => 'Exercício leve 1–3 dias/sem';

  @override
  String get activityModerate => 'Moderadamente ativo';

  @override
  String get activityModerateHint => 'Exercício 3–5 dias/sem';

  @override
  String get activityActive => 'Muito ativo';

  @override
  String get activityActiveHint => 'Exercício intenso 6–7 dias/sem';

  @override
  String get activityVeryActive => 'Atleta';

  @override
  String get activityVeryActiveHint => 'Treino duas vezes ao dia';

  @override
  String get specWeightLoss => 'Perda de peso';

  @override
  String get specMuscleGain => 'Ganho de massa';

  @override
  String get specStrength => 'Força';

  @override
  String get specNutrition => 'Nutrição';

  @override
  String get specRecomp => 'Recomposição corporal';

  @override
  String get specGeneralFitness => 'Fitness geral';

  @override
  String get specEndurance => 'Resistência';

  @override
  String get specMobility => 'Mobilidade e reabilitação';

  @override
  String get expJustStarting => 'Começando agora';

  @override
  String get expJustStartingHint => 'Novo no coaching';

  @override
  String get expOneToThree => '1–3 anos';

  @override
  String get expOneToThreeHint => 'Formando minha base';

  @override
  String get expThreeToFive => '3–5 anos';

  @override
  String get expThreeToFiveHint => 'Treinador estabelecido';

  @override
  String get expFivePlus => 'Mais de 5 anos';

  @override
  String get expFivePlusHint => 'Profissional experiente';

  @override
  String get rosterSolo => 'Só eu, ainda sem clientes';

  @override
  String get rosterSmall => '1–10 clientes';

  @override
  String get rosterGrowing => '11–25 clientes';

  @override
  String get rosterEstablished => 'Mais de 25 clientes';

  @override
  String get priorWhatsapp => 'WhatsApp e chat';

  @override
  String get priorSpreadsheets => 'Planilhas';

  @override
  String get priorOtherApp => 'Outro app de coaching';

  @override
  String get priorPenPaper => 'Papel e caneta';

  @override
  String get priorMix => 'Um pouco de tudo';

  @override
  String get coachIntakeSaveError =>
      'Não foi possível salvar seu perfil. Tente novamente.';

  @override
  String get ciSpecialtiesTitle => 'Em que você é especialista?';

  @override
  String get ciSpecialtiesSubtitle =>
      'Escolha tudo que se aplica — molda seu perfil de coaching.';

  @override
  String get ciExperienceTitle => 'Há quanto tempo você treina pessoas?';

  @override
  String get ciExperienceSubtitle => 'Para adaptar a experiência a você.';

  @override
  String get ciRosterTitle => 'Quantos clientes você tem hoje?';

  @override
  String get ciRosterSubtitle =>
      'Aproximadamente — só para entender sua escala.';

  @override
  String get ciPriorTitle => 'Como você gerencia tudo hoje?';

  @override
  String get ciPriorSubtitle => 'Vamos te ajudar a substituir o caos.';

  @override
  String get ciAnalyzing1 => 'Configurando seu estúdio';

  @override
  String get ciAnalyzing2 => 'Preparando seu painel';

  @override
  String get ciAnalyzing3 => 'Adaptando às suas especialidades';

  @override
  String get ciAnalyzing4 => 'Quase pronto';

  @override
  String get ciAllSet => 'Tudo pronto';

  @override
  String ciWelcomeName(String name) {
    return 'Bem-vindo, $name';
  }

  @override
  String get ciYourFocus => 'Seu foco';

  @override
  String get enterValence => 'Entrar no Valence';

  @override
  String get settingsDisplayName => 'Nome de exibição';

  @override
  String get settingsEnterName => 'Digite seu nome';

  @override
  String get profileUpdated => 'Perfil atualizado';

  @override
  String get profileUpdateError => 'Não foi possível atualizar o perfil agora';

  @override
  String get settingsSaved => 'Configurações salvas';

  @override
  String get settingsSaveError => 'Não foi possível salvar as configurações';

  @override
  String get changePassword => 'Alterar senha';

  @override
  String changePasswordMsg(String email) {
    return 'Enviaremos um link de redefinição seguro para $email. Abra-o para definir uma nova senha.';
  }

  @override
  String get sendLink => 'Enviar link';

  @override
  String get helpSupport => 'Ajuda e suporte';

  @override
  String supportBody(String role) {
    return 'Para suporte de conta ou do app, contate support@valence.app.\n\nInclua seu papel ($role) e um breve resumo do problema.';
  }

  @override
  String get copyEmail => 'Copiar e-mail';

  @override
  String get supportEmailCopied => 'E-mail de suporte copiado';

  @override
  String get aboutValence => 'Sobre o Valence';

  @override
  String aboutVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get aboutTaglineClient =>
      'Acompanhe suas refeições, treinos e hábitos — e mantenha o compromisso com seu treinador todos os dias.';

  @override
  String get myCoach => 'Meu treinador';

  @override
  String get coachLinkedLabel => 'Vinculado à sua conta';

  @override
  String get coachNotLinked => 'Ainda não vinculado';

  @override
  String get connect => 'Conectar';

  @override
  String get darkMode => 'Modo escuro';

  @override
  String get darkModeSubtitle => 'Altere a aparência do app';

  @override
  String get mealReminders => 'Lembretes de refeição';

  @override
  String get mealRemindersSubtitle => 'Lembre-me de registrar minhas refeições';

  @override
  String get metricUnits => 'Unidades métricas (kg)';

  @override
  String get metricUnitsSubtitle => 'Mostrar o peso em quilos ou libras';

  @override
  String get logoutConfirmTitle => 'Sair?';

  @override
  String get logoutConfirmMsg =>
      'Você precisará entrar novamente para continuar.';

  @override
  String get sectionAccount => 'CONTA';

  @override
  String get sectionSupport => 'SUPORTE';

  @override
  String get badgeMember => 'MEMBRO';

  @override
  String get badgeCoach => 'TREINADOR';

  @override
  String get inviteAClient => 'Convidar um cliente';

  @override
  String get coachSupportTitle => 'Suporte ao treinador';

  @override
  String get coachSupportBody =>
      'Para faturamento, gestão de clientes ou suporte técnico:\nsupport@valence.app';

  @override
  String get aboutTaglineCoach =>
      'A plataforma de acompanhamento que mantém treinadores e clientes em sintonia — todos os dias.';

  @override
  String get planLabel => 'Plano';

  @override
  String get planFree => 'Grátis';

  @override
  String get planPro => 'Pro';

  @override
  String get planStudio => 'Elite';

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
  String get clientActivityAlerts => 'Alertas de atividade dos clientes';

  @override
  String get clientActivityAlertsSubtitle =>
      'Seja avisado quando um cliente registra';

  @override
  String get inviteGenerateError =>
      'Não foi possível gerar o código de convite';

  @override
  String get inviteCodeCopied => 'Código de convite copiado';

  @override
  String get inviteLinkCopied => 'Link de convite copiado';

  @override
  String get inviteSheetSubtitle => 'Adicione alguém à sua lista';

  @override
  String get inviteSheetBody =>
      'Gere um código de uso único (válido por 7 dias) e compartilhe. Seu cliente o insere ao se cadastrar — um código por cliente, sem compartilhar demais.';

  @override
  String get inviteNoCode => 'Ainda sem código — gere um abaixo';

  @override
  String get generateCode => 'Gerar código';

  @override
  String get newCode => 'Novo código';

  @override
  String get copyCode => 'Copiar código';

  @override
  String get copyLink => 'Copiar link';

  @override
  String get todaysWorkout => 'Treino de hoje';

  @override
  String workoutExercisesSets(int exercises, int done, int total) {
    return '$exercises exercícios · $done de $total séries';
  }

  @override
  String get markComplete => 'Concluir treino';

  @override
  String get markNotDone => 'Marcar como não concluído';

  @override
  String get pastWorkoutViewOnly => 'Treino anterior — somente leitura';

  @override
  String exerciseSetsTarget(int done, int sets, int reps) {
    return '$done/$sets séries · meta $reps reps';
  }

  @override
  String get completeAllSets => 'Concluir todas as séries';

  @override
  String get resetExercise => 'Redefinir exercício';

  @override
  String setNumberLabel(int n) {
    return 'Série $n';
  }

  @override
  String get logged => 'Registrado';

  @override
  String get tapToLog => 'Toque para registrar';

  @override
  String get repsLabel => 'Reps';

  @override
  String get enterValidWeight => 'Digite um peso válido';

  @override
  String get restDay => 'Dia de descanso';

  @override
  String get restDayTodayBody =>
      'Nenhum treino planejado para hoje. Aproveite a recuperação — ou veja outro dia.';

  @override
  String get restDayPastBody => 'Nenhum treino foi atribuído para este dia.';

  @override
  String get logWeightTitle => 'Registrar peso';

  @override
  String get enterWeightHint => 'Digite seu peso';

  @override
  String get noteSentToCoach => 'Nota enviada ao treinador';

  @override
  String get noLogForDay => 'Ainda não há registro para este dia';

  @override
  String get noteSaveFailed => 'Falha ao salvar a nota';

  @override
  String get editMeal => 'Editar refeição';

  @override
  String get mealName => 'Nome da refeição';

  @override
  String get caloriesLabel => 'Calorias';

  @override
  String get proteinG => 'Proteínas (g)';

  @override
  String get carbsG => 'Carboidratos (g)';

  @override
  String get fatG => 'Gorduras (g)';

  @override
  String get invalidMacros => 'Digite valores de macros válidos';

  @override
  String get mealUpdated => 'Refeição atualizada';

  @override
  String get deleteMealTitle => 'Excluir refeição?';

  @override
  String deleteMealMsg(String meal) {
    return 'Remover “$meal” do histórico de hoje?';
  }

  @override
  String get mealDeleted => 'Refeição excluída';

  @override
  String get noteOnlyToday => 'Você só pode deixar uma nota para hoje';

  @override
  String get hi => 'Oi,';

  @override
  String get noteButton => 'Nota';

  @override
  String get todaysCheckIn => 'Check-in de hoje';

  @override
  String get noteToCoachBody =>
      'Conte ao seu treinador como foi o dia — energia, dores, desejos, qualquer coisa. Ele vê isso com seu registro.';

  @override
  String get noteToCoachHint =>
      'ex. “Me senti forte hoje, dormi 8 h, sem energia após o almoço…”';

  @override
  String get sendToCoach => 'Enviar ao treinador';

  @override
  String get viewingPastDay => 'Visualizando dia anterior — somente leitura';

  @override
  String get dailyWinCopied => 'Conquista do dia copiada para compartilhar';

  @override
  String get shareDailyWin => 'Compartilhar conquista do dia';

  @override
  String get dailyHabits => 'Hábitos diários';

  @override
  String get yourHabits => 'Seus hábitos';

  @override
  String get waterLabel => 'Água';

  @override
  String get weightLabel => 'Peso';

  @override
  String get sleepQuality => 'Qualidade do sono';

  @override
  String get howRested => 'Quão descansado você se sente hoje?';

  @override
  String get todaysMeals => 'Refeições de hoje';

  @override
  String get logMeal => 'Registrar refeição';

  @override
  String get logNow => 'Registrar agora';

  @override
  String get confHigh => 'Alta';

  @override
  String get confMedium => 'Média';

  @override
  String get confLow => 'Baixa';

  @override
  String get deleteMeal => 'Excluir refeição';

  @override
  String get aiCameraError => 'Não foi possível acessar a câmera ou a galeria.';

  @override
  String get describeMealFirst => 'Descreva sua refeição primeiro.';

  @override
  String get fillMealAndMacros =>
      'Preencha o nome da refeição e todos os macros.';

  @override
  String get failedToSaveMeal => 'Falha ao salvar a refeição.';

  @override
  String get readByValenceAI => 'Lido pela Valence AI';

  @override
  String get manualEntry => 'Entrada manual';

  @override
  String get yourMeal => 'Sua refeição';

  @override
  String get newMeal => 'Nova refeição';

  @override
  String get whatTheAiSaw => 'O que a IA viu';

  @override
  String get adjust => 'Ajustar';

  @override
  String get startOver => 'Começar de novo';

  @override
  String get logAMeal => 'Registrar uma refeição';

  @override
  String get snapItLogged => 'Fotografe. Registrado.';

  @override
  String get aiReadsPlate => 'A Valence AI lê seu prato em segundos.';

  @override
  String get scanAMeal => 'Escanear uma refeição';

  @override
  String get chooseFromGallery => 'Escolher da galeria';

  @override
  String get describeMealHint =>
      'ex. “2 ovos, torrada com manteiga, suco de laranja”';

  @override
  String get describeYourMeal => 'Descreva sua refeição';

  @override
  String get analyzeWithAI => 'Analisar com IA';

  @override
  String get enterMacrosManually => 'Inserir macros manualmente';

  @override
  String get readingYourPlate => 'Lendo seu prato…';

  @override
  String get aiStatus1 => 'Identificando sua comida';

  @override
  String get aiStatus2 => 'Estimando porções';

  @override
  String get aiStatus3 => 'Calculando os macros';

  @override
  String get aiStatus4 => 'Quase lá';

  @override
  String get mealBreakfast => 'Café da manhã';

  @override
  String get mealLunch => 'Almoço';

  @override
  String get mealSnack => 'Lanche';

  @override
  String get mealDinner => 'Jantar';

  @override
  String get noProgressData => 'Ainda não há dados de progresso.';

  @override
  String chartCaloriesSubtitle(String avg, String target) {
    return 'Méd. $avg kcal • Meta $target';
  }

  @override
  String get weightTrendHint =>
      'Adicione pesagens diárias para ver a tendência';

  @override
  String get habitsScore => 'Pontuação de hábitos';

  @override
  String chartHabitsSubtitle(String water, String sleep) {
    return 'Água méd. $water L • Sono méd. $sleep/5';
  }

  @override
  String get notEnoughData => 'Dados insuficientes';

  @override
  String get chartWeekly => 'Semana';

  @override
  String get chartMonthly => 'Mês';

  @override
  String get chartYearly => 'Ano';

  @override
  String get progressLoadError =>
      'Não foi possível carregar o progresso agora.';

  @override
  String get statusGood => 'Bom';

  @override
  String get statusWatch => 'Atenção';

  @override
  String get statusAlert => 'Alerta';

  @override
  String get statusSetup => 'Config.';

  @override
  String get removeClientTitle => 'Remover cliente?';

  @override
  String removeClientMsg(String name) {
    return 'Isso remove $name da sua lista, exclui os dados e agenda a remoção da conta.';
  }

  @override
  String clientRemoved(String name) {
    return '$name removido; remoção de conta na fila';
  }

  @override
  String get removeClientError => 'Não foi possível remover o cliente agora';

  @override
  String get viewDetails => 'Ver detalhes';

  @override
  String get configurePlan => 'Configurar plano';

  @override
  String get editMacros => 'Editar macros';

  @override
  String get removeClient => 'Remover cliente';

  @override
  String get loadClientsError => 'Não foi possível carregar os clientes';

  @override
  String get checkConnection => 'Verifique sua conexão e tente novamente.';

  @override
  String get coachWord => 'Treinador';

  @override
  String get noClientsYet => 'Ainda sem clientes';

  @override
  String get noClientsBody =>
      'Compartilhe um código de convite na aba Perfil para trazer seu primeiro cliente.';

  @override
  String noClientsMatch(String query) {
    return 'Nenhum cliente corresponde a “$query”.';
  }

  @override
  String get noClientsInGroup => 'Ninguém neste grupo agora.';

  @override
  String get allOnTrack => 'Todos em dia';

  @override
  String needsYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count precisam de você',
      one: '1 precisa de você',
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
  String get metricTraining => 'Treino';

  @override
  String get awaitingLogs => 'Aguardando registros recentes';

  @override
  String get setupMacrosPlan => 'Configure macros e plano para ativar';

  @override
  String get noLogsYet => 'Sem registros';

  @override
  String lastLogOn(String date) {
    return 'Último registro · $date';
  }

  @override
  String get loggedToday => 'Registrado hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String daysAgo(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Há $days dias',
      one: 'Há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get deleteTemplateTitle => 'Excluir modelo?';

  @override
  String deleteTemplateMsg(String name) {
    return 'Isso remove permanentemente “$name” da sua biblioteca. Os treinos já atribuídos aos clientes permanecem.';
  }

  @override
  String get templateDeleted => 'Modelo excluído';

  @override
  String get deleteTemplateError =>
      'Não foi possível excluir o modelo. Tente novamente.';

  @override
  String get noClientsToAssign => 'Ainda não há clientes para atribuir';

  @override
  String assignedDays(int count, String name) {
    return '$count dias atribuídos a $name';
  }

  @override
  String assignedToName(String name) {
    return 'Atribuído a $name';
  }

  @override
  String get assignError => 'Não foi possível atribuir agora. Tente novamente.';

  @override
  String noTemplatesMatch(String query) {
    return 'Nenhum modelo corresponde a “$query”.';
  }

  @override
  String get workoutPlansTitle => 'Planos de treino';

  @override
  String get statExercises => 'Exercícios';

  @override
  String get statSets => 'Séries';

  @override
  String get statReps => 'Repetições';

  @override
  String get assign => 'Atribuir';

  @override
  String get newTemplate => 'Novo modelo';

  @override
  String get buildFirstPlan => 'Crie seu primeiro plano';

  @override
  String get buildFirstPlanBody =>
      'Crie um treino reutilizável uma vez e atribua-o a qualquer cliente em segundos.';

  @override
  String get createTemplate => 'Criar modelo';

  @override
  String get searchTemplates => 'Buscar modelos';

  @override
  String get enterValidWeightBlank =>
      'Digite um peso válido ou deixe em branco';

  @override
  String get giveTemplateName => 'Dê um nome ao seu modelo';

  @override
  String get addAtLeastOneExercise => 'Adicione pelo menos um exercício';

  @override
  String get templateUpdated => 'Modelo atualizado';

  @override
  String get templateCreated => 'Modelo criado';

  @override
  String get couldNotSaveNow => 'Não foi possível salvar agora';

  @override
  String get templateNameLabel => 'Nome do modelo';

  @override
  String get templateNameHint => 'ex. Parte superior · Empurrar';

  @override
  String get saveChanges => 'Salvar alterações';

  @override
  String get newLabel => 'Novo';

  @override
  String get workoutTemplateTitle => 'Modelo de treino';

  @override
  String get exerciseNameHint => 'Nome do exercício';

  @override
  String get targetWeightOptional => 'Peso-alvo · opcional';

  @override
  String get addExercise => 'Adicionar exercício';

  @override
  String get whenLabel => 'Quando';

  @override
  String get todayLabel => 'Hoje';

  @override
  String get tomorrowLabel => 'Amanhã';

  @override
  String get pickLabel => 'Escolher…';

  @override
  String get repeatLabel => 'Repetir';

  @override
  String get justOnce => 'Apenas uma vez';

  @override
  String get weeklyLabel => 'Semanal';

  @override
  String assignNWorkouts(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Atribuir $count treinos',
      one: 'Atribuir 1 treino',
    );
    return '$_temp0';
  }

  @override
  String get assignWorkoutBtn => 'Atribuir treino';

  @override
  String get durationLabel => 'Duração';

  @override
  String get noDaysInRange =>
      'Nenhum dia no intervalo — adicione uma semana ou escolha um dia posterior';

  @override
  String schedulesDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Agenda $count dias de treino',
      one: 'Agenda 1 dia de treino',
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
  String get sleepPoor => 'Ruim';

  @override
  String get sleepFair => 'Razoável';

  @override
  String get sleepGreat => 'Ótimo';

  @override
  String get sleepLabel => 'Sono';

  @override
  String get noteSaved => 'Nota salva';

  @override
  String get macroTargets => 'Metas de macros';

  @override
  String dailyGoalsName(String name) {
    return 'Metas diárias · $name';
  }

  @override
  String get saveTargets => 'Salvar metas';

  @override
  String get enterValidMacros => 'Digite valores de macros válidos';

  @override
  String get macrosMustBePositive =>
      'Todos os valores de macros devem ser maiores que 0';

  @override
  String get macroTargetsUpdated => 'Metas de macros atualizadas';

  @override
  String get failedSaveMacros => 'Falha ao salvar os macros';

  @override
  String get clientDetailsTitle => 'Detalhes do cliente';

  @override
  String get loadClientError => 'Não foi possível carregar este cliente agora.';

  @override
  String get loadDayError => 'Não foi possível carregar os dados deste dia.';

  @override
  String get tabAnalytics => 'Análises';

  @override
  String get tabPlan => 'Plano';

  @override
  String get nutritionSummary => 'Resumo nutricional';

  @override
  String get editTargets => 'Editar metas';

  @override
  String get workoutLabel => 'Treino';

  @override
  String get swapWorkout => 'Trocar treino';

  @override
  String get coachNoteLabel => 'Nota do treinador';

  @override
  String get noMealsLogged => 'Nenhuma refeição registrada neste dia.';

  @override
  String get noWorkoutAssignedLib =>
      'Nenhum treino atribuído neste dia.\nAtribua um na aba Biblioteca.';

  @override
  String pendingTarget(int reps) {
    return 'pendente · meta $reps';
  }

  @override
  String get clientCheckIn => 'Check-in do cliente';

  @override
  String get noCheckInNote => 'Nenhuma nota de check-in neste dia.';

  @override
  String get loadAnalyticsError => 'Não foi possível carregar as análises.';

  @override
  String get noCoachLinked => 'Este cliente não tem treinador vinculado.';

  @override
  String get noLibraryWorkouts =>
      'Ainda não há treinos na sua biblioteca — crie um na aba Biblioteca.';

  @override
  String workoutAssignedName(String name) {
    return 'Treino atribuído · $name';
  }

  @override
  String get assignWorkoutErr =>
      'Não foi possível atribuir o treino. Tente novamente.';

  @override
  String get updateWorkout => 'Atualizar treino';

  @override
  String get workoutTitleLabel => 'Título do treino';

  @override
  String exerciseNumber(int n) {
    return 'Exercício $n';
  }

  @override
  String get targetWeightLabel => 'Peso-alvo';

  @override
  String get saveWorkout => 'Salvar treino';

  @override
  String get workoutTitleRequired =>
      'O título do treino e os exercícios são obrigatórios';

  @override
  String get workoutUpdated => 'Treino atualizado';

  @override
  String get updateWorkoutError =>
      'Não foi possível atualizar o treino. Tente novamente.';

  @override
  String get removeWorkoutTitle => 'Remover treino?';

  @override
  String get removeWorkoutMsg =>
      'Isso limpa o treino atribuído neste dia. Seu modelo da biblioteca permanece.';

  @override
  String get workoutRemoved => 'Treino removido';

  @override
  String get removeWorkoutError =>
      'Não foi possível remover o treino. Tente novamente.';

  @override
  String get noCustomHabitsBody =>
      'Ainda sem hábitos personalizados. Adicione coisas como passos, suplementos ou uma caminhada diária — aparecem na tela inicial do cliente, além de água, sono e peso.';

  @override
  String get addHabits => 'Adicionar';

  @override
  String get manageHabits => 'Gerenciar';

  @override
  String get habitsUpdated => 'Hábitos atualizados';

  @override
  String get saveHabitsError => 'Não foi possível salvar os hábitos';

  @override
  String get configureMacros => 'Configurar macros';

  @override
  String get savingMacrosConfigures =>
      'Salvar os macros marca este cliente como configurado.';

  @override
  String workoutLogTitle(String date) {
    return 'Registro de treino ($date)';
  }

  @override
  String get noWorkoutSelectedDay =>
      'Nenhum treino atribuído para o dia selecionado.';

  @override
  String get updateBtn => 'Atualizar';

  @override
  String get yourNote => 'Sua nota';

  @override
  String get leaveANote => 'Deixe uma nota';

  @override
  String get savedLabel => 'Salvo';

  @override
  String writeFeedbackFor(String name) {
    return 'Escreva um feedback para $name…';
  }

  @override
  String get editingPastDay => 'Editando um dia anterior';

  @override
  String get updateNote => 'Atualizar nota';

  @override
  String get saveNote => 'Salvar nota';

  @override
  String get relToday => 'hoje';

  @override
  String get relTomorrow => 'amanhã';

  @override
  String get relYesterday => 'ontem';

  @override
  String forClientDate(String name, String date) {
    return 'Para $name · $date';
  }

  @override
  String get chooseAWorkout => 'Escolha um treino';

  @override
  String get includesLabel => 'Inclui';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercícios',
      one: '1 exercício',
    );
    return '$_temp0';
  }

  @override
  String get habitsManagerBody =>
      'Hábitos que este cliente marca todo dia, junto com água, sono e peso.';

  @override
  String get addAHabit => 'Adicionar um hábito';

  @override
  String get habitNameHint => 'ex. 10 mil passos';

  @override
  String get saveHabits => 'Salvar hábitos';

  @override
  String get plansSubtitle => 'Escolha o plano ideal para sua carteira';

  @override
  String get planCurrent => 'Plano atual';

  @override
  String get planMostPopular => 'Mais popular';

  @override
  String get planPerMonth => '/mês';

  @override
  String planChoose(String plan) {
    return 'Escolher $plan';
  }

  @override
  String planClientsUpTo(int count) {
    return 'Até $count clientes';
  }

  @override
  String get planClientsUnlimited => 'Clientes ilimitados';

  @override
  String planUsageLimited(int used, int total) {
    return '$used / $total clientes';
  }

  @override
  String get planFreeTagline => 'Comece com alguns clientes';

  @override
  String get planProTagline => 'Para coaches em crescimento';

  @override
  String get planStudioTagline => 'Para coaches estabelecidos, sem limites';

  @override
  String get featureMonitoring => 'Monitoramento diário de clientes';

  @override
  String get featureWorkoutLibrary => 'Biblioteca de treinos e programação';

  @override
  String get featureAiMeal => 'Escaneamento de refeições com IA incluído';

  @override
  String get featureRecurring => 'Programação semanal recorrente';

  @override
  String get featureCustomHabits => 'Acompanhamento de hábitos personalizados';

  @override
  String get featureAnalytics => 'Análises de progresso';

  @override
  String get featurePrioritySupport => 'Suporte prioritário';

  @override
  String get featureEverythingFree => 'Tudo do plano Grátis';

  @override
  String get featureEverythingPro => 'Tudo do plano Pro';

  @override
  String get upgradeContactTitle => 'Faça upgrade do seu plano';

  @override
  String upgradeContactBody(String plan) {
    return 'O pagamento online chega em breve. Fale conosco e ativaremos seu plano $plan na hora.';
  }

  @override
  String get contactUs => 'Fale conosco';

  @override
  String get clientLimitTitle => 'Limite de clientes atingido';

  @override
  String clientLimitBody(int count) {
    return 'Você atingiu o limite de $count clientes do seu plano. Faça upgrade para adicionar mais.';
  }

  @override
  String get viewPlans => 'Ver planos';

  @override
  String get deleteAccount => 'Excluir conta';

  @override
  String get deleteAccountWarning =>
      'Isto apaga permanentemente sua conta e todos os seus dados. Esta ação não pode ser desfeita.';

  @override
  String get deleteAccountConfirmPassword => 'Digite sua senha para confirmar';

  @override
  String get reminderTitle => 'Hora de registrar seu dia';

  @override
  String get reminderBody => 'Registre suas refeições e hábitos no Valence.';

  @override
  String get reminderTimeLabel => 'Horário do lembrete';

  @override
  String get remindersPermissionDenied =>
      'Ative as notificações nas configurações do seu dispositivo para receber lembretes.';

  @override
  String get intakePriorTitle => 'Já fez acompanhamento antes?';

  @override
  String get intakePriorSubtitle =>
      'Sem julgamentos — só nos ajuda a definir o ritmo certo.';

  @override
  String get priorNever => 'Nunca';

  @override
  String get priorStopped => 'Tentei, não mantive';

  @override
  String get priorCurrent => 'Já faço';

  @override
  String get onboardCommitTitle => 'Pronto para se comprometer?';

  @override
  String get onboardCommitSubtitle =>
      'Pequenos registos diários somam. Apareça por si e o seu plano faz o resto.';

  @override
  String get onboardCommitCta => 'Estou dentro';

  @override
  String get createAccountSavePlan => 'Criar conta para guardar o meu plano';

  @override
  String get planGoalLabel => 'O seu objetivo';

  @override
  String planReachBy(String weight, String date) {
    return 'Atingir $weight até $date';
  }

  @override
  String get roleCoachDesc =>
      'Faça a gestão dos seus clientes, crie planos e acompanhe o progresso de todos.';

  @override
  String get roleClientDesc =>
      'Registe as suas refeições com IA e siga o plano do seu coach.';

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
    return '$amount $unit para ganhar';
  }

  @override
  String get intakeAgeInsight =>
      'A sua idade influencia quantas calorias queima em repouso.';

  @override
  String get intakeHeightInsight =>
      'A sua altura combina-se com o seu peso para estimar o seu metabolismo.';

  @override
  String get intakeWeightInsight =>
      'Este é o seu ponto de partida — vamos acompanhar cada passo a partir daqui.';

  @override
  String get intakeTargetInsight =>
      'Um ritmo gradual é a forma mais sustentável de lá chegar.';

  @override
  String get intakeActivityInsight =>
      'Define o seu gasto diário com o método Mifflin-St Jeor usado por nutricionistas.';

  @override
  String get ciSpecialtiesInsight =>
      'Adaptamos os modelos e as dicas que sugerimos ao seu foco.';

  @override
  String get ciExperienceInsight =>
      'Isto define predefinições sensatas — pode alterar tudo mais tarde.';

  @override
  String get ciRosterInsight =>
      'O Valence cresce consigo — comece grátis com os seus primeiros 3 clientes.';

  @override
  String get ciPriorInsight => 'Vamos ajudá-lo a juntar tudo num só lugar.';

  @override
  String get purchaseSuccess => 'Atualizado — aproveite!';

  @override
  String get purchaseFailed => 'A compra não foi concluída. Tente novamente.';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get authErrInviteRequired =>
      'É necessário um código de convite para entrar';

  @override
  String get authErrInviteInvalid =>
      'Esse código de convite é inválido, expirou ou já foi usado';

  @override
  String get authErrEmailInUse =>
      'Esse e-mail já está registrado — tente fazer login';

  @override
  String get authErrWeakPassword =>
      'A senha é muito fraca — use pelo menos 6 caracteres';

  @override
  String get authErrInvalidEmail => 'Esse endereço de e-mail não é válido';

  @override
  String get authErrWrongCredentials => 'E-mail ou senha incorretos';

  @override
  String get authErrTooManyRequests =>
      'Muitas tentativas — aguarde um momento e tente novamente';

  @override
  String get authErrNetwork =>
      'Erro de rede — verifique sua conexão e tente novamente';

  @override
  String get authErrUserDataNotFound =>
      'Os dados da sua conta não foram encontrados';

  @override
  String get authErrNoEmailOnFile => 'Nenhum e-mail registrado';

  @override
  String get authErrNotLoggedIn => 'Você precisa estar conectado';

  @override
  String get authErrClientsOnly =>
      'Apenas contas de cliente podem vincular um treinador';

  @override
  String get authErrLinkCoachFailed =>
      'Não foi possível vincular seu treinador — tente novamente';

  @override
  String get authErrIncorrectPassword => 'Senha incorreta';

  @override
  String get authErrRecentLogin => 'Saia, entre novamente e tente de novo';

  @override
  String get authErrResetFailed =>
      'Não foi possível enviar o e-mail de redefinição';

  @override
  String get authErrSignupFailed =>
      'Não foi possível criar sua conta — tente novamente';

  @override
  String get authErrSigninFailed =>
      'Não foi possível fazer login — tente novamente';

  @override
  String get authErrDeleteFailed =>
      'Não foi possível excluir sua conta — tente novamente';

  @override
  String get authErrUnknown => 'Algo deu errado — tente novamente';

  @override
  String quietForDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias sem atividade',
      one: '1 dia sem atividade',
    );
    return '$_temp0';
  }

  @override
  String get statusNew => 'Novo';

  @override
  String get joinedRecently => 'Recém-chegado — aguardando o primeiro registro';

  @override
  String consistencyThisWeek(int pct) {
    return '$pct% de consistência esta semana';
  }

  @override
  String get coverRolePrompt => 'Como você vai usar o Valence?';

  @override
  String get welcomeTitle => 'Bem-vindo ao Valence';

  @override
  String get clientIntroTitle => 'Seu treinador, no seu bolso';

  @override
  String get coachIntroTitle => 'Todo o seu coaching num só lugar';

  @override
  String get introSubtitle => 'Veja como o Valence funciona para você.';

  @override
  String get roleAthlete => 'Atleta';

  @override
  String get clientIntroCta => 'Criar meu plano';

  @override
  String get coachIntroCta => 'Configurar meu perfil';

  @override
  String get coachSetupReady =>
      'Seu espaço de coaching está pronto. Convide seu primeiro cliente para começar.';

  @override
  String confidenceNote(String word, int score) {
    return 'Confiança $word ($score/100) — toque em Ajustar para afinar.';
  }

  @override
  String get centerYourPlate => 'Centralize o seu prato';

  @override
  String get portionLabel => 'Porção';

  @override
  String kcalLeftToday(int n) {
    return 'Restam $n kcal hoje';
  }

  @override
  String kcalOverToday(int n) {
    return '$n kcal acima hoje';
  }

  @override
  String get describeCardSub => 'Escreva — a IA faz as contas';

  @override
  String get manualCardSub => 'Sabe os números? Insira você mesmo';

  @override
  String get flashLabel => 'Flash';

  @override
  String get galleryCardSub => 'Escolha uma foto existente';

  @override
  String get scanCardSub => 'Aponte, fotografe — registrado';

  @override
  String get aiInsightsTitle => 'Análise com IA';

  @override
  String get aiInsightsTease =>
      'Veja o que está funcionando e o que está falhando esta semana, em comparação com a semana passada.';

  @override
  String get aiInsightsUnlock => 'Desbloquear com Pro';

  @override
  String get aiInsightsWins => 'O que está funcionando';

  @override
  String get aiInsightsRisks => 'Precisa de atenção';

  @override
  String get aiInsightsActions => 'O que você pode fazer';

  @override
  String get aiInsightsReading => 'Lendo os registros desta semana…';

  @override
  String get aiInsightsRefresh => 'Analisar novamente';

  @override
  String get aiInsightsUpToDate =>
      'Nada novo registrado desde a última análise.';

  @override
  String get aiInsightsNoData =>
      'Ainda não há dados suficientes. Volte após mais alguns dias de registro.';

  @override
  String get aiInsightsError =>
      'Não foi possível analisar agora. Tente novamente.';

  @override
  String get aiInsightsDisclaimer =>
      'Observações a partir dos dados registrados — não é conselho médico. Confirme antes de agir.';

  @override
  String get aiAnalyzedToday => 'Analisado hoje';

  @override
  String get aiAnalyzedYesterday => 'Analisado ontem';

  @override
  String aiAnalyzedDaysAgo(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Analisado há $days dias',
    );
    return '$_temp0';
  }

  @override
  String aiInsightsConfidence(String word) {
    return 'Confiança $word';
  }

  @override
  String get aiInsightsOutdated =>
      'Isto cobre uma semana que já passou. Analise novamente para a semana atual.';

  @override
  String aiInsightsOtherLanguage(String language) {
    return 'Escrito em outro idioma. Analise novamente para obtê-lo em $language.';
  }

  @override
  String get shareWinCta => 'Compartilhar meu progresso';

  @override
  String get shareWinTitle => 'Seu progresso';

  @override
  String get shareWinNothingYet =>
      'Registre mais alguns dias e seu cartão de progresso estará pronto para compartilhar.';

  @override
  String shareWinLost(String amount, String unit) {
    return '$amount $unit a menos';
  }

  @override
  String shareWinGained(String amount, String unit) {
    return '$amount $unit ganhos';
  }

  @override
  String shareWinInWeeks(num weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'em $weeks semanas',
      one: 'em 1 semana',
    );
    return '$_temp0';
  }

  @override
  String shareWinStreakHero(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias seguidos',
      one: '1 dia seguido',
    );
    return '$_temp0';
  }

  @override
  String get shareWinShowedUp => 'Presente';

  @override
  String get shareWinStatStreak => 'Sequência';

  @override
  String get shareWinStatDays => 'Dias registrados';

  @override
  String get shareWinStatSessions => 'Sessões';

  @override
  String shareWinCoachedBy(String name) {
    return 'Treinado por $name';
  }

  @override
  String get shareWinFailed =>
      'Não foi possível criar a imagem. Tente novamente.';

  @override
  String get featureAiInsights =>
      'Análises de clientes com IA, com os números por trás';

  @override
  String get featureLibraryRecurring =>
      'Biblioteca, programação e treinos recorrentes';

  @override
  String get featureHabitsAnalytics =>
      'Hábitos personalizados e análises de progresso';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get undo => 'Desfazer';

  @override
  String get habitRemoved => 'Hábito removido';

  @override
  String assignSkippedPast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias desta semana já passaram',
      one: '1 dia desta semana já passou',
    );
    return '$_temp0';
  }

  @override
  String get assignChooseClient => 'Escolha um cliente';

  @override
  String get unitLiters => 'L';

  @override
  String get unitGrams => 'g';

  @override
  String get noWorkoutToday => 'Nenhum treino atribuído para hoje.';

  @override
  String get noWorkoutSwapHint =>
      'Nenhum treino atribuído para este dia. Use «Trocar treino» acima para definir um.';

  @override
  String get readingYourDescription => 'Lendo a sua descrição…';

  @override
  String get mealsOnDay => 'Refeições';
}
