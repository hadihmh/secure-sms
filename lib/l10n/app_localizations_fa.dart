// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'پیامک امن';

  @override
  String get tagline => 'رمزگذاری سرتاسری · بدون سرور';

  @override
  String get myKey => 'کلید شما';

  @override
  String get myKeyHint =>
      'این کلید را برای دوستتان بفرستید تا بتواند برایتان پیام رمزشده بفرستد.';

  @override
  String get shareKey => 'ارسال کلید';

  @override
  String get copy => 'کپی';

  @override
  String get copied => 'کپی شد';

  @override
  String get openMessage => 'باز کردن پیام';

  @override
  String get noContacts => 'هنوز مخاطبی ندارید';

  @override
  String get noContactsHint =>
      'کلیدتان را برای یک دوست بفرستید، یا پیامی را که کلید او در آن است کپی کنید و «باز کردن پیام» را بزنید.';

  @override
  String get contacts => 'مخاطبان';

  @override
  String get invite => 'دعوت مخاطب';

  @override
  String get name => 'نام';

  @override
  String get phone => 'شماره تلفن (اختیاری)';

  @override
  String get save => 'ذخیره';

  @override
  String get cancel => 'انصراف';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'ویرایش';

  @override
  String get close => 'بستن';

  @override
  String get reply => 'پاسخ';

  @override
  String get waitingKey => 'منتظر کلید';

  @override
  String get verified => 'تأییدشده';

  @override
  String get unverified => 'تأییدنشده';

  @override
  String get composeHint => 'پیام محرمانه…';

  @override
  String get sendSms => 'ارسال با پیامک';

  @override
  String get copyEncrypted => 'کپی متن رمزشده';

  @override
  String smsCount(String chars, String parts) {
    return '$chars نویسه · $parts پیامک';
  }

  @override
  String get safetyNumber => 'کد امنیتی';

  @override
  String safetyHint(String name) {
    return 'این کد را تلفنی یا حضوری با $name مقایسه کنید. روی هر دو گوشی باید یکی باشد.';
  }

  @override
  String get markVerified => 'کدها یکی است';

  @override
  String get unmarkVerified => 'لغو تأیید';

  @override
  String get nothingToOpen =>
      'متن رمزشده یا کلیدی پیدا نشد. اول پیامک را کپی کنید.';

  @override
  String get notRecognized => 'این پیام با هیچ‌یک از کلیدهای شما باز نشد.';

  @override
  String fromContact(String name) {
    return 'از $name';
  }

  @override
  String toContact(String name) {
    return 'پیام شما به $name';
  }

  @override
  String get newKeyTitle => 'کلید جدید دریافت شد';

  @override
  String get newKeyBody => 'این کلید مال کیست؟';

  @override
  String get newContact => 'مخاطب جدید';

  @override
  String get sendMyKey => 'ارسال کلید من';

  @override
  String sendKeyBackPrompt(String name) {
    return '$name اضافه شد. کلیدتان را هم برایش بفرستید.';
  }

  @override
  String keyKnown(String name) {
    return 'این کلیدِ $name است و از قبل ذخیره شده.';
  }

  @override
  String get ownKey => 'این کلید خودتان است.';

  @override
  String keyChangedTitle(String name) {
    return 'کلید $name عوض شده!';
  }

  @override
  String keyChangedBody(String name) {
    return 'شاید $name گوشی یا برنامه را عوض کرده باشد، یا کسی بخواهد خودش را جای او جا بزند. قبل از پذیرش، حتماً تلفنی با او حرف بزنید.';
  }

  @override
  String get acceptNewKey => 'پذیرش کلید جدید';

  @override
  String deleteConfirm(String name) {
    return '$name حذف شود؟ پیام‌های او دیگر باز نمی‌شود.';
  }

  @override
  String waitingBody(String name) {
    return 'تا کلید $name نرسد نمی‌توانید برایش پیام رمزشده بفرستید. دعوت‌نامه را بفرستید و وقتی جواب داد، پیامش را کپی کنید و «باز کردن پیام» را بزنید.';
  }

  @override
  String get sendInvite => 'ارسال دعوت‌نامه';

  @override
  String get smsFailed => 'برنامهٔ پیامک باز نشد؛ متن کپی شد.';

  @override
  String unverifiedWarn(String name) {
    return 'هنوز کد امنیتی را با $name مقایسه نکرده‌اید.';
  }

  @override
  String get compare => 'مقایسه';

  @override
  String get allowSmsTitle => 'نمایش گفتگو';

  @override
  String get allowSmsBody =>
      'با اجازهٔ پیامک، پیام‌های این مخاطب همین‌جا رمزگشایی و مستقیم ارسال می‌شوند و وقتی برنامه بسته است، رسیدن پیام امن خبر داده می‌شود (بدون نشان دادن متن). متن باز هیچ‌جا ذخیره نمی‌شود.';

  @override
  String get allowSms => 'اجازه';

  @override
  String get smsDenied => 'اجازه داده نشد؛ از تنظیمات برنامه فعالش کنید.';

  @override
  String get noMessages => 'هنوز پیام رمزشده‌ای با این مخاطب نیست.';

  @override
  String get sharedPhrase => 'عبارت مشترک';

  @override
  String get sharedPhraseOn => 'عبارت مشترک فعال است';

  @override
  String sharedPhraseBody(String name) {
    return 'یک عبارت که حضوری با $name قرار گذاشته‌اید. هر دو نفر باید دقیقاً همین را وارد کنند، وگرنه پیام‌ها باز نمی‌شوند. حتی اگر کسی وسط راه کلید را عوض کند، بدون این عبارت پیام‌ها را نمی‌خواند. پیام‌های قبلی با عبارت قبلی دیگر نمایش داده نمی‌شوند.';
  }

  @override
  String get pickContact => 'انتخاب از مخاطبین گوشی';

  @override
  String get inviteHint =>
      'اگر نمی‌دانی این کد چیست، برنامهٔ «پیامک امن» را از بازار نصب کن.';

  @override
  String get inviteAccepted => 'دعوتت را قبول کردم؛ این کلید من است.';

  @override
  String get inviteTitle => 'دعوت پیامک امن';

  @override
  String inviteFrom(String phone) {
    return '$phone کلیدش را برایت فرستاده. قبول می‌کنی؟ کلید تو هم خودکار برایش فرستاده می‌شود.';
  }

  @override
  String get accept => 'قبول';

  @override
  String get decline => 'رد';

  @override
  String connected(String name) {
    return 'به $name وصل شدی';
  }

  @override
  String get inviteSent => 'کلیدت فرستاده شد';

  @override
  String get ok => 'تأیید';

  @override
  String get backup => 'پشتیبان رمزدار';

  @override
  String get backupBody =>
      'کلید و مخاطبینت با یک رمز عبور قفل می‌شوند. متن حاصل را جای امنی نگه دار. در گوشی جدید آن را کپی کن و «بازیابی پشتیبان» را بزن تا مخاطبین هشدار تغییر کلید نبینند. رمز را فراموش نکن؛ بدون آن هیچ‌کس نمی‌تواند بازش کند.';

  @override
  String get passphrase => 'رمز عبور';

  @override
  String get passphraseAgain => 'تکرار رمز عبور';

  @override
  String get passTooShort => 'دست‌کم ۱۰ نویسه';

  @override
  String get passMismatch => 'دو رمز یکی نیستند';

  @override
  String get working => 'کمی صبر کن…';

  @override
  String get restoreBackup => 'بازیابی پشتیبان';

  @override
  String get restoreHint => 'متن پشتیبان را کپی کن، بعد این را بزن.';

  @override
  String get restoreBody => 'رمز عبور همین پشتیبان را وارد کن.';

  @override
  String get restoreConfirm =>
      'کلید و مخاطبین فعلی این گوشی پاک می‌شوند و پشتیبان جایشان را می‌گیرد. ادامه می‌دهی؟';

  @override
  String restoreDone(int count) {
    return 'بازیابی شد: $count مخاطب';
  }

  @override
  String get backupWrong => 'رمز اشتباه است یا متن پشتیبان ناقص است.';

  @override
  String get appLock => 'قفل برنامه';

  @override
  String get appLockBody =>
      'پیش از نمایش پیام‌ها اثر انگشت یا قفل صفحهٔ گوشی خواسته می‌شود.';

  @override
  String get appLockUnavailable =>
      'برای قفل برنامه، اول در تنظیمات گوشی قفل صفحه بگذار.';

  @override
  String get unlock => 'باز کردن قفل';

  @override
  String get lockedTitle => 'پیامک امن قفل است';

  @override
  String get introTitle1 => 'کلیدت را بفرست';

  @override
  String get introBody1 =>
      'با «دعوت»، کلید عمومی‌ات با یک پیامک معمولی برای دوستت می‌رود. کلید خصوصی هیچ‌وقت از گوشی بیرون نمی‌رود.';

  @override
  String get introTitle2 => 'کد امنیتی را مقایسه کن';

  @override
  String get introBody2 =>
      'یک بار کد ۲۰ رقمی را حضوری یا تلفنی با هم مقایسه کنید تا مطمئن شوید کسی وسط راه کلید را عوض نکرده.';

  @override
  String get introTitle3 => 'امن گپ بزن';

  @override
  String get introBody3 =>
      'پیام‌ها روی گوشی رمز می‌شوند و به شکل پیامک عادی می‌روند. اپراتور فقط یک متن درهم می‌بیند. بی‌سرور، بی‌حساب کاربری.';

  @override
  String get next => 'بعدی';

  @override
  String get start => 'شروع';

  @override
  String get skip => 'رد شدن';
}
