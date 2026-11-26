import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../crypto/sms_crypto.dart';
import 'vault.dart';

class SmsRow {
  const SmsRow(this.address, this.body, this.date, [this.incoming = false]);
  final String address, body;
  final DateTime date;
  final bool incoming; // inbox row
}

class Message {
  const Message(this.text, this.outgoing, this.date, this.address);
  final String text, address;
  final bool outgoing;
  final DateTime date;
}

/// The phone's SMS store (Android, READ_SMS + SEND_SMS). Elsewhere every call says "unavailable".
/// Notifies when the store changes so open threads refresh.
class SmsBox extends ChangeNotifier {
  SmsBox() {
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'changed') notifyListeners();
    });
  }
  static const _ch = MethodChannel('secure_sms/sms');

  Future<T> _call<T>(String m, T fallback, [Object? args]) async {
    try {
      return await _ch.invokeMethod<T>(m, args) ?? fallback;
    } on MissingPluginException {
      return fallback;
    } on PlatformException {
      return fallback;
    }
  }

  Future<bool> granted() => _call('granted', false);
  Future<bool> request() async {
    final ok = await _call('request', false);
    if (ok) notifyListeners(); // open screens and the invite check re-read
    return ok;
  }

  Future<(String, String)?> pickContact() async {
    final m = await _call<Map<Object?, Object?>?>('pickContact', null);
    return m == null ? null : ('${m['name'] ?? ''}', '${m['phone'] ?? ''}');
  }

  Future<String?> senderOf(String text) =>
      _call<String?>('senderOf', null, {'text': text});
  Future<bool> send(String to, String body) =>
      _call('send', false, {'to': to, 'body': body});

  /// System share sheet (no SMS permission needed). False where unavailable.
  Future<bool> share(String text) => _call('share', false, {'text': text});

  /// Rows whose body contains [tag], newest first.
  Future<List<SmsRow>> list({String tag = msgTag}) async => [
    for (final r in await _call<List<Object?>>('list', const [], {'tag': tag}))
      if (r case {
        'address': final String? a,
        'body': final String b,
        'date': final int d,
        'type': final int t,
      })
        SmsRow(a ?? '', b, DateTime.fromMillisecondsSinceEpoch(d), t == 1),
  ];
}

final smsBox = SmsBox();

/// The conversation with [c], oldest first: only rows that decrypt under c's key.
/// Plaintext lives in memory only (D5).
Future<List<Message>> thread(Identity me, Contact c, List<SmsRow> rows) async {
  final out = <Message>[];
  for (final r in rows) {
    if (parse(r.body) case Ciphertext(:final payload)) {
      final d = await me.decrypt(payload, [c.key!], secretOf: (_) => c.secret);
      if (d != null) out.add(Message(d.text, d.outgoing, r.date, r.address));
    }
  }
  return out..sort((a, b) => a.date.compareTo(b.date));
}
