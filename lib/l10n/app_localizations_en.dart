// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Secure SMS';

  @override
  String get tagline => 'End-to-end encrypted · no server';

  @override
  String get myKey => 'Your key';

  @override
  String get myKeyHint =>
      'Send this key to a friend so they can send you encrypted messages.';

  @override
  String get shareKey => 'Send key';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get openMessage => 'Open message';

  @override
  String get noContacts => 'No contacts yet';

  @override
  String get noContactsHint =>
      'Send your key to a friend, or copy the message with their key and tap “Open message”.';

  @override
  String get contacts => 'Contacts';

  @override
  String get invite => 'Invite contact';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone (optional)';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get reply => 'Reply';

  @override
  String get waitingKey => 'Waiting for key';

  @override
  String get verified => 'Verified';

  @override
  String get unverified => 'Not verified';

  @override
  String get composeHint => 'Private message…';

  @override
  String get sendSms => 'Send by SMS';

  @override
  String get copyEncrypted => 'Copy encrypted text';

  @override
  String smsCount(String chars, String parts) {
    return '$chars chars · $parts SMS';
  }

  @override
  String get safetyNumber => 'Safety number';

  @override
  String safetyHint(String name) {
    return 'Compare this code with $name by phone or in person. It must match on both phones.';
  }

  @override
  String get markVerified => 'Codes match';

  @override
  String get unmarkVerified => 'Remove verification';

  @override
  String get nothingToOpen =>
      'No encrypted text or key found. Copy the SMS first.';

  @override
  String get notRecognized =>
      'This message doesn\'t open with any of your keys.';

  @override
  String fromContact(String name) {
    return 'From $name';
  }

  @override
  String toContact(String name) {
    return 'Your message to $name';
  }

  @override
  String get newKeyTitle => 'New key received';

  @override
  String get newKeyBody => 'Whose key is this?';

  @override
  String get newContact => 'New contact';

  @override
  String get sendMyKey => 'Send my key';

  @override
  String sendKeyBackPrompt(String name) {
    return '$name added. Send them your key too.';
  }

  @override
  String keyKnown(String name) {
    return 'This is $name\'s key; it\'s already saved.';
  }

  @override
  String get ownKey => 'This is your own key.';

  @override
  String keyChangedTitle(String name) {
    return '$name\'s key changed!';
  }

  @override
  String keyChangedBody(String name) {
    return '$name may have a new phone or reinstalled the app — or someone may be impersonating them. Call them before accepting.';
  }

  @override
  String get acceptNewKey => 'Accept new key';

  @override
  String deleteConfirm(String name) {
    return 'Delete $name? Their messages won\'t open anymore.';
  }

  @override
  String waitingBody(String name) {
    return 'You can\'t encrypt for $name until their key arrives. Send the invite; when they reply, copy it and tap “Open message”.';
  }

  @override
  String get sendInvite => 'Send invite';

  @override
  String get smsFailed => 'Couldn\'t open the SMS app; text copied.';

  @override
  String unverifiedWarn(String name) {
    return 'You haven\'t compared the safety number with $name yet.';
  }

  @override
  String get compare => 'Compare';

  @override
  String get allowSmsTitle => 'Show the conversation';

  @override
  String get allowSmsBody =>
      'Allow reading and sending SMS to decrypt this contact\'s messages here and send directly. Plaintext is never stored.';

  @override
  String get allowSms => 'Allow';

  @override
  String get smsDenied => 'Permission denied; enable it in the app settings.';

  @override
  String get noMessages => 'No encrypted messages with this contact yet.';

  @override
  String get sharedPhrase => 'Shared phrase';

  @override
  String get sharedPhraseOn => 'Shared phrase is on';

  @override
  String sharedPhraseBody(String name) {
    return 'A phrase you agreed on with $name in person. Both of you must enter exactly the same one, or messages won\'t open. Even if someone swaps the key in transit, they can\'t read messages without it. Messages sent with an earlier phrase stop showing.';
  }

  @override
  String get pickContact => 'Pick from contacts';

  @override
  String get inviteHint =>
      'Don\'t know what this code is? Install the Secure SMS app from Bazaar.';

  @override
  String get inviteAccepted => 'I accepted your invite; this is my key.';

  @override
  String get inviteTitle => 'Secure SMS invite';

  @override
  String inviteFrom(String phone) {
    return '$phone sent you their key. Accept? Your key is sent back automatically.';
  }

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String connected(String name) {
    return 'Connected to $name';
  }

  @override
  String get inviteSent => 'Your key was sent';

  @override
  String get ok => 'OK';

  @override
  String get backup => 'Encrypted backup';

  @override
  String get backupBody =>
      'Your key and contacts are locked with a passphrase. Keep the resulting text somewhere safe. On a new phone, copy it and tap “Restore backup”, so your contacts see no key-change warning. Don\'t forget the passphrase: without it nobody can open the backup.';

  @override
  String get passphrase => 'Passphrase';

  @override
  String get passphraseAgain => 'Repeat passphrase';

  @override
  String get passTooShort => 'At least 10 characters';

  @override
  String get passMismatch => 'The passphrases differ';

  @override
  String get working => 'One moment…';

  @override
  String get restoreBackup => 'Restore backup';

  @override
  String get restoreHint => 'Copy the backup text, then tap this.';

  @override
  String get restoreBody => 'Enter this backup\'s passphrase.';

  @override
  String get restoreConfirm =>
      'The key and contacts on this phone are erased and replaced by the backup. Continue?';

  @override
  String restoreDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restored: $count contacts',
      one: 'Restored: 1 contact',
    );
    return '$_temp0';
  }

  @override
  String get backupWrong =>
      'Wrong passphrase, or the backup text is incomplete.';

  @override
  String get appLock => 'App lock';

  @override
  String get appLockBody =>
      'Asks for your fingerprint or screen lock before messages are shown.';

  @override
  String get appLockUnavailable =>
      'Set a screen lock in the phone\'s settings first.';

  @override
  String get unlock => 'Unlock';

  @override
  String get lockedTitle => 'Secure SMS is locked';

  @override
  String get introTitle1 => 'Send your key';

  @override
  String get introBody1 =>
      '“Invite” sends your public key to a friend in a normal SMS. Your private key never leaves the phone.';

  @override
  String get introTitle2 => 'Compare the safety number';

  @override
  String get introBody2 =>
      'Compare the 20-digit number once, in person or by phone, to be sure nobody swapped the key on the way.';

  @override
  String get introTitle3 => 'Chat securely';

  @override
  String get introBody3 =>
      'Messages are encrypted on the phone and travel as normal SMS. The carrier sees only scrambled text. No server, no account.';

  @override
  String get next => 'Next';

  @override
  String get start => 'Start';

  @override
  String get skip => 'Skip';
}
