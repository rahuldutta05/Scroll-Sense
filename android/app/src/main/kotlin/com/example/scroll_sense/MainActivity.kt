package com.example.scroll_sense

import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import java.util.*

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.scrollsense/usage_stats"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    "hasUsagePermission" -> {
                        result.success(hasUsagePermission())
                    }

                    "requestUsagePermission" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }

                    "hasOverlayPermission" -> {
                        result.success(Settings.canDrawOverlays(this))
                    }

                    "requestOverlayPermission" -> {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            android.net.Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(null)
                    }

                    "hasAccessibilityPermission" -> {
                        result.success(isAccessibilityEnabled())
                    }

                    "requestAccessibilityPermission" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }

                    "setFocusMode" -> {
                        val active = call.argument<Boolean>("active") ?: false
                        val appsList = call.argument<List<String>>("apps") ?: emptyList()
                        val appsJson = JSONArray(appsList).toString()

                        val prefs = getSharedPreferences("scrollsense_prefs", Context.MODE_PRIVATE)
                        prefs.edit()
                            .putBoolean("focus_mode_active", active)
                            .putString("blocked_apps", appsJson)
                            .apply()

                        result.success(true)
                    }

                    "getUsageStats" -> {
                        if (!hasUsagePermission()) {
                            result.error("NO_PERMISSION", "Usage stats permission not granted", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val startTime = call.argument<Long>("startTime")
                                ?: (System.currentTimeMillis() - 24 * 60 * 60 * 1000L)
                            val endTime = call.argument<Long>("endTime")
                                ?: System.currentTimeMillis()

                            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                            val stats = usm.queryUsageStats(
                                UsageStatsManager.INTERVAL_DAILY, startTime, endTime
                            )

                            val list = mutableListOf<Map<String, Any>>()
                            if (stats != null) {
                                for (stat in stats) {
                                    if (stat.totalTimeInForeground <= 0) continue
                                    if (stat.packageName == packageName) continue

                                    val appName = try {
                                        packageManager.getApplicationLabel(
                                            packageManager.getApplicationInfo(stat.packageName, 0)
                                        ).toString()
                                    } catch (e: PackageManager.NameNotFoundException) {
                                        stat.packageName
                                    }

                                    list.add(mapOf(
                                        "packageName" to stat.packageName,
                                        "appName" to appName,
                                        "totalTime" to stat.totalTimeInForeground,
                                        "launchCount" to 0
                                    ))
                                }
                            }

                            // Sort by usage descending
                            val sorted = list.sortedByDescending { it["totalTime"] as Long }
                            result.success(sorted)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    "getForegroundApp" -> {
                        if (!hasUsagePermission()) {
                            result.success(null)
                            return@setMethodCallHandler
                        }
                        try {
                            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                            val time = System.currentTimeMillis()
                            val appList = usm.queryUsageStats(
                                UsageStatsManager.INTERVAL_DAILY,
                                time - 60 * 1000,
                                time
                            )
                            if (appList != null && appList.isNotEmpty()) {
                                val sorted = appList.sortedByDescending { it.lastTimeUsed }
                                result.success(sorted.first().packageName)
                            } else {
                                result.success(null)
                            }
                        } catch (e: Exception) {
                            result.success(null)
                        }
                    }

                    "startMonitoringService" -> {
                        val intent = Intent(this, UsageMonitorService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun isAccessibilityEnabled(): Boolean {
        val service = "$packageName/${ScrollSenseAccessibilityService::class.java.name}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.contains(service)
    }
}