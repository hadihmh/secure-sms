package ir.securesms.secure_sms

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony

/**
 * While the app is closed: an incoming key or ciphertext raises "secure message / key from <number>".
 * Never the text (we can't decrypt here, and the keystore stays in the app).
 */
class SmsAlert : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION || MainActivity.visible) return
        val parts = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
        val from = parts.firstOrNull()?.originatingAddress ?: ""
        val body = parts.joinToString("") { it.messageBody ?: "" }
        val title = ctx.getString(
            when {
                "#SK1:" in body -> R.string.alert_key
                "#SM1:" in body -> R.string.alert_message
                else -> return
            }
        )
        show(ctx, from, title)
    }

    private fun show(ctx: Context, from: String, title: String) {
        val nm = ctx.getSystemService(NotificationManager::class.java)
        val builder = if (Build.VERSION.SDK_INT >= 26) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL, ctx.getString(R.string.alert_channel), NotificationManager.IMPORTANCE_HIGH)
            )
            Notification.Builder(ctx, CHANNEL)
        } else @Suppress("DEPRECATION") Notification.Builder(ctx).setPriority(Notification.PRIORITY_HIGH)
        val open = PendingIntent.getActivity(
            ctx, 0,
            Intent(ctx, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        // The lock screen shows only the title, not who wrote.
        val public = Notification.Builder(ctx).setSmallIcon(R.drawable.ic_stat_lock).setContentTitle(title).build()
        val n = builder
            .setSmallIcon(R.drawable.ic_stat_lock)
            .setContentTitle(title)
            .setContentText(from)
            .setContentIntent(open)
            .setAutoCancel(true)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setPublicVersion(public)
            .build()
        nm.notify(from.hashCode(), n) // one per sender, replaced by the next
    }

    companion object { const val CHANNEL = "secure_sms_alerts" }
}
