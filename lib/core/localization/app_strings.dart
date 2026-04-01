enum AppLanguage { ru, en, ar }

class AppStrings {
  final AppLanguage language;
  const AppStrings(this.language);

  static AppLanguage currentLanguage = AppLanguage.ru;

  // --- Статические методы для моделей ---
  static String mapCategory(String key) {
    final map = {
      'admin': {
        AppLanguage.ru: 'Администратор',
        AppLanguage.en: 'Administrator',
        AppLanguage.ar: 'مدير'
      },
      'sales': {
        AppLanguage.ru: 'Продавец',
        AppLanguage.en: 'Sales Bot',
        AppLanguage.ar: 'بوت مبيعات'
      },
      'support': {
        AppLanguage.ru: 'Поддержка',
        AppLanguage.en: 'Support Bot',
        AppLanguage.ar: 'بوت دعم'
      },
    };
    return map[key.trim()]?[currentLanguage] ?? key;
  }

  static String translateFeature(String label) {
    final map = {
      'Запись клиентов': {
        AppLanguage.en: 'Client Booking',
        AppLanguage.ar: 'حجز العملاء'
      },
      'Напоминания': {AppLanguage.en: 'Reminders', AppLanguage.ar: 'تذكيرات'},
      'Отмена записей': {
        AppLanguage.en: 'Cancel Bookings',
        AppLanguage.ar: 'إلغاء الحجوزات'
      },
      'Уведомления': {
        AppLanguage.en: 'Notifications',
        AppLanguage.ar: 'إشعارات'
      },
      'Консультация': {
        AppLanguage.en: 'Consultation',
        AppLanguage.ar: 'استشارة'
      },
      'Квалификация лидов': {
        AppLanguage.en: 'Lead Qualification',
        AppLanguage.ar: 'تأهيل العملاء المحتملين'
      },
      'Работа с возражениями': {
        AppLanguage.en: 'Handling Objections',
        AppLanguage.ar: 'التعامل со встречными предложениями'
      },
      'Передача менеджеру': {
        AppLanguage.en: 'Transfer to Manager',
        AppLanguage.ar: 'تحويل للمدير'
      },
    };
    return map[label]?[currentLanguage] ?? label;
  }

  // --- Навигация ---
  String get navShop => _map({
        AppLanguage.ru: 'Магазин',
        AppLanguage.en: 'Shop',
        AppLanguage.ar: 'المتجر'
      });
  String get navMyBots => _map({
        AppLanguage.ru: 'Мои боты',
        AppLanguage.en: 'My Bots',
        AppLanguage.ar: 'بوتاتي'
      });
  String get navSettings => _map({
        AppLanguage.ru: 'Настройки',
        AppLanguage.en: 'Settings',
        AppLanguage.ar: 'الإعدادات'
      });
  String get navSupport => _map({
        AppLanguage.ru: 'Поддержка',
        AppLanguage.en: 'Support',
        AppLanguage.ar: 'الدعم'
      });

