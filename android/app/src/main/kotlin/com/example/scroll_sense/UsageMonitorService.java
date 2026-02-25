package com.example.scroll_sense;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;

import androidx.core.app.NotificationCompat;
import com.example.scroll_sense.LockOverlayService;

import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.SortedMap;
import java.util.TreeMap;

public class UsageMonitorService extends Service {

    private static final String CHANNEL_ID = "scrollsense_bg";
    private static final int NOTIFICATION_ID = 888;
    private static final int CHECK_INTERVAL_MS = 15000;

    private static final Set<String> SOCIAL_APPS = new HashSet<>(Arrays.asList(
            "com.instagram.android",
            "com.tiktok.android",
            "com.twitter.android",
            "com.snapchat.android",
            "com.reddit.frontpage",
            "com.google.android.youtube"
    ));

    private Handler handler;
    private String currentApp = "";
    private long sessionStart = 0;
    private int sessionCount = 0;

    private final Runnable monitorRunnable = new Runnable() {
        @Override
        public void run() {
            checkUsage();
            handler.postDelayed(this, CHECK_INTERVAL_MS);
        }
    };

    @Override
    public void onCreate() {
        super.onCreate();
        handler = new Handler(Looper.getMainLooper());
        createNotificationChannel();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        startForeground(NOTIFICATION_ID, buildNotification("Monitoring screen time..."));
        handler.post(monitorRunnable);
        return START_STICKY;
    }

    private void checkUsage() {

        String foregroundApp = getForegroundApp();
        if (foregroundApp == null || foregroundApp.equals(getPackageName())) return;

        if (!foregroundApp.equals(currentApp)) {
            currentApp = foregroundApp;
            sessionStart = System.currentTimeMillis();
            sessionCount = 0;
        } else {
            sessionCount++;
        }

        long sessionMinutes = (System.currentTimeMillis() - sessionStart) / 1000 / 60;
        boolean isSocial = SOCIAL_APPS.contains(currentApp);
        boolean isNight = isNightTime();

        SharedPreferences prefs = getSharedPreferences("scrollsense_prefs", MODE_PRIVATE);
        int threshold = prefs.getInt("continuous_threshold_mins", 30);

        boolean shouldIntervene = sessionMinutes >= threshold ||
                (isSocial && sessionMinutes >= 20) ||
                (isNight && isSocial && sessionMinutes >= 10);

        if (shouldIntervene) {

            boolean focusModeActive = prefs.getBoolean("focus_mode_active", false);
            int level = prefs.getInt("intervention_level", 3);

            if (level >= 5 || focusModeActive) {

                // 😈 HARD LOCK TRIGGER
                Intent overlayIntent = new Intent(this, LockOverlayService.class);
                overlayIntent.putExtra("locked_app", currentApp);
                overlayIntent.putExtra("lock_reason",
                        isNight ? "Late-night binge" : "Continuous usage");

                startForegroundService(overlayIntent);
            }
        }
    }

    private String getForegroundApp() {
        try {
            UsageStatsManager usm = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
            long time = System.currentTimeMillis();

            List<UsageStats> appList = usm.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    time - 1000 * 60,
                    time
            );

            if (appList != null && !appList.isEmpty()) {
                SortedMap<Long, UsageStats> sortedMap = new TreeMap<>();
                for (UsageStats stats : appList) {
                    sortedMap.put(stats.getLastTimeUsed(), stats);
                }
                if (!sortedMap.isEmpty()) {
                    return sortedMap.get(sortedMap.lastKey()).getPackageName();
                }
            }
        } catch (Exception ignored) {}
        return null;
    }

    private boolean isNightTime() {
        int hour = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY);
        return hour >= 23 || hour <= 5;
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "ScrollSense Monitor",
                    NotificationManager.IMPORTANCE_LOW
            );
            NotificationManager nm = getSystemService(NotificationManager.class);
            nm.createNotificationChannel(channel);
        }
    }

    private Notification buildNotification(String content) {
        return new NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("ScrollSense")
                .setContentText(content)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        handler.removeCallbacks(monitorRunnable);
        super.onDestroy();
    }
}