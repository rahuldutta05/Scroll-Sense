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
import android.view.accessibility.AccessibilityEvent;
import androidx.core.app.NotificationCompat;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/**
 * ScrollSenseAccessibilityService
 * 
 * Listens for:
 * - Window state changes (app switches)
 * - View scroll events (doom scroll detection)
 * - Content changes (activity monitoring)
 */
public class ScrollSenseAccessibilityService extends AccessibilityService {

    private static final String TAG = "ScrollSenseA11y";
    private static final String CHANNEL_ID = "scrollsense_lock";

    // Social media apps to monitor
    private static final Set<String> MONITORED_APPS = new HashSet<>(Arrays.asList(
            "com.instagram.android",
            "com.tiktok.android",
            "com.twitter.android",
            "com.snapchat.android",
            "com.reddit.frontpage",
            "com.google.android.youtube",
            "com.facebook.katana"
    ));

    private String currentApp = "";
    private long sessionStartTime = 0;
    private int scrollCount = 0;
    private long lastScrollTime = 0;
    private int rapidScrollCount = 0;
    private boolean isLocked = false;

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        if (event == null) return;

        String packageName = "";
        if (event.getPackageName() != null) {
            packageName = event.getPackageName().toString();
        }

        // Skip our own app
        if (packageName.equals(getPackageName())) return;

        switch (event.getEventType()) {
            case AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED:
                handleAppSwitch(packageName);
                break;

            case AccessibilityEvent.TYPE_VIEW_SCROLLED:
                handleScrollEvent(packageName);
                break;

            case AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED:
                // Track content updates for activity monitoring
                break;
        }
    }

    private void handleAppSwitch(String packageName) {
        if (!packageName.equals(currentApp)) {
            currentApp = packageName;
            sessionStartTime = System.currentTimeMillis();
            scrollCount = 0;
            rapidScrollCount = 0;

            // Check if we need to show lock overlay
            checkAndShowLockIfNeeded(packageName);
        }
    }

    private void handleScrollEvent(String packageName) {
        if (!MONITORED_APPS.contains(packageName)) return;

        long now = System.currentTimeMillis();
        scrollCount++;

        // Detect rapid scrolling (doom scroll)
        if (now - lastScrollTime < 500) { // Less than 500ms between scrolls
            rapidScrollCount++;
            if (rapidScrollCount >= 10) {
                // Rapid scroll detected - trigger intervention
                saveEvent("rapid_scroll", packageName);
                rapidScrollCount = 0; // Reset to avoid spam
            }
        } else {
            rapidScrollCount = 0;
        }

        lastScrollTime = now;

        // Check continuous session length
        long sessionDuration = (now - sessionStartTime) / 1000 / 60; // in minutes
        if (sessionDuration >= 20 && MONITORED_APPS.contains(packageName)) {
            triggerIntervention(packageName, "Social media binge: " + sessionDuration + " min");
        }
    }

    private void checkAndShowLockIfNeeded(String packageName) {
        SharedPreferences prefs = getSharedPreferences("scrollsense_prefs", MODE_PRIVATE);
        
        // Check if focus mode is active and this app is blocked
        boolean focusModeActive = prefs.getBoolean("focus_mode_active", false);
        String blockedAppsJson = prefs.getString("blocked_apps", "[]");
        
        if (focusModeActive && blockedAppsJson.contains(packageName)) {
            showLockOverlay(packageName, "Focus mode active");
        }

        // Check night mode
        int hour = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY);
        boolean nightModeEnabled = prefs.getBoolean("night_mode_enabled", true);
        if (nightModeEnabled && (hour >= 23 || hour <= 5) && MONITORED_APPS.contains(packageName)) {
            // Warn user about late night usage
            sendWarningNotification(packageName);
        }
    }

    private void triggerIntervention(String packageName, String reason) {
        if (isLocked) return;
        
        SharedPreferences prefs = getSharedPreferences("scrollsense_prefs", MODE_PRIVATE);
        int level = prefs.getInt("intervention_level", 3);

        if (level >= 5) {
            showLockOverlay(packageName, reason);
        } else if (level >= 4) {
            sendWarningNotification(packageName);
        }
    }

    private void showLockOverlay(String packageName, String reason) {
        isLocked = true;
        Intent intent = new Intent(this, MainActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        intent.putExtra("show_lock", true);
        intent.putExtra("locked_app", packageName);
        intent.putExtra("lock_reason", reason);
        startActivity(intent);
    }

    private void sendWarningNotification(String packageName) {
        NotificationManager nm = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID, "ScrollSense Alerts", NotificationManager.IMPORTANCE_HIGH
            );
            channel.setDescription("Doom scroll detection alerts");
            nm.createNotificationChannel(channel);
        }

        Intent intent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(
                this, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle("⚠️ Doom Scroll Alert")
                .setContentText("You've been on " + packageName + " for a while")
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

    @Override
    public void onInterrupt() {
        // Service interrupted
    }

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        // Accessibility service connected
    }
}