  // --- Auth ---
  String get authLogin => _map({
        AppLanguage.ru: 'Войти',
        AppLanguage.en: 'Login',
        AppLanguage.ar: 'تسجيل الدخول'
      });
  String get authRegistration => _map({
        AppLanguage.ru: 'Регистрация',
        AppLanguage.en: 'Registration',
        AppLanguage.ar: 'إنشاء حساب'
      });
  String get authPassword => _map({
        AppLanguage.ru: 'Пароль',
        AppLanguage.en: 'Password',
        AppLanguage.ar: 'كلمة المرور'
      });
  String get authForgotPassword => _map({
        AppLanguage.ru: 'Забыли пароль?',
        AppLanguage.en: 'Forgot password?',
        AppLanguage.ar: 'هل نسит كلمة المرور؟'
      });
  String get authNoAccount => _map({
        AppLanguage.ru: 'Нет аккаунта? Регистрация',
        AppLanguage.en: 'No account? Register',
        AppLanguage.ar: 'ليس لديك حساب؟ سجل الآن'
      });
  String get authHasAccount => _map({
        AppLanguage.ru: 'Уже есть аккаунт? Войти',
        AppLanguage.en: 'Already have an account? Login',
        AppLanguage.ar: 'لديك حساب بالفعل؟ دخول'
      });
  String get authGoogle => _map({
        AppLanguage.ru: 'Войти через Google',
        AppLanguage.en: 'Sign in with Google',
        AppLanguage.ar: 'تسجيل الدخول عبر Google'
      });
  String get authFieldsRequired => _map({
        AppLanguage.ru: 'Заполните все поля',
        AppLanguage.en: 'Fill all fields',
        AppLanguage.ar: 'يرجى ملء جميع الحقول'
      });
  String get authCheckEmail => _map({
        AppLanguage.ru: 'Проверьте почту для подтверждения',
        AppLanguage.en: 'Check your email for confirmation',
        AppLanguage.ar: 'تحقق من بريدك الإلكتروني للتأكيد'
      });
  String get authError => _map({
        AppLanguage.ru: 'Произошла ошибка',
        AppLanguage.en: 'An error occurred',
        AppLanguage.ar: 'حدث خطأ ما'
      });
  String get authOr =>
      _map({AppLanguage.ru: 'или', AppLanguage.en: 'or', AppLanguage.ar: 'أو'});

  // --- Каталог ---
  String get catDetails => _map({
        AppLanguage.ru: 'Подробнее',
        AppLanguage.en: 'Details',
        AppLanguage.ar: 'تفاصيل'
      });
  String get catDescription => _map({
        AppLanguage.ru: 'Описание',
        AppLanguage.en: 'Description',
        AppLanguage.ar: 'وصف'
      });
  String get catFunctions => _map({
        AppLanguage.ru: 'Функции',
        AppLanguage.en: 'Functions',
        AppLanguage.ar: 'وظائف'
      });
  String get catEmpty => _map({
        AppLanguage.ru: 'Список пуст',
        AppLanguage.en: 'List is empty',
        AppLanguage.ar: 'القائمة فارغة'
      });
  String get botConnect => _map({
        AppLanguage.ru: 'Подключить',
        AppLanguage.en: 'Connect',
        AppLanguage.ar: 'اتصال'
      });

  // --- Оплата ---
  String get paySubscription => _map({
        AppLanguage.ru: 'Подписка',
        AppLanguage.en: 'Subscription',
        AppLanguage.ar: 'اشتراك'
      });
  String get payMonth => _map(
      {AppLanguage.ru: 'мес', AppLanguage.en: 'month', AppLanguage.ar: 'شهر'});
  String get payYear => _map(
      {AppLanguage.ru: 'год', AppLanguage.en: 'year', AppLanguage.ar: 'сنة'});
  String get payAction => _map({
        AppLanguage.ru: 'ПОДКЛЮЧИТЬ ЗА',
        AppLanguage.en: 'CONNECT FOR',
        AppLanguage.ar: 'اتصال مقابل'
      });
  String get paySuccessTitle => _map({
        AppLanguage.ru: 'Оплата успешна',
        AppLanguage.en: 'Payment successful',
        AppLanguage.ar: 'تم الدفع بنجاح'
      });
  String get paySuccessBody => _map({
        AppLanguage.ru: 'Подписка активирована (тестовый режим)',
        AppLanguage.en: 'Subscription activated (test mode)',
        AppLanguage.ar: 'تم تفعيل الاشتراك'
      });
  String get payContinue => _map({
        AppLanguage.ru: 'Продолжить',
        AppLanguage.en: 'Continue',
        AppLanguage.ar: 'استمرار'
      });

  // --- Подключение бота ---
  String get connStep1Title => _map({
        AppLanguage.ru: 'Шаг 1: Подключение Telegram',
        AppLanguage.en: 'Step 1: Telegram Connection',
        AppLanguage.ar: 'الخطوة ١'
      });
  String get connStep2Title => _map({
        AppLanguage.ru: 'Шаг 2: Настройка сервера',
        AppLanguage.en: 'Step 2: Server Setup',
        AppLanguage.ar: 'الخطوة ٢'
      });
  String get connTelegramInstrTitle => _map({
        AppLanguage.ru: 'ИНСТРУКЦИЯ',
        AppLanguage.en: 'INSTRUCTIONS',
        AppLanguage.ar: 'تعليمات'
      });
  String get connTelegramInstrBody => _map({
        AppLanguage.ru:
            '1. Откройте @BotFather.\n2. Сгенерируйте НОВЫЙ токен.\n3. Вставьте его ниже.',
        AppLanguage.en:
            '1. Open @BotFather.\n2. Generate a NEW token.\n3. Paste it below.',
        AppLanguage.ar:
            '١. افتح BotFather@.\n٢. ولد رمزاً جديداً.\n٣. الصقه أدناه.'
      });
  String get connTokenLabel => _map({
        AppLanguage.ru: 'API ТОКЕН',
        AppLanguage.en: 'API TOKEN',
        AppLanguage.ar: 'رمز API'
      });
  String get connBtnContinue => _map({
        AppLanguage.ru: 'ПРОВЕРИТЬ И ПРОДОЛЖИТЬ',
        AppLanguage.en: 'CHECK AND CONTINUE',
        AppLanguage.ar: 'التحقق والاستمرار'
      });
  String get connErrorNoToken => _map({
        AppLanguage.ru: 'Пожалуйста, введите токен Telegram',
        AppLanguage.en: 'Please enter Telegram token',
        AppLanguage.ar: 'يرجى إدخال الرمز'
      });
  String get connRailwayInstrTitle => _map({
        AppLanguage.ru: 'ИНСТРУКЦИЯ RAILWAY',
        AppLanguage.en: 'RAILWAY INSTRUCTIONS',
        AppLanguage.ar: 'تعليمات Railway'
      });
  String get connRailwayInstrBody => _map({
        AppLanguage.ru:
            '1. Войдите в Railway.\n2. Создайте API Token.\n3. Скопируйте Workspace ID.',
        AppLanguage.en:
            '1. Log in to Railway.\n2. Create an API Token.\n3. Copy Workspace ID.',
        AppLanguage.ar:
            '١. سجل في Railway.\n٢. أنشئ رمز API.\n٣. انسخ معرف مساحة العمل.'
      });
  String get connRailwayTokenLabel => _map({
        AppLanguage.ru: 'RAILWAY API ТОКЕН',
        AppLanguage.en: 'RAILWAY API TOKEN',
        AppLanguage.ar: 'رمز Railway'
      });
  String get connWorkspaceLabel => _map({
        AppLanguage.ru: 'WORKSPACE ID',
        AppLanguage.en: 'WORKSPACE ID',
        AppLanguage.ar: 'معرف مساحة العمل'
      });
  String get connBtnDeploy => _map({
        AppLanguage.ru: 'ПОДКЛЮЧИТЬ И ЗАДЕПЛОИТЬ',
        AppLanguage.en: 'CONNECT AND DEPLOY',
        AppLanguage.ar: 'اتصال ونشر'
      });
  String get connErrorNoRailway => _map({
        AppLanguage.ru: 'Пожалуйста, заполните данные Railway',
        AppLanguage.en: 'Please fill Railway data',
        AppLanguage.ar: 'يرجى ملء البيانات'
      });
  String get connSuccessDeploy => _map({
        AppLanguage.ru: 'Бот успешно отправлен на деплой!',
        AppLanguage.en: 'Bot sent for deployment!',
        AppLanguage.ar: 'تم إرسال البот للنشر!'
      });

