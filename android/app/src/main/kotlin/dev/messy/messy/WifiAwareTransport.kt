package dev.messy.messy

import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.aware.AttachCallback
import android.net.wifi.aware.DiscoverySessionCallback
import android.net.wifi.aware.PeerHandle
import android.net.wifi.aware.PublishConfig
import android.net.wifi.aware.PublishDiscoverySession
import android.net.wifi.aware.SubscribeConfig
import android.net.wifi.aware.SubscribeDiscoverySession
import android.net.wifi.aware.WifiAwareManager
import android.net.wifi.aware.WifiAwareNetworkInfo
import android.net.wifi.aware.WifiAwareNetworkSpecifier
import android.net.wifi.aware.WifiAwareSession
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.io.IOException
import java.net.Inet6Address
import java.net.ServerSocket
import java.net.Socket
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

/**
 * Wi-Fi Aware (NAN) mesh transport — the high-throughput half of the hybrid
 * mesh (BLE is the universal low-power half).
 *
 * Adapted from NodleCode's production reference
 * (github.com/NodleCode/wifi-aware). Every node publishes AND subscribes; on
 * discovery, the peers exchange ids, the lower-nodeId side opens a
 * ServerSocket and requests a Wi-Fi Aware data-path network, the other side
 * connects a socket over the peer's link-local IPv6. The result is a plain
 * TCP socket bound to the NAN network — which is why this must live in native
 * code (Dart can't bind a socket to a specific Android Network).
 *
 * This class is a TRANSPARENT BYTE PIPE: it does none of Messy's framing,
 * handshake, or crypto. Those all run in Dart, unchanged, over the socket —
 * exactly like the Wi-Fi/hotspot transport. Bytes flow Kotlin↔Dart over the
 * platform channels wired in [MainActivity].
 */
class WifiAwareTransport(private val context: Context) {

    interface Events {
        fun onConnected(connId: Int, peerId: String)
        fun onData(connId: Int, data: ByteArray)
        fun onClosed(connId: Int)
    }

    companion object {
        private const val TAG = "MessyWifiAware"
        private const val SERVICE_NAME = "messy-mesh"
        // Transport-layer PSK for the NAN data path. Messy's real end-to-end
        // encryption runs on top of this; it only gates who can form a NAN
        // link, not message confidentiality.
        private const val PSK = "messy-wifi-aware-v1"
    }

    private val main = Handler(Looper.getMainLooper())
    private val awareManager = context.getSystemService(WifiAwareManager::class.java)
    private val cm = context.getSystemService(ConnectivityManager::class.java)
    private val readers = Executors.newCachedThreadPool()
    private val connIds = AtomicInteger(1)

    private var session: WifiAwareSession? = null
    private var publishSession: PublishDiscoverySession? = null
    private var subscribeSession: SubscribeDiscoverySession? = null

    private val handleToPeer = ConcurrentHashMap<PeerHandle, String>()
    private val serverSockets = ConcurrentHashMap<String, ServerSocket>()
    private val peerSockets = ConcurrentHashMap<String, Socket>()
    private val connSockets = ConcurrentHashMap<Int, Socket>()
    private val networkCallbacks = ConcurrentHashMap<String, ConnectivityManager.NetworkCallback>()

    private var myPeerId: String = ""
    private var events: Events? = null
    @Volatile private var active = false

