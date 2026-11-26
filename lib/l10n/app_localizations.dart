import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

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
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fa, this message translates to:
  /// **'پیامک امن'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In fa, this message translates to:
  /// **'رمزگذاری سرتاسری · بدون سرور'**
  String get tagline;

  /// No description provided for @myKey.
  ///
  /// In fa, this message translates to:
  /// **'کلید شما'**
  String get myKey;

  /// No description provided for @myKeyHint.
  ///
  /// In fa, this message translates to:
  /// **'این کلید را برای دوستتان بفرستید تا بتواند برایتان پیام رمزشده بفرستد.'**
  String get myKeyHint;

  /// No description provided for @shareKey.
  ///
  /// In fa, this message translates to:
  /// **'ارسال کلید'**
  String get shareKey;

  /// No description provided for @copy.
  ///
  /// In fa, this message translates to:
  /// **'کپی'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In fa, this message translates to:
  /// **'کپی شد'**
  String get copied;

  /// No description provided for @openMessage.
  ///
  /// In fa, this message translates to:
  /// **'باز کردن پیام'**
  String get openMessage;

  /// No description provided for @noContacts.
  ///
  /// In fa, this message translates to:
  /// **'هنوز مخاطبی ندارید'**
  String get noContacts;

  /// No description provided for @noContactsHint.
  ///
  /// In fa, this message translates to:
  /// **'کلیدتان را برای یک دوست بفرستید، یا پیامی را که کلید او در آن است کپی کنید و «باز کردن پیام» را بزنید.'**
  String get noContactsHint;

  /// No description provided for @contacts.
  ///
  /// In fa, this message translates to:
  /// **'مخاطبان'**
  String get contacts;

  /// No description provided for @invite.
  ///
  /// In fa, this message translates to:
  /// **'دعوت مخاطب'**
  String get invite;

  /// No description provided for @name.
  ///
  /// In fa, this message translates to:
  /// **'نام'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In fa, this message translates to:
  /// **'شماره تلفن (اختیاری)'**
  String get phone;

  /// No description provided for @save.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In fa, this message translates to:
  /// **'انصراف'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In fa, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In fa, this message translates to:
  /// **'بستن'**
  String get close;

  /// No description provided for @reply.
  ///
  /// In fa, this message translates to:
  /// **'پاسخ'**
  String get reply;

  /// No description provided for @waitingKey.
  ///
  /// In fa, this message translates to:
  /// **'منتظر کلید'**
  String get waitingKey;

  /// No description provided for @verified.
  ///
  /// In fa, this message translates to:
  /// **'تأییدشده'**
  String get verified;

  /// No description provided for @unverified.
  ///
  /// In fa, this message translates to:
  /// **'تأییدنشده'**
  String get unverified;

  /// No description provided for @composeHint.
  ///
  /// In fa, this message translates to:
  /// **'پیام محرمانه…'**
  String get composeHint;

  /// No description provided for @sendSms.
  ///
  /// In fa, this message translates to:
  /// **'ارسال با پیامک'**
  String get sendSms;

  /// No description provided for @copyEncrypted.
  ///
  /// In fa, this message translates to:
  /// **'کپی متن رمزشده'**
  String get copyEncrypted;

  /// No description provided for @smsCount.
  ///
  /// In fa, this message translates to:
  /// **'{chars} نویسه · {parts} پیامک'**
  String smsCount(String chars, String parts);

  /// No description provided for @safetyNumber.
  ///
  /// In fa, this message translates to:
  /// **'کد امنیتی'**
  String get safetyNumber;

  /// No description provided for @safetyHint.
  ///
  /// In fa, this message translates to:
  /// **'این کد را تلفنی یا حضوری با {name} مقایسه کنید. روی هر دو گوشی باید یکی باشد.'**
  String safetyHint(String name);

  /// No description provided for @markVerified.
  ///
  /// In fa, this message translates to:
  /// **'کدها یکی است'**
  String get markVerified;

  /// No description provided for @unmarkVerified.
  ///
  /// In fa, this message translates to:
  /// **'لغو تأیید'**
  String get unmarkVerified;

  /// No description provided for @nothingToOpen.
  ///
  /// In fa, this message translates to:
  /// **'متن رمزشده یا کلیدی پیدا نشد. اول پیامک را کپی کنید.'**
  String get nothingToOpen;

  /// No description provided for @notRecognized.
  ///
  /// In fa, this message translates to:
  /// **'این پیام با هیچ‌یک از کلیدهای شما باز نشد.'**
  String get notRecognized;

  /// No description provided for @fromContact.
  ///
  /// In fa, this message translates to:
  /// **'از {name}'**
  String fromContact(String name);

  /// No description provided for @toContact.
  ///
  /// In fa, this message translates to:
  /// **'پیام شما به {name}'**
  String toContact(String name);

  /// No description provided for @newKeyTitle.
  ///
  /// In fa, this message translates to:
  /// **'کلید جدید دریافت شد'**
  String get newKeyTitle;

  /// No description provided for @newKeyBody.
  ///
  /// In fa, this message translates to:
  /// **'این کلید مال کیست؟'**
  String get newKeyBody;

  /// No description provided for @newContact.
  ///
  /// In fa, this message translates to:
  /// **'مخاطب جدید'**
  String get newContact;

  /// No description provided for @sendMyKey.
  ///
  /// In fa, this message translates to:
  /// **'ارسال کلید من'**
  String get sendMyKey;

  /// No description provided for @sendKeyBackPrompt.
  ///
  /// In fa, this message translates to:
  /// **'{name} اضافه شد. کلیدتان را هم برایش بفرستید.'**
  String sendKeyBackPrompt(String name);

  /// No description provided for @keyKnown.
  ///
  /// In fa, this message translates to:
  /// **'این کلیدِ {name} است و از قبل ذخیره شده.'**
  String keyKnown(String name);

  /// No description provided for @ownKey.
  ///
  /// In fa, this message translates to:
  /// **'این کلید خودتان است.'**
  String get ownKey;

  /// No description provided for @keyChangedTitle.
  ///
  /// In fa, this message translates to:
  /// **'کلید {name} عوض شده!'**
  String keyChangedTitle(String name);

  /// No description provided for @keyChangedBody.
  ///
  /// In fa, this message translates to:
  /// **'شاید {name} گوشی یا برنامه را عوض کرده باشد، یا کسی بخواهد خودش را جای او جا بزند. قبل از پذیرش، حتماً تلفنی با او حرف بزنید.'**
  String keyChangedBody(String name);

  /// No description provided for @acceptNewKey.
  ///
  /// In fa, this message translates to:
  /// **'پذیرش کلید جدید'**
  String get acceptNewKey;

  /// No description provided for @deleteConfirm.
  ///
  /// In fa, this message translates to:
  /// **'{name} حذف شود؟ پیام‌های او دیگر باز نمی‌شود.'**
  String deleteConfirm(String name);

  /// No description provided for @waitingBody.
  ///
  /// In fa, this message translates to:
  /// **'تا کلید {name} نرسد نمی‌توانید برایش پیام رمزشده بفرستید. دعوت‌نامه را بفرستید و وقتی جواب داد، پیامش را کپی کنید و «باز کردن پیام» را بزنید.'**
  String waitingBody(String name);

  /// No description provided for @sendInvite.
  ///
  /// In fa, this message translates to:
  /// **'ارسال دعوت‌نامه'**
  String get sendInvite;

  /// No description provided for @smsFailed.
  ///
  /// In fa, this message translates to:
  /// **'برنامهٔ پیامک باز نشد؛ متن کپی شد.'**
  String get smsFailed;

  /// No description provided for @unverifiedWarn.
  ///
  /// In fa, this message translates to:
  /// **'هنوز کد امنیتی را با {name} مقایسه نکرده‌اید.'**
  String unverifiedWarn(String name);

  /// No description provided for @compare.
  ///
  /// In fa, this message translates to:
  /// **'مقایسه'**
  String get compare;

  /// No description provided for @allowSmsTitle.
  ///
  /// In fa, this message translates to:
  /// **'نمایش گفتگو'**
  String get allowSmsTitle;

  /// No description provided for @allowSmsBody.
  ///
  /// In fa, this message translates to:
  /// **'با اجازهٔ خواندن و ارسال پیامک، پیام‌های این مخاطب همین‌جا رمزگشایی و مستقیم ارسال می‌شوند. متن باز هیچ‌جا ذخیره نمی‌شود.'**
  String get allowSmsBody;

  /// No description provided for @allowSms.
  ///
  /// In fa, this message translates to:
  /// **'اجازه'**
  String get allowSms;

  /// No description provided for @smsDenied.
  ///
  /// In fa, this message translates to:
  /// **'اجازه داده نشد؛ از تنظیمات برنامه فعالش کنید.'**
  String get smsDenied;

  /// No description provided for @noMessages.
  ///
  /// In fa, this message translates to:
  /// **'هنوز پیام رمزشده‌ای با این مخاطب نیست.'**
  String get noMessages;

  /// No description provided for @sharedPhrase.
  ///
  /// In fa, this message translates to:
  /// **'عبارت مشترک'**
  String get sharedPhrase;

  /// No description provided for @sharedPhraseOn.
  ///
  /// In fa, this message translates to:
  /// **'عبارت مشترک فعال است'**
  String get sharedPhraseOn;

  /// No description provided for @sharedPhraseBody.
  ///
  /// In fa, this message translates to:
  /// **'یک عبارت که حضوری با {name} قرار گذاشته‌اید. هر دو نفر باید دقیقاً همین را وارد کنند، وگرنه پیام‌ها باز نمی‌شوند. حتی اگر کسی وسط راه کلید را عوض کند، بدون این عبارت پیام‌ها را نمی‌خواند. پیام‌های قبلی با عبارت قبلی دیگر نمایش داده نمی‌شوند.'**
  String sharedPhraseBody(String name);

  /// No description provided for @pickContact.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب از مخاطبین گوشی'**
  String get pickContact;

  /// No description provided for @inviteHint.
  ///
  /// In fa, this message translates to:
  /// **'اگر نمی‌دانی این کد چیست، برنامهٔ «پیامک امن» را از بازار نصب کن: {url}'**
  String inviteHint(String url);

  /// No description provided for @inviteAccepted.
  ///
  /// In fa, this message translates to:
  /// **'دعوتت را قبول کردم؛ این کلید من است.'**
  String get inviteAccepted;

  /// No description provided for @inviteTitle.
  ///
  /// In fa, this message translates to:
  /// **'دعوت پیامک امن'**
  String get inviteTitle;

  /// No description provided for @inviteFrom.
  ///
  /// In fa, this message translates to:
  /// **'{phone} کلیدش را برایت فرستاده. قبول می‌کنی؟ کلید تو هم خودکار برایش فرستاده می‌شود.'**
  String inviteFrom(String phone);

  /// No description provided for @accept.
  ///
  /// In fa, this message translates to:
  /// **'قبول'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In fa, this message translates to:
  /// **'رد'**
  String get decline;

  /// No description provided for @connected.
  ///
  /// In fa, this message translates to:
  /// **'به {name} وصل شدی'**
  String connected(String name);

  /// No description provided for @inviteSent.
  ///
  /// In fa, this message translates to:
  /// **'کلیدت فرستاده شد'**
  String get inviteSent;

  /// No description provided for @ok.
  ///
  /// In fa, this message translates to:
  /// **'تأیید'**
  String get ok;

  /// No description provided for @backup.
  ///
  /// In fa, this message translates to:
  /// **'پشتیبان رمزدار'**
  String get backup;

  /// No description provided for @backupBody.
  ///
  /// In fa, this message translates to:
  /// **'کلید و مخاطبینت با یک رمز عبور قفل می‌شوند. متن حاصل را جای امنی نگه دار. در گوشی جدید آن را کپی کن و «بازیابی پشتیبان» را بزن تا مخاطبین هشدار تغییر کلید نبینند. رمز را فراموش نکن؛ بدون آن هیچ‌کس نمی‌تواند بازش کند.'**
  String get backupBody;

  /// No description provided for @passphrase.
  ///
  /// In fa, this message translates to:
  /// **'رمز عبور'**
  String get passphrase;

  /// No description provided for @passphraseAgain.
  ///
  /// In fa, this message translates to:
  /// **'تکرار رمز عبور'**
  String get passphraseAgain;

  /// No description provided for @passTooShort.
  ///
  /// In fa, this message translates to:
  /// **'دست‌کم ۱۰ نویسه'**
  String get passTooShort;

  /// No description provided for @passMismatch.
  ///
  /// In fa, this message translates to:
  /// **'دو رمز یکی نیستند'**
  String get passMismatch;

  /// No description provided for @working.
  ///
  /// In fa, this message translates to:
  /// **'کمی صبر کن…'**
  String get working;

  /// No description provided for @restoreBackup.
  ///
  /// In fa, this message translates to:
  /// **'بازیابی پشتیبان'**
  String get restoreBackup;

  /// No description provided for @restoreHint.
  ///
  /// In fa, this message translates to:
  /// **'متن پشتیبان را کپی کن، بعد این را بزن.'**
  String get restoreHint;

  /// No description provided for @restoreBody.
  ///
  /// In fa, this message translates to:
  /// **'رمز عبور همین پشتیبان را وارد کن.'**
  String get restoreBody;

  /// No description provided for @restoreConfirm.
  ///
  /// In fa, this message translates to:
  /// **'کلید و مخاطبین فعلی این گوشی پاک می‌شوند و پشتیبان جایشان را می‌گیرد. ادامه می‌دهی؟'**
  String get restoreConfirm;

  /// No description provided for @restoreDone.
  ///
  /// In fa, this message translates to:
  /// **'بازیابی شد: {count} مخاطب'**
  String restoreDone(int count);

  /// No description provided for @backupWrong.
  ///
  /// In fa, this message translates to:
  /// **'رمز اشتباه است یا متن پشتیبان ناقص است.'**
  String get backupWrong;

  /// No description provided for @appLock.
  ///
  /// In fa, this message translates to:
  /// **'قفل برنامه'**
  String get appLock;

  /// No description provided for @appLockBody.
  ///
  /// In fa, this message translates to:
  /// **'پیش از نمایش پیام‌ها اثر انگشت یا قفل صفحهٔ گوشی خواسته می‌شود.'**
  String get appLockBody;

  /// No description provided for @appLockUnavailable.
  ///
  /// In fa, this message translates to:
  /// **'برای قفل برنامه، اول در تنظیمات گوشی قفل صفحه بگذار.'**
  String get appLockUnavailable;

  /// No description provided for @unlock.
  ///
  /// In fa, this message translates to:
  /// **'باز کردن قفل'**
  String get unlock;

  /// No description provided for @lockedTitle.
  ///
  /// In fa, this message translates to:
  /// **'پیامک امن قفل است'**
  String get lockedTitle;

  /// No description provided for @introTitle1.
  ///
  /// In fa, this message translates to:
  /// **'کلیدت را بفرست'**
  String get introTitle1;

  /// No description provided for @introBody1.
  ///
  /// In fa, this message translates to:
  /// **'با «دعوت»، کلید عمومی‌ات با یک پیامک معمولی برای دوستت می‌رود. کلید خصوصی هیچ‌وقت از گوشی بیرون نمی‌رود.'**
  String get introBody1;

  /// No description provided for @introTitle2.
  ///
  /// In fa, this message translates to:
  /// **'کد امنیتی را مقایسه کن'**
  String get introTitle2;

  /// No description provided for @introBody2.
  ///
  /// In fa, this message translates to:
  /// **'یک بار کد ۲۰ رقمی را حضوری یا تلفنی با هم مقایسه کنید تا مطمئن شوید کسی وسط راه کلید را عوض نکرده.'**
  String get introBody2;

  /// No description provided for @introTitle3.
  ///
  /// In fa, this message translates to:
  /// **'امن گپ بزن'**
  String get introTitle3;

  /// No description provided for @introBody3.
  ///
  /// In fa, this message translates to:
  /// **'پیام‌ها روی گوشی رمز می‌شوند و به شکل پیامک عادی می‌روند. اپراتور فقط یک متن درهم می‌بیند. بی‌سرور، بی‌حساب کاربری.'**
  String get introBody3;

  /// No description provided for @next.
  ///
  /// In fa, this message translates to:
  /// **'بعدی'**
  String get next;

  /// No description provided for @start.
  ///
  /// In fa, this message translates to:
  /// **'شروع'**
  String get start;

  /// No description provided for @skip.
  ///
  /// In fa, this message translates to:
  /// **'رد شدن'**
  String get skip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