  // --- Мои боты ---
  String get myBotsLocked => _map({
        AppLanguage.ru: 'Войдите чтобы увидеть ваших ботов',
        AppLanguage.en: 'Login to see your bots',
        AppLanguage.ar: 'سجل الدخول لرؤية بوتاتك'
      });
  String get myBotsEmpty => _map({
        AppLanguage.ru: 'У вас пока нет подключённых ботов',
        AppLanguage.en: 'You have no connected bots yet',
        AppLanguage.ar: 'ليس لديك بوتات متصلة'
      });
  String get myBotsGoCatalog => _map({
        AppLanguage.ru: 'Перейти в каталог',
        AppLanguage.en: 'Go to catalog',
        AppLanguage.ar: 'الذهاب إلى المتجر'
      });
  String get bmManage => _map({
        AppLanguage.ru: 'Управление',
        AppLanguage.en: 'Manage',
        AppLanguage.ar: 'إدارة'
      });
  String get bmStatusOff => _map({
        AppLanguage.ru: 'Отключён',
        AppLanguage.en: 'Disabled',
        AppLanguage.ar: 'معطل'
      });
  String get bmStatusActive => _map({
        AppLanguage.ru: 'В работе',
        AppLanguage.en: 'Active',
        AppLanguage.ar: 'نشط'
      });
  String get bmStatusSetup => _map({
        AppLanguage.ru: 'Настройка',
        AppLanguage.en: 'Setup',
        AppLanguage.ar: 'إعداد'
      });

  // --- Настройки ---
  String get setAccount => _map({
        AppLanguage.ru: 'Аккаунт',
        AppLanguage.en: 'Account',
        AppLanguage.ar: 'الحساب'
      });
  String get setLanguage => _map({
        AppLanguage.ru: 'Язык',
        AppLanguage.en: 'Language',
        AppLanguage.ar: 'اللغة'
      });
  String get setNotifications => _map({
        AppLanguage.ru: 'Уведомления',
        AppLanguage.en: 'Notifications',
        AppLanguage.ar: 'الإشعارات'
      });
  String get setAbout => _map({
        AppLanguage.ru: 'О приложении',
        AppLanguage.en: 'About app',
        AppLanguage.ar: 'حول التطبيق'
      });
  String get setVersion => _map({
        AppLanguage.ru: 'Версия',
        AppLanguage.en: 'Version',
        AppLanguage.ar: 'الإصдар'
      });
  String get setNotifSettings => _map({
        AppLanguage.ru: 'Настройки уведомлений',
        AppLanguage.en: 'Notification settings',
        AppLanguage.ar: 'إعدادات الإشعارات'
      });
  String get setSubscription => _map({
        AppLanguage.ru: 'Подписка',
        AppLanguage.en: 'Subscription',
        AppLanguage.ar: 'اشتراك'
      });
  String get setSubFree => _map({
        AppLanguage.ru: 'Бесплатный план',
        AppLanguage.en: 'Free Plan',
        AppLanguage.ar: 'خطة مجانية'
      });
  String get setSubPro => _map({
        AppLanguage.ru: 'Pro план',
        AppLanguage.en: 'Pro Plan',
        AppLanguage.ar: 'خطة برو'
      });
  String get setPrivacy => _map({
        AppLanguage.ru: 'Политика конфиденциальности',
        AppLanguage.en: 'Privacy Policy',
        AppLanguage.ar: 'سياسة الخصوصية'
      });
  String get setTerms => _map({
        AppLanguage.ru: 'Условия использования',
        AppLanguage.en: 'Terms of Service',
        AppLanguage.ar: 'شروط الخدمة'
      });

