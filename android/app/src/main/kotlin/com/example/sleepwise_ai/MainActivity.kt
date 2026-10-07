package com.example.sleepwise_ai

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sleepwise/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "manufacturer" -> result.success(Build.MANUFACTURER.lowercase())
                    "openAppPermissions" -> result.success(openAppPermissions())
                    else -> result.notImplemented()
                }
            }
    }

    /// เปิดหน้าตั้งสิทธิ์ของแอปนี้ ถ้าเป็น Xiaomi จะไปหน้าสิทธิ์เฉพาะของ MIUI/HyperOS
    /// (มีข้อ "แสดงบนหน้าจอล็อก" / "แสดงหน้าต่างป๊อปอัปขณะทำงานเบื้องหลัง")
    /// ถ้าเปิดไม่ได้ก็ถอยไปหน้าข้อมูลแอปมาตรฐานของ Android
    private fun openAppPermissions(): Boolean {
        try {
            val miui = Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                setComponent(
                    ComponentName(
                        "com.miui.securitycenter",
                        "com.miui.permcenter.permissions.PermissionsEditorActivity",
                    ),
                )
                putExtra("extra_pkgname", packageName)
            }
            startActivity(miui)
            return true
        } catch (_: Exception) {
            // ไม่ใช่ Xiaomi หรือ ROM ไม่รองรับ — ใช้หน้ามาตรฐานแทน
        }
        return try {
            startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                },
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }
}