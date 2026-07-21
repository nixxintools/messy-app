package dev.messy.messy

import android.os.Handler
import android.os.Looper
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
    }

    private fun emit(event: Map<String, Any?>) {
        main.post { sink?.success(event) }
    }
}
