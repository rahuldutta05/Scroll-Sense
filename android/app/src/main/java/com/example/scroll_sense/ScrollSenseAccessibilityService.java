package com.example.scroll_sense;

import com.example.scroll_sense.MainActivity;
import android.accessibilityservice.AccessibilityService;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.provider.Settings;
import android.view.accessibility.AccessibilityEvent;
import androidx.core.app.NotificationCompat;

import org.json.JSONArray;

import java.util.HashSet;
import java.util.Set;

/**
 * ScrollSenseAccessibilityService
 *
 * Listens for window state changes (app switches) and IMMEDIATELY
 * blocks apps when focus mode is active.
 */
public class ScrollSenseAccessibilityService extends AccessibilityService {

    private static final String TAG = "ScrollSenseA11y";
    private static final String CHANNEL_ID = "scrollsense_lock";

    private String currentApp = "";
    private long sessionStartTime = 0;
    private int scrollCount = 0;
    private long lastScrollTime = 0;
    private int rapidScrollCount = 0;

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        if (event == null) return;

        String packageName = "";
        if (event.getPackageName() != null) {
            packageName = event.getPackageName().toString();
        }

        // Skip our own app
        if (packageName.equals(getPackageName())) return;
        // Skip system UI
        if (packageName.equals("com.android.systemui")) return;
        if (packageName.isEmpty()) return;

        switch (event.getEventType()) {
            case AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED:
                handleAppSwitch(packageName);
                break;

            case AccessibilityEvent.TYPE_VIEW_SCROLLED:
                handleScrollEvent(packageName);
                break;
        }
    }

    private void handleAppSwitch(String packageName) {
        if (!packageName.equals(currentApp)) {
            currentApp = packageName;
            sessionStartTime = System.currentTimeMillis();
            scrollCount = 0;
            rapidScrollCount = 0;

            // IMMEDIATELY check focus mode on every app switch
            checkAndShowLockIfNeeded(packageName);
        }
    }

    private void handleScrollEvent(String packageName) {
        long now = System.currentTimeMillis();
        scrollCount++;

        // Detect rapid scrolling (doom scroll)
        if (now - lastScrollTime < 500) {
            rapidScrollCount++;
            if (rapidScrollCount >= 10) {
                saveEvent("rapid_scroll", packageName);
                rapidScrollCount = 0;
            }
        } else {
            rapidScrollCount = 0;
        }
        lastScrollTime = now;

        // Check continuous session length for social apps
        SharedPreferences prefs = getSharedPreferences("scrollsense_prefs", MODE_PRIVATE);
        long sessionDuration = (now - sessionStartTime) / 1000 / 60; // minutes
        int level = prefs.getInt("intervention_level", 3);

        Set<String> SOCIAL = getSocialApps();
        if (SOCIAL.contains(packageName) && sessionDuration >= 20 && level >= 5) {
            triggerLockOverlay(packageName, "Social media binge: " + sessionDuration + " min");
        }
    }

    private void checkAndShowLockIfNeeded(String packageName) {
        SharedPreferences prefs = getSharedPreferences("scrollsense_prefs", MODE_PRIVATE);

        // Check if focus mode is active
        boolean focusModeActive = prefs.getBoolean("focus_mode_active", false);
        if (focusModeActive) {
            String blockedAppsJson = prefs.getString("blocked_apps", "[]");
            if (isAppBlocked(packageName, blockedAppsJson)) {
                triggerLockOverlay(packageName, "Focus mode active");
                return;
            }
        }

        // Check night mode
        int hour = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY);
        boolean nightModeEnabled = prefs.getBoolean("night_mode_enabled", true);
        if (nightModeEnabled && (hour >= 23 || hour <= 5) && getSocialApps().contains(packageName)) {
            sendWarningNotification(packageName);
        }

        // If we reach here, the app is NOT blocked by Focus Mode
        stopService(new Intent(this, LockOverlayService.class));
    }

    private boolean isAppBlocked(String packageName, String blockedAppsJson) {
        try {
            JSONArray arr = new JSONArray(blockedAppsJson);
            for (int i = 0; i < arr.length(); i++) {
                if (arr.getString(i).equals(packageName)) return true;
            }
        } catch (Exception e) {
            // Fallback: simple contains check
            return blockedAppsJson.contains(packageName);
        }
        return false;
    }

    private void triggerLockOverlay(String packageName, String reason) {
        // Only show if overlay permission granted
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            sendWarningNotification(packageName);
            return;
        }

        Intent overlayIntent = new Intent(this, LockOverlayService.class);
        overlayIntent.putExtra("locked_app", packageName);
        overlayIntent.putExtra("lock_reason", reason);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(overlayIntent);
        } else {
            startService(overlayIntent);
        }
    }

    private void sendWarningNotification(String packageName) {
        NotificationManager nm = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID, "ScrollSense Alerts", NotificationManager.IMPORTANCE_HIGH
            );
            nm.createNotificationChannel(channel);
        }

        Intent intent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(
                this, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle("⚠️ ScrollSense Alert")
                .setContentText("This app is blocked during Focus Mode")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .build();

        nm.notify((int) System.currentTimeMillis(), notification);
    }

    private void saveEvent(String eventType, String packageName) {
        SharedPreferences prefs = getSharedPreferences("scrollsense_events", MODE_PRIVATE);
        String key = eventType + "_" + System.currentTimeMillis();
        prefs.edit().putString(key, packageName).apply();
    }

    private Set<String> getSocialApps() {
        Set<String> apps = new HashSet<>();
        apps.add("com.instagram.android");
        apps.add("com.tiktok.android");
        apps.add("com.twitter.android");
        apps.add("com.snapchat.android");
        apps.add("com.reddit.frontpage");
        apps.add("com.google.android.youtube");
        apps.add("com.facebook.katana");
        return apps;
    }

    @Override
    public void onInterrupt() {}

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
    }
}
