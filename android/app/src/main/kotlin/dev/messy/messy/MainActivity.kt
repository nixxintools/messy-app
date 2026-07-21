package dev.messy.messy

import android.content.Context
import android.content.Intent
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges the native [WifiAwareTransport] to Dart over two channels:
 *  - method channel "messy/wifi_aware": isSupported / start / stop / send
 *  - event channel  "messy/wifi_aware/events": connected / data / closed
 *
 * Everything is best-effort and isolated: if Wi-Fi Aware is unsupported the
 * method calls simply report false and Dart falls back to Wi-Fi/BLE.
 */
class MainActivity : FlutterActivity() {
    private val methodName = "messy/wifi_aware"
    private val eventName = "messy/wifi_aware/events"

    private var transport: WifiAwareTransport? = null
    private var sink: EventChannel.EventSink? = null
    private var directTransport: WifiDirectTransport? = null
    private var directSink: EventChannel.EventSink? = null
    private val main = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        transport = WifiAwareTransport(applicationContext)

        EventChannel(messenger, eventName).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, events: EventChannel.EventSink?) {
                    sink = events
                }
                override fun onCancel(args: Any?) {
                    sink = null
                }
            },
        )

        MethodChannel(messenger, methodName).setMethodCallHandler { call, result ->
            val t = transport
            when (call.method) {
                "isSupported" -> result.success(t?.isSupported() ?: false)
                "start" -> {
                    val nodeId = call.argument<String>("nodeId") ?: ""
                    val ok = t?.start(nodeId, object : WifiAwareTransport.Events {
                        override fun onConnected(connId: Int, peerId: String) = emit(
                            mapOf("type" to "connected", "id" to connId, "peer" to peerId),
                        )
                        override fun onData(connId: Int, data: ByteArray) = emit(
                            mapOf("type" to "data", "id" to connId, "data" to data),
                        )
                        override fun onClosed(connId: Int) = emit(
                            mapOf("type" to "closed", "id" to connId),
                        )
                    }) ?: false
                    result.success(ok)
                }
                "send" -> {
                    val connId = call.argument<Int>("id") ?: -1
                    val data = call.argument<ByteArray>("data") ?: ByteArray(0)
                    result.success(t?.send(connId, data) ?: false)
                }
                "stop" -> {
                    t?.stop()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Wi-Fi Direct transport (same byte-pipe model as Wi-Fi Aware).
        directTransport = WifiDirectTransport(applicationContext)
        EventChannel(messenger, "messy/wifi_direct/events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, events: EventChannel.EventSink?) {
                    directSink = events
                }
                override fun onCancel(args: Any?) {
                    directSink = null
                }
            },
        )
        MethodChannel(messenger, "messy/wifi_direct").setMethodCallHandler { call, result ->
            val d = directTransport
            when (call.method) {
                "isSupported" -> result.success(d?.isSupported() ?: false)
                "start" -> {
                    val ok = d?.start(object : WifiDirectTransport.Events {
                        override fun onConnected(connId: Int, peerId: String) =
                            emitDirect(mapOf("type" to "connected", "id" to connId, "peer" to peerId))
                        override fun onData(connId: Int, data: ByteArray) =
                            emitDirect(mapOf("type" to "data", "id" to connId, "data" to data))
                        override fun onClosed(connId: Int) =
                            emitDirect(mapOf("type" to "closed", "id" to connId))
                    }) ?: false
                    result.success(ok)
                }
                "send" -> {
                    val connId = call.argument<Int>("id") ?: -1
                    val data = call.argument<ByteArray>("data") ?: ByteArray(0)
                    result.success(d?.send(connId, data) ?: false)
                }
                "stop" -> { d?.stop(); result.success(null) }
                else -> result.notImplemented()
            }
        }

        // FLAG_SECURE: block screenshots and hide the app from the recents
        // thumbnail when enabled.
        MethodChannel(messenger, "messy/window").setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecure" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    runOnUiThread {
                        if (enabled) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Radio state gate: report Wi-Fi state and open the system panels so
        // the user can enable Wi-Fi (the app can't toggle it on Android 10+).
        MethodChannel(messenger, "messy/radio").setMethodCallHandler { call, result ->
            when (call.method) {
                "isWifiEnabled" -> {
                    val wifi = applicationContext
                        .getSystemService(Context.WIFI_SERVICE) as WifiManager
                    result.success(wifi.isWifiEnabled)
                }
                "openWifiPanel" -> {
                    try {
                        startActivity(
                            Intent(Settings.Panel.ACTION_WIFI)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                    } catch (e: Exception) {
                        startActivity(
                            Intent(Settings.ACTION_WIFI_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                    }
                    result.success(null)
                }
                "openHotspotSettings" -> {
                    try {
                        startActivity(
                            Intent(Intent.ACTION_MAIN)
                                .setClassName(
                                    "com.android.settings",
                                    "com.android.settings.TetherSettings",
                                )
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                    } catch (e: Exception) {
                        startActivity(
                            Intent(Settings.ACTION_WIRELESS_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun emit(event: Map<String, Any?>) {
        main.post { sink?.success(event) }
    }

    private fun emitDirect(event: Map<String, Any?>) {
        main.post { directSink?.success(event) }
    }
}
