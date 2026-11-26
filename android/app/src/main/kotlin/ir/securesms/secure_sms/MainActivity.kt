package ir.securesms.secure_sms

import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.ContactsContract.CommonDataKinds.Phone
import android.telephony.SmsManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Hands shared / selected text to Dart, reads/sends ciphertext SMS, keeps plaintext out of screenshots. */
class MainActivity : FlutterFragmentActivity() {
    private var channel: MethodChannel? = null
    private var sms: MethodChannel? = null
    private var pending: String? = null
    private var permResult: MethodChannel.Result? = null
    private var pickResult: MethodChannel.Result? = null
    private val smsUri = Uri.parse("content://sms")
    private val perms = arrayOf(Manifest.permission.READ_SMS, Manifest.permission.SEND_SMS, Manifest.permission.RECEIVE_SMS)
    // Asked with the SMS permissions but optional: denying it only loses the closed-app alerts.
    private val ask = if (Build.VERSION.SDK_INT >= 33) perms + Manifest.permission.POST_NOTIFICATIONS else perms
    private var observing = false
    private val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
        override fun onChange(selfChange: Boolean) { sms?.invokeMethod("changed", null) }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        pending = textOf(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        channel = MethodChannel(messenger, "secure_sms/inbound").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "initial") { result.success(pending); pending = null } else result.notImplemented()
            }
        }
        sms = MethodChannel(messenger, "secure_sms/sms").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "granted" -> result.success(granted())
                    "request" -> if (granted()) result.success(true) else {
                        permResult = result
                        requestPermissions(ask, 7)
                    }
                    "senderOf" -> result.success(if (granted()) senderOf(call.argument<String>("text")!!) else null)
                    "list" -> if (!granted()) result.success(emptyList<Any>()) else result.success(list(call.argument<String>("tag") ?: "#SM1:"))
                    // System picker: returns one chosen number, no READ_CONTACTS needed.
                    "pickContact" -> try {
                        pickResult = result
                        startActivityForResult(Intent(Intent.ACTION_PICK, Phone.CONTENT_URI), 8)
                    } catch (e: Exception) { pickResult = null; result.success(null) }
                    "send" -> try {
                        val m = if (Build.VERSION.SDK_INT >= 31) getSystemService(SmsManager::class.java) else @Suppress("DEPRECATION") SmsManager.getDefault()
                        m.sendMultipartTextMessage(call.argument<String>("to"), null, m.divideMessage(call.argument<String>("body")), null, null)
                        result.success(true)
                    } catch (e: Exception) { result.error("send", e.message, null) }
                    "share" -> try {
                        val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, call.argument<String>("text"))
                        startActivity(Intent.createChooser(send, null))
                        result.success(true)
                    } catch (e: Exception) { result.success(false) }
                    else -> result.notImplemented()
                }
            }
        }
        observe()
    }

    private fun granted() = perms.all { checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED }

    private fun observe() {
        if (observing || !granted()) return
        contentResolver.registerContentObserver(smsUri, true, observer)
        observing = true
    }

    /** Only our own ciphertexts; the rest of the inbox is never read into Dart. */
    private fun list(tag: String): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        contentResolver.query(smsUri, arrayOf("address", "body", "date", "type"), "body LIKE ?", arrayOf("%$tag%"), "date DESC LIMIT 500")?.use { c ->
            while (c.moveToNext()) out.add(mapOf("address" to c.getString(0), "body" to c.getString(1), "date" to c.getLong(2), "type" to c.getInt(3)))
        }
        return out
    }

    /** Who sent us an SMS containing [text] (e.g. a key invite), newest first. */
    private fun senderOf(text: String): String? =
        contentResolver.query(Uri.parse("content://sms/inbox"), arrayOf("address"), "body LIKE ?", arrayOf("%$text%"), "date DESC LIMIT 1")
            ?.use { c -> if (c.moveToFirst()) c.getString(0) else null }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != 7) return
        observe()
        permResult?.success(granted())
        permResult = null
    }

    @Deprecated("FlutterFragmentActivity still routes results here")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 8) return
        val uri = if (resultCode == RESULT_OK) data?.data else null
        val row = uri?.let { u ->
            contentResolver.query(u, arrayOf(Phone.DISPLAY_NAME, Phone.NUMBER), null, null, null)
                ?.use { c -> if (c.moveToFirst()) mapOf("name" to c.getString(0), "phone" to c.getString(1)) else null }
        }
        pickResult?.success(row)
        pickResult = null
    }

    override fun onResume() {
        super.onResume()
        visible = true
        getSystemService(NotificationManager::class.java).cancelAll() // the app is open now
    }

    override fun onPause() {
        visible = false
        super.onPause()
    }

    companion object { @Volatile var visible = false }

    override fun onDestroy() {
        if (observing) contentResolver.unregisterContentObserver(observer)
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        textOf(intent)?.let { channel?.invokeMethod("text", it) }
    }

    private fun textOf(i: Intent?): String? = when (i?.action) {
        Intent.ACTION_SEND -> i.getStringExtra(Intent.EXTRA_TEXT)
        Intent.ACTION_PROCESS_TEXT -> i.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
        else -> null
    }
}
