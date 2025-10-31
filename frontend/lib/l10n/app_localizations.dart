import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('ar'), // العربية
  ];

  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString('assets/l10n/${locale.languageCode}.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      return true;
    } catch (e) {
      debugPrint('❌ : $e');
      // تحميل اللغة الافتراضية (العربية)
      String jsonString = await rootBundle.loadString('assets/l10n/ar.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      return true;
    }
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // اختصار للترجمة
  String t(String key) => translate(key);

  // الترجمات الشائعة
  String get appName => translate('app_name');
  String get myAccount => translate('my_account');
  String get editProfile => translate('edit_profile');
  String get language => translate('language');
  String get aboutApp => translate('about_app');
  String get logout => translate('logout');
  String get logoutConfirm => translate('logout_confirm');
  String get logoutMessage => translate('logout_message');
  String get cancel => translate('cancel');
  String get orders => translate('orders');
  String get profits => translate('profits');
  String get joinedOn => translate('joined_on');
  String get arabic => translate('arabic');
  String get english => translate('english');
  String get kurdish => translate('kurdish');
  String get selectLanguage => translate('select_language');
  String get home => translate('home');
  String get products => translate('products');
  String get myOrders => translate('my_orders');
  String get settings => translate('settings');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get search => translate('search');
  String get filter => translate('filter');
  String get sort => translate('sort');
  String get total => translate('total');
  String get status => translate('status');
  String get date => translate('date');
  String get price => translate('price');
  String get quantity => translate('quantity');
  String get description => translate('description');
  String get name => translate('name');
  String get phone => translate('phone');
  String get email => translate('email');
  String get address => translate('address');
  String get city => translate('city');
  String get notes => translate('notes');
  String get confirm => translate('confirm');
  String get back => translate('back');
  String get next => translate('next');
  String get previous => translate('previous');
  String get submit => translate('submit');
  String get close => translate('close');
  String get open => translate('open');
  String get view => translate('view');
  String get download => translate('download');
  String get upload => translate('upload');
  String get share => translate('share');
  String get copy => translate('copy');
  String get paste => translate('paste');
  String get cut => translate('cut');
  String get selectAll => translate('select_all');
  String get clear => translate('clear');
  String get refresh => translate('refresh');
  String get retry => translate('retry');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  String get done => translate('done');
  String get skip => translate('skip');
  String get later => translate('later');
  String get now => translate('now');
  String get today => translate('today');
  String get yesterday => translate('yesterday');
  String get tomorrow => translate('tomorrow');
  String get week => translate('week');
  String get month => translate('month');
  String get year => translate('year');
  String get all => translate('all');
  String get none => translate('none');
  String get other => translate('other');
  String get more => translate('more');
  String get less => translate('less');
  String get show => translate('show');
  String get hide => translate('hide');
  String get enable => translate('enable');
  String get disable => translate('disable');
  String get on => translate('on');
  String get off => translate('off');
  String get active => translate('active');
  String get inactive => translate('inactive');
  String get online => translate('online');
  String get offline => translate('offline');
  String get available => translate('available');
  String get unavailable => translate('unavailable');
  String get pending => translate('pending');
  String get approved => translate('approved');
  String get rejected => translate('rejected');
  String get completed => translate('completed');
  String get cancelled => translate('cancelled');
  String get failed => translate('failed');
  String get processing => translate('processing');
  String get delivered => translate('delivered');
  String get shipping => translate('shipping');
  String get payment => translate('payment');
  String get paid => translate('paid');
  String get unpaid => translate('unpaid');
  String get refund => translate('refund');
  String get refunded => translate('refunded');
  String get discount => translate('discount');
  String get tax => translate('tax');
  String get subtotal => translate('subtotal');
  String get grandTotal => translate('grand_total');
  String get customer => translate('customer');
  String get seller => translate('seller');
  String get admin => translate('admin');
  String get user => translate('user');
  String get guest => translate('guest');
  String get profile => translate('profile');
  String get account => translate('account');
  String get dashboard => translate('dashboard');
  String get statistics => translate('statistics');
  String get reports => translate('reports');
  String get notifications => translate('notifications');
  String get messages => translate('messages');
  String get inbox => translate('inbox');
  String get sent => translate('sent');
  String get draft => translate('draft');
  String get trash => translate('trash');
  String get archive => translate('archive');
  String get favorite => translate('favorite');
  String get bookmark => translate('bookmark');
  String get tag => translate('tag');
  String get category => translate('category');
  String get subcategory => translate('subcategory');
  String get brand => translate('brand');
  String get model => translate('model');
  String get color => translate('color');
  String get size => translate('size');
  String get weight => translate('weight');
  String get dimensions => translate('dimensions');
  String get material => translate('material');
  String get warranty => translate('warranty');
  String get stock => translate('stock');
  String get inStock => translate('in_stock');
  String get outOfStock => translate('out_of_stock');
  String get lowStock => translate('low_stock');
  String get preOrder => translate('pre_order');
  String get backOrder => translate('back_order');
  String get newArrival => translate('new_arrival');
  String get bestSeller => translate('best_seller');
  String get featured => translate('featured');
  String get recommended => translate('recommended');
  String get popular => translate('popular');
  String get trending => translate('trending');
  String get sale => translate('sale');
  String get clearance => translate('clearance');
  String get limitedOffer => translate('limited_offer');
  String get freeShipping => translate('free_shipping');
  String get cashOnDelivery => translate('cash_on_delivery');
  String get returnPolicy => translate('return_policy');
  String get termsAndConditions => translate('terms_and_conditions');
  String get privacyPolicy => translate('privacy_policy');
  String get contactUs => translate('contact_us');
  String get helpCenter => translate('help_center');
  String get faq => translate('faq');
  String get support => translate('support');
  String get feedback => translate('feedback');
  String get rateApp => translate('rate_app');
  String get version => translate('version');
  String get update => translate('update');
  String get updateAvailable => translate('update_available');
  String get noUpdates => translate('no_updates');
  String get checkForUpdates => translate('check_for_updates');
  String get downloading => translate('downloading');
  String get installing => translate('installing');
  String get installed => translate('installed');
  String get uninstall => translate('uninstall');
  String get permissions => translate('permissions');
  String get allow => translate('allow');
  String get deny => translate('deny');
  String get camera => translate('camera');
  String get gallery => translate('gallery');
  String get location => translate('location');
  String get storage => translate('storage');
  String get microphone => translate('microphone');
  String get contacts => translate('contacts');
  String get calendar => translate('calendar');
  String get sms => translate('sms');
  String get call => translate('call');
  String get bluetooth => translate('bluetooth');
  String get wifi => translate('wifi');
  String get mobileData => translate('mobile_data');
  String get airplane => translate('airplane');
  String get doNotDisturb => translate('do_not_disturb');
  String get silent => translate('silent');
  String get vibrate => translate('vibrate');
  String get sound => translate('sound');
  String get brightness => translate('brightness');
  String get volume => translate('volume');
  String get battery => translate('battery');
  String get charging => translate('charging');
  String get lowBattery => translate('low_battery');
  String get fullBattery => translate('full_battery');
  String get powerSaving => translate('power_saving');
  String get darkMode => translate('dark_mode');
  String get lightMode => translate('light_mode');
  String get theme => translate('theme');
  String get fontSize => translate('font_size');
  String get fontFamily => translate('font_family');
  String get textDirection => translate('text_direction');
  String get ltr => translate('ltr');
  String get rtl => translate('rtl');
  String get auto => translate('auto');
  String get manual => translate('manual');
  String get automatic => translate('automatic');
  String get custom => translate('custom');
  String get default_ => translate('default');
  String get reset => translate('reset');
  String get restore => translate('restore');
  String get backup => translate('backup');
  String get export => translate('export');
  String get import => translate('import');
  String get sync => translate('sync');
  String get syncing => translate('syncing');
  String get synced => translate('synced');
  String get notSynced => translate('not_synced');
  String get syncFailed => translate('sync_failed');
  String get lastSync => translate('last_sync');
  String get syncNow => translate('sync_now');
  String get autoSync => translate('auto_sync');
  String get manualSync => translate('manual_sync');
  String get syncSettings => translate('sync_settings');
  String get syncFrequency => translate('sync_frequency');
  String get syncOnWifiOnly => translate('sync_on_wifi_only');
  String get syncInBackground => translate('sync_in_background');
  String get syncCompleted => translate('sync_completed');
  String get syncError => translate('sync_error');
  String get noInternet => translate('no_internet');
  String get checkConnection => translate('check_connection');
  String get reconnecting => translate('reconnecting');
  String get connected => translate('connected');
  String get disconnected => translate('disconnected');
  String get connectionLost => translate('connection_lost');
  String get connectionRestored => translate('connection_restored');
  String get slowConnection => translate('slow_connection');
  String get noData => translate('no_data');
  String get noResults => translate('no_results');
  String get noItems => translate('no_items');
  String get empty => translate('empty');
  String get notFound => translate('not_found');
  String get pageNotFound => translate('page_not_found');
  String get somethingWentWrong => translate('something_went_wrong');
  String get tryAgain => translate('try_again');
  String get reload => translate('reload');
  String get goBack => translate('go_back');
  String get goHome => translate('go_home');
  String get continue_ => translate('continue');
  String get proceed => translate('proceed');
  String get finish => translate('finish');
  String get complete => translate('complete');
  String get incomplete => translate('incomplete');
  String get required => translate('required');
  String get optional => translate('optional');
  String get valid => translate('valid');
  String get invalid => translate('invalid');
  String get validating => translate('validating');
  String get verified => translate('verified');
  String get unverified => translate('unverified');
  String get verify => translate('verify');
  String get verification => translate('verification');
  String get code => translate('code');
  String get enterCode => translate('enter_code');
  String get resendCode => translate('resend_code');
  String get codeSent => translate('code_sent');
  String get codeExpired => translate('code_expired');
  String get invalidCode => translate('invalid_code');
  String get correctCode => translate('correct_code');
  String get incorrectCode => translate('incorrect_code');
  String get tooManyAttempts => translate('too_many_attempts');
  String get tryAgainLater => translate('try_again_later');
  String get accountLocked => translate('account_locked');
  String get accountSuspended => translate('account_suspended');
  String get accountDeleted => translate('account_deleted');
  String get accountNotFound => translate('account_not_found');
  String get accountExists => translate('account_exists');
  String get accountCreated => translate('account_created');
  String get accountUpdated => translate('account_updated');
  String get accountVerified => translate('account_verified');
  String get accountUnverified => translate('account_unverified');
  String get accountActive => translate('account_active');
  String get accountInactive => translate('account_inactive');
  String get accountPending => translate('account_pending');
  String get accountApproved => translate('account_approved');
  String get accountRejected => translate('account_rejected');
  String get accountBanned => translate('account_banned');
  String get accountUnbanned => translate('account_unbanned');
  String get accountReactivated => translate('account_reactivated');
  String get accountDeactivated => translate('account_deactivated');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ar', 'en', 'ku'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
