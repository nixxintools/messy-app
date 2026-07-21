package dev.messy.messy

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.io.IOException
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

/**
 * Wi-Fi Direct transport (WifiP2pManager). The broadest-support high-throughput
 * no-shared-network path — Wi-Fi Direct exists on virtually every Android phone
 * since 4.0, including budget handsets that lack Wi-Fi Aware. Fills the gap for
 * low-cost devices.
 *
 * Once a group forms, the members share a subnet with the group owner at a
 * known address, so we run a plain TCP socket over it (group owner listens,
 * clients connect) and stream bytes to Dart — the same transparent-byte-pipe
 * model as [WifiAwareTransport], reusing Messy's Dart framing/handshake/crypto.
 *
 * Caveat (documented): a device can be in only ONE Wi-Fi Direct group at a
 * time, so this is a fast point-to-point / small-cluster link, not a multi-hop
 * backbone — BLE still does the long chaining. Isolated + fail-safe.
 */
class WifiDirectTransport(private val context: Context) {

    interface Events {
        fun onConnected(connId: Int, peerId: String)
        fun onData(connId: Int, data: ByteArray)
        fun onClosed(connId: Int)
    }

    companion object {
        private const val TAG = "MessyWifiDirect"
        private const val PORT = 47555
    }

    private val main = Handler(Looper.getMainLooper())
    private val manager =
        context.getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
    private var channel: WifiP2pManager.Channel? = null
    private val readers = Executors.newCachedThreadPool()
    private val connIds = AtomicInteger(1)
    private val connSockets = ConcurrentHashMap<Int, Socket>()

    private var events: Events? = null
    @Volatile private var active = false
    @Volatile private var serverSocket: ServerSocket? = null
    private var receiver: BroadcastReceiver? = null

    fun isSupported(): Boolean =
        manager != null &&
            context.packageManager.hasSystemFeature(
                "android.hardware.wifi.direct",
            )

    fun start(events: Events): Boolean {
        if (active) return true
        val mgr = manager ?: return false
        if (!isSupported()) return false
        this.events = events
        active = true
        channel = mgr.initialize(context, Looper.getMainLooper(), null)
        registerReceiver()
        discover()
        return true
    }

    private fun discover() {
        val mgr = manager ?: return
        val ch = channel ?: return
        try {
            mgr.discoverPeers(ch, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {}
                override fun onFailure(reason: Int) {}
            })
        } catch (e: SecurityException) {
            Log.e(TAG, "discoverPeers denied", e)
        }
    }

    private fun registerReceiver() {
        val filter = IntentFilter().apply {
            addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
        }
        val rcv = object : BroadcastReceiver() {
            override fun onReceive(c: Context, intent: Intent) {
                when (intent.action) {
                    WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> requestPeers()
                    WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION ->
                        onConnectionChanged()
                }
            }
        }
        receiver = rcv
        context.registerReceiver(rcv, filter)
    }

    private fun requestPeers() {
        val mgr = manager ?: return
        val ch = channel ?: return
        try {
            mgr.requestPeers(ch) { peers ->
                // Connect to the first available peer; the group-owner logic
                // and Messy's own handshake sort out roles/identity.
                val device = peers.deviceList.firstOrNull {
                    it.status == WifiP2pDevice.AVAILABLE
                } ?: return@requestPeers
                connectTo(device)
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "requestPeers denied", e)
        }
    }

    private fun connectTo(device: WifiP2pDevice) {
        val mgr = manager ?: return
        val ch = channel ?: return
        val config = WifiP2pConfig().apply { deviceAddress = device.deviceAddress }
        try {
            mgr.connect(ch, config, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {}
                override fun onFailure(reason: Int) {}
            })
        } catch (e: SecurityException) {
            Log.e(TAG, "connect denied", e)
        }
    }

    private fun onConnectionChanged() {
        val mgr = manager ?: return
        val ch = channel ?: return
        mgr.requestConnectionInfo(ch) { info ->
            if (!info.groupFormed) return@requestConnectionInfo
            if (info.isGroupOwner) {
                startServer()
            } else {
                val host = info.groupOwnerAddress?.hostAddress ?: return@requestConnectionInfo
                connectClient(host)
            }
        }
    }

    private fun startServer() {
        if (serverSocket != null) return
        readers.execute {
            try {
                val ss = ServerSocket(PORT)
                serverSocket = ss
                while (active) {
                    val sock = try { ss.accept() } catch (e: IOException) { break }
                    sock.keepAlive = true
                    register(sock, sock.inetAddress.hostAddress ?: "peer")
                }
            } catch (e: IOException) {
                Log.e(TAG, "server socket failed", e)
            }
        }
    }

    private fun connectClient(host: String) {
        readers.execute {
            try {
                val sock = Socket()
                sock.connect(InetSocketAddress(host, PORT), 5000)
                sock.keepAlive = true
                register(sock, host)
            } catch (e: IOException) {
                Log.e(TAG, "client connect failed to $host", e)
            }
        }
    }

    private fun register(sock: Socket, peerId: String) {
        val connId = connIds.getAndIncrement()
        connSockets[connId] = sock
        main.post { events?.onConnected(connId, peerId) }
        readers.execute { pump(connId, sock) }
    }

    private fun pump(connId: Int, sock: Socket) {
        val input = try { sock.getInputStream() } catch (e: IOException) { return }
        val buf = ByteArray(64 * 1024)
        while (active) {
            val n = try { input.read(buf) } catch (e: IOException) { break }
            if (n <= 0) break
            val data = buf.copyOf(n)
            main.post { events?.onData(connId, data) }
        }
        try { sock.close() } catch (_: Exception) {}
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
        receiver?.let { runCatching { context.unregisterReceiver(it) } }
        receiver = null
        try { serverSocket?.close() } catch (_: Exception) {}
        serverSocket = null
        connSockets.values.forEach { runCatching { it.close() } }
        connSockets.clear()
        val mgr = manager
        val ch = channel
        if (mgr != null && ch != null) {
            runCatching {
                mgr.removeGroup(ch, object : WifiP2pManager.ActionListener {
                    override fun onSuccess() {}
                    override fun onFailure(reason: Int) {}
                })
            }
        }
    }
}
