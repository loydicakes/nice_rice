package com.example.nice_rice  // <-- must match your applicationId

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "app.bluetooth/controls"

    private var pendingResult: MethodChannel.Result? = null

    // Request codes (compat API)
    private val REQ_ENABLE_BT = 1001
    private val REQ_PERMS = 1002

    // Discovery state
    private var discoveryResult: MethodChannel.Result? = null
    private var discoveryReceiver: BroadcastReceiver? = null
    private val discovered = linkedSetOf<BluetoothDevice>()
    private val handler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ensureBluetoothOn" -> { pendingResult = result; ensureBluetoothOn() }
                    "listBondedDevices" -> listBondedDevices(result)
                    "discoverDevices" -> startDiscovery(result)   // short classic discovery
                    else -> result.notImplemented()
                }
            }
    }

    // ---- Ensure BT ON (same as before) --------------------------------------

    private fun ensureBluetoothOn() {
        val adapter = BluetoothAdapter.getDefaultAdapter()
        if (adapter == null) {
            pendingResult?.error("no_adapter", "Device has no Bluetooth adapter", null)
            pendingResult = null
            return
        }
        if (!hasNeededPermissions()) {
            requestNeededPermissions()
            return
        }
        if (adapter.isEnabled) {
            pendingResult?.success(true)
            pendingResult = null
            return
        }
        @Suppress("DEPRECATION")
        val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
        @Suppress("DEPRECATION")
        startActivityForResult(intent, REQ_ENABLE_BT)
    }

    private fun hasNeededPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val scan = ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
            val connect = ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
            scan && connect
        } else {
            ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestNeededPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT),
                REQ_PERMS
            )
        } else {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                REQ_PERMS
            )
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_ENABLE_BT) {
            val isOn = BluetoothAdapter.getDefaultAdapter()?.isEnabled == true
            pendingResult?.success(isOn)
            pendingResult = null
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_PERMS) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            val adapter = BluetoothAdapter.getDefaultAdapter()
            if (!allGranted) {
                pendingResult?.success(false)
                pendingResult = null
                discoveryResult?.success(emptyList<Map<String, String>>())
                discoveryResult = null
                return
            }
            // Continue pending flow: if BT already on, return true, else prompt enable
            if (pendingResult != null) {
                if (adapter?.isEnabled == true) {
                    pendingResult?.success(true)
                    pendingResult = null
                } else {
                    @Suppress("DEPRECATION")
                    startActivityForResult(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE), REQ_ENABLE_BT)
                }
            }
            // If discovery was waiting on perms, start now
            if (discoveryResult != null) startDiscovery(discoveryResult!!)
        }
    }

    // ---- Bonded devices -----------------------------------------------------

    private fun listBondedDevices(result: MethodChannel.Result) {
        val adapter = BluetoothAdapter.getDefaultAdapter()
        if (adapter == null) {
            result.error("no_adapter", "Device has no Bluetooth adapter", null)
            return
        }
        if (!hasNeededPermissions()) {
            result.success(emptyList<Map<String, String>>())
            return
        }
        val list = adapter.bondedDevices?.map { dev ->
            mapOf(
                "name" to (dev.name ?: ""),
                "address" to (dev.address ?: "")
            )
        } ?: emptyList()
        result.success(list)
    }

    // ---- Classic discovery (8 seconds) --------------------------------------

    private fun startDiscovery(result: MethodChannel.Result) {
        val adapter = BluetoothAdapter.getDefaultAdapter()
        if (adapter == null) {
            result.error("no_adapter", "Device has no Bluetooth adapter", null)
            return
        }
        if (!hasNeededPermissions()) {
            // Let onRequestPermissionsResult call us again
            discoveryResult = result
            requestNeededPermissions()
            return
        }

        // Clean previous
        stopDiscoveryInternal()

        discoveryResult = result
        discovered.clear()

        // Receiver
        discoveryReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    BluetoothDevice.ACTION_FOUND -> {
                        val device: BluetoothDevice? =
                            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                        if (device != null) {
                            discovered.add(device)
                        }
                    }
                    BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                        finishDiscovery()
                    }
                }
            }
        }

        // Register filters
        val filter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
        }
        registerReceiver(discoveryReceiver, filter)

        // Start discovery
        adapter.cancelDiscovery()
        val started = adapter.startDiscovery()

        // safety timeout (8s)
        handler.postDelayed({ finishDiscovery() }, 8000L)

        if (!started) {
            finishDiscovery() // will just return whatever we have (probably empty)
        }
    }

    private fun finishDiscovery() {
        stopDiscoveryInternal()
        val list = discovered.map { dev ->
            mapOf(
                "name" to (dev.name ?: ""),
                "address" to (dev.address ?: "")
            )
        }
        discoveryResult?.success(list)
        discoveryResult = null
    }

    private fun stopDiscoveryInternal() {
        val adapter = BluetoothAdapter.getDefaultAdapter()
        try {
            adapter?.cancelDiscovery()
        } catch (_: Exception) {}
        discoveryReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
        }
        discoveryReceiver = null
        handler.removeCallbacksAndMessages(null)
    }

    override fun onDestroy() {
        stopDiscoveryInternal()
        super.onDestroy()
    }
}