  // --- Профиль ---
  String get profTitle => _map({
        AppLanguage.ru: 'Профиль',
        AppLanguage.en: 'Profile',
        AppLanguage.ar: 'الملف الشخصي'
      });
  String get profChangePass => _map({
        AppLanguage.ru: 'Сменить пароль',
        AppLanguage.en: 'Change password',
        AppLanguage.ar: 'تغيير كلمة المرور'
      });
  String get profLogout => _map({
        AppLanguage.ru: 'Выйти из аккаунта',
        AppLanguage.en: 'Sign out',
        AppLanguage.ar: 'تسجيل الخروج'
      });
  String get profCurrentPass => _map({
        AppLanguage.ru: 'Текущий пароль',
        AppLanguage.en: 'Current password',
        AppLanguage.ar: 'كلمة المرور الحالية'
      });
  String get profNewPass => _map({
        AppLanguage.ru: 'Новый пароль',
        AppLanguage.en: 'New password',
        AppLanguage.ar: 'كلمة المرور الجديدة'
      });
  String get profRepeatPass => _map({
        AppLanguage.ru: 'Повторите новый пароль',
        AppLanguage.en: 'Repeat new password',
        AppLanguage.ar: 'تأكيد كلمة المرور الجديدة'
      });
  String get profCancel => _map({
        AppLanguage.ru: 'Отмена',
        AppLanguage.en: 'Cancel',
        AppLanguage.ar: 'إлгاء'
      });
  String get profSave => _map({
        AppLanguage.ru: 'Сохранить',
        AppLanguage.en: 'Save',
        AppLanguage.ar: 'حفظ'
      });
  String get profPassMismatch => _map({
        AppLanguage.ru: 'Пароли не совпадают',
        AppLanguage.en: 'Passwords do not match',
        AppLanguage.ar: 'كلمات المرور غير متطابقة'
      });
  String get profPassLength => _map({
        AppLanguage.ru: 'Пароль должен быть минимум 6 символов',
        AppLanguage.en: 'Min 6 chars',
        AppLanguage.ar: '٦ أحرف على الأقل'
      });
  String get profPassSuccess => _map({
        AppLanguage.ru: 'Пароль успешно изменён',
        AppLanguage.en: 'Password changed',
        AppLanguage.ar: 'تم تغيير كلمة المرور'
      });

  // --- Уведомления ---
  String get notifPush => _map({
        AppLanguage.ru: 'Push-уведомления',
        AppLanguage.en: 'Push notifications',
        AppLanguage.ar: 'إشعارات'
      });
  String get notifPushSub => _map({
        AppLanguage.ru: 'Получать уведомления на устройство',
        AppLanguage.en: 'On device',
        AppLanguage.ar: 'على الجهاز'
      });
  String get notifEmail => _map({
        AppLanguage.ru: 'Email-уведомления',
        AppLanguage.en: 'Email notifications',
        AppLanguage.ar: 'إشعارات البريد'
      });
  String get notifEmailSub => _map({
        AppLanguage.ru: 'Получать уведомления на почту',
        AppLanguage.en: 'By email',
        AppLanguage.ar: 'عبر البريد'
      });

  // --- Управление ботом ---
  String get bmTitle => _map({
        AppLanguage.ru: 'Управление ботом',
        AppLanguage.en: 'Bot management',
        AppLanguage.ar: 'إدارة البوت'
      });
  String get bmActions => _map({
        AppLanguage.ru: 'ДЕЙСТВИЯ',
        AppLanguage.en: 'ACTIONS',
        AppLanguage.ar: 'الإجراءات'
      });
  String get bmAppointments => _map({
        AppLanguage.ru: 'ЗАПИСИ',
        AppLanguage.en: 'APPOINTMENTS',
        AppLanguage.ar: 'السجلات'
      });
  String get bmPromptSettings => _map({
        AppLanguage.ru: 'НАСТРОЙКИ ПРОМПТА',
        AppLanguage.en: 'PROMPT SETTINGS',
        AppLanguage.ar: 'إعدادات الأوامر'
      });
  String get bmActivateGroup => _map({
        AppLanguage.ru: 'АКТИВИРОВАТЬ ГРУППУ',
        AppLanguage.en: 'ACTIVATE GROUP',
        AppLanguage.ar: 'تفعيل المجموعة'
      });
  String get bmActive => _map({
        AppLanguage.ru: 'Бот активен',
        AppLanguage.en: 'Bot active',
        AppLanguage.ar: 'البوت مفعل'
      });
  String get bmSetupRequired => _map({
        AppLanguage.ru: 'Требуется настройка',
        AppLanguage.en: 'Setup required',
        AppLanguage.ar: 'مطلوب إعداد'
      });
  String get bmReady => _map({
        AppLanguage.ru: 'Бот готов к приему заказов',
        AppLanguage.en: 'Bot ready',
        AppLanguage.ar: 'البوت جاهز'
      });
  String get bmBindGroup => _map({
        AppLanguage.ru: 'Привяжите Telegram группу',
        AppLanguage.en: 'Bind group',
        AppLanguage.ar: 'ربط المجموعة'
      });

  String _map(Map<AppLanguage, String> values) =>
      values[language] ?? values[AppLanguage.ru]!;
}
