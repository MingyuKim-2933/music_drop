package kr.soundmate.soundmate

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var tracker: MediaSessionTracker? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "soundmate/media")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasNotificationAccess" -> result.success(hasNotificationAccess())
                    "openNotificationAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "soundmate/media_events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    if (hasNotificationAccess()) {
                        tracker = MediaSessionTracker(this@MainActivity, events)
                        tracker?.start()
                    }
                }

                override fun onCancel(arguments: Any?) {
                    tracker?.stop()
                    tracker = null
                }
            })
    }

    private fun hasNotificationAccess(): Boolean {
        val component = ComponentName(this, MediaNotificationListener::class.java)
        val enabled = Settings.Secure.getString(
            contentResolver, "enabled_notification_listeners"
        ) ?: return false
        return enabled.split(":").any {
            ComponentName.unflattenFromString(it) == component
        }
    }

    override fun onDestroy() {
        tracker?.stop()
        tracker = null
        super.onDestroy()
    }
}