    fun isSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        if (!context.packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_AWARE)) {
            return false
        }
        return awareManager?.isAvailable == true
    }

    fun start(nodeId: String, events: Events): Boolean {
        if (active) return true
        if (!isSupported()) return false
        myPeerId = nodeId
        this.events = events
        active = true
        try {
            awareManager!!.attach(object : AttachCallback() {
                override fun onAttached(s: WifiAwareSession) {
                    session = s
                    startPublish(s)
                    startSubscribe(s)
                }
                override fun onAttachFailed() {
                    Log.e(TAG, "Wi-Fi Aware attach failed")
                    active = false
                }
            }, main)
            return true
        } catch (e: Exception) {
            active = false
            return false
        }
    }

    private fun startPublish(s: WifiAwareSession) {
        s.publish(
            PublishConfig.Builder().setServiceName(SERVICE_NAME).build(),
            object : DiscoverySessionCallback() {
                override fun onPublishStarted(pub: PublishDiscoverySession) {
                    publishSession = pub
                }
                override fun onMessageReceived(peerHandle: PeerHandle, message: ByteArray) {
                    val subscriberId = String(message)
                    if (subscriberId == myPeerId || subscriberId.isEmpty()) return
                    handleToPeer[peerHandle] = subscriberId
                    handleSubscriberPing(peerHandle)
                }
            },
            main,
        )
    }

    private fun startSubscribe(s: WifiAwareSession) {
        s.subscribe(
            SubscribeConfig.Builder().setServiceName(SERVICE_NAME).build(),
            object : DiscoverySessionCallback() {
                override fun onSubscribeStarted(sub: SubscribeDiscoverySession) {
                    subscribeSession = sub
                }
                override fun onServiceDiscovered(
                    peerHandle: PeerHandle,
                    serviceSpecificInfo: ByteArray,
                    matchFilter: List<ByteArray>,
                ) {
                    // Ping the publisher with our id so it can decide roles.
                    subscribeSession?.sendMessage(peerHandle, 0, myPeerId.toByteArray())
                }
                override fun onMessageReceived(peerHandle: PeerHandle, message: ByteArray) {
                    // Publisher tells us its id (first) then the server port.
                    if (message.size == Int.SIZE_BYTES) {
                        handleServerReady(peerHandle, message)
                    } else {
                        handleToPeer[peerHandle] = String(message)
                    }
                }
            },
            main,
        )
    }

    private fun amIServerFor(peerId: String) = myPeerId < peerId

    private fun handleSubscriberPing(peerHandle: PeerHandle) {
        val peerId = handleToPeer[peerHandle] ?: return
        if (!amIServerFor(peerId) || serverSockets.containsKey(peerId)) return
        val pub = publishSession ?: return

        val ss = ServerSocket(0)
        serverSockets[peerId] = ss
        val port = ss.localPort

        val spec = WifiAwareNetworkSpecifier.Builder(pub, peerHandle)
            .setPskPassphrase(PSK)
            .setPort(port)
            .build()
        val req = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI_AWARE)
            .setNetworkSpecifier(spec)
            .build()
        val cb = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                try {
                    val client = ss.accept().apply { keepAlive = true }
                    registerSocket(peerId, client)
                } catch (ioe: IOException) {
                    Log.e(TAG, "accept failed for $peerId", ioe)
                }
            }
            override fun onLost(network: Network) {
                networkCallbacks.remove(peerId)
            }
        }
        networkCallbacks[peerId] = cb
        cm?.requestNetwork(req, cb)

        // Tell the subscriber which port to dial.
        val portBytes = ByteBuffer.allocate(4).order(ByteOrder.BIG_ENDIAN).putInt(port).array()
        main.post {
            try {
                pub.sendMessage(peerHandle, (System.nanoTime() and 0x7fffffff).toInt(), portBytes)
            } catch (e: Exception) {
                Log.e(TAG, "send server-ready failed", e)
            }
        }
    }

    private fun handleServerReady(peerHandle: PeerHandle, payload: ByteArray) {
        val peerId = handleToPeer[peerHandle] ?: return
        if (amIServerFor(peerId) || peerSockets.containsKey(peerId)) return
        val sub = subscribeSession ?: return
        val port = ByteBuffer.wrap(payload).order(ByteOrder.BIG_ENDIAN).int

        val spec = WifiAwareNetworkSpecifier.Builder(sub, peerHandle)
            .setPskPassphrase(PSK)
            .build()
        val req = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI_AWARE)
            .setNetworkSpecifier(spec)
            .build()
        val cb = object : ConnectivityManager.NetworkCallback() {
            override fun onCapabilitiesChanged(network: Network, nc: NetworkCapabilities) {
                if (peerSockets.containsKey(peerId)) return
                val info = (nc.transportInfo as? WifiAwareNetworkInfo) ?: return
                val addr = info.peerIpv6Addr as? Inet6Address ?: return
                try {
                    val sock = network.socketFactory.createSocket(addr, port)
                        .apply { keepAlive = true }
                    registerSocket(peerId, sock)
                } catch (ioe: IOException) {
                    Log.e(TAG, "client connect failed to $peerId", ioe)
                }
            }
            override fun onLost(network: Network) {
                networkCallbacks.remove(peerId)
            }
        }
        networkCallbacks[peerId] = cb
        cm?.requestNetwork(req, cb)
    }

    private fun registerSocket(peerId: String, sock: Socket) {
        if (peerSockets.putIfAbsent(peerId, sock) != null) {
            sock.closeQuietly()
            return
        }
        val connId = connIds.getAndIncrement()
        connSockets[connId] = sock
        main.post { events?.onConnected(connId, peerId) }
        readers.execute { pump(connId, peerId, sock) }
    }

    private fun pump(connId: Int, peerId: String, sock: Socket) {
        val input = try { sock.getInputStream() } catch (e: IOException) { return }
        val buf = ByteArray(64 * 1024)
        while (active) {
            val n = try { input.read(buf) } catch (e: IOException) { break }
            if (n <= 0) break
            val data = buf.copyOf(n)
            main.post { events?.onData(connId, data) }
        }
        sock.closeQuietly()
        peerSockets.remove(peerId)
        connSockets.remove(connId)
        main.post { events?.onClosed(connId) }
    }

    fun send(connId: Int, data: ByteArray): Boolean {
        val sock = connSockets[connId] ?: return false
        return try {
            sock.getOutputStream().write(data)
            true
        } catch (e: IOException) {
            false
        }
    }

    fun stop() {
        active = false
        networkCallbacks.values.forEach { runCatching { cm?.unregisterNetworkCallback(it) } }
        networkCallbacks.clear()
        publishSession?.close(); publishSession = null
        subscribeSession?.close(); subscribeSession = null
        session?.close(); session = null
        serverSockets.values.forEach { it.closeQuietly() }
        peerSockets.values.forEach { it.closeQuietly() }
        serverSockets.clear()
        peerSockets.clear()
        connSockets.clear()
        handleToPeer.clear()
    }

    private fun java.net.Socket.closeQuietly() = try { close() } catch (_: Exception) {}
    private fun java.net.ServerSocket.closeQuietly() = try { close() } catch (_: Exception) {}
}
