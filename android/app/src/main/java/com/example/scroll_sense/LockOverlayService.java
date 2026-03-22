package com.example.scroll_sense;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.graphics.PixelFormat;
import android.os.Build;
import android.os.IBinder;
import android.provider.Settings;
import android.view.*;
import android.widget.*;
import androidx.core.app.NotificationCompat;
import android.content.pm.ServiceInfo;

public class LockOverlayService extends Service {

    private static final String CHANNEL_ID = "scrollsense_lock_overlay";
    private static final int NOTIF_ID = 999;
    private WindowManager wm;
    private View overlayView;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {

        createNotificationChannel();
        Notification notif = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle("ScrollSense")
                .setContentText("Focus mode lock active")
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIF_ID, notif, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE);
        } else {
            startForeground(NOTIF_ID, notif);
        }

        // Guard: overlay permission is required
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            stopSelf();
            return START_NOT_STICKY;
        }

        String lockedApp = intent != null ? intent.getStringExtra("locked_app") : "app";
        String lockReason = intent != null ? intent.getStringExtra("lock_reason") : "Focus mode active";

        wm = (WindowManager) getSystemService(WINDOW_SERVICE);

        if (overlayView != null) {
            try { wm.removeView(overlayView); } catch (Exception ignored) {}
        }

        // Build overlay view programmatically (no XML dependency)
        overlayView = buildOverlayView(lockedApp, lockReason);

        WindowManager.LayoutParams params = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.OPAQUE
        );

        try {
            wm.addView(overlayView, params);
        } catch (Exception e) {
            stopSelf();
        }

        return START_STICKY;
    }

    private View buildOverlayView(String packageName, String reason) {
        // Build a full-screen blocking overlay programmatically
        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(0xFF1A1A2E); // fully opaque

        root.setFocusableInTouchMode(true);
        root.setOnKeyListener((v, keyCode, event) -> {
            if (keyCode == KeyEvent.KEYCODE_BACK && event.getAction() == KeyEvent.ACTION_UP) {
                Intent homeIntent = new Intent(Intent.ACTION_MAIN);
                homeIntent.addCategory(Intent.CATEGORY_HOME);
                homeIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(homeIntent);
                stopSelf();
                return true;
            }
            return false;
        });

        LinearLayout inner = new LinearLayout(this);
        inner.setOrientation(LinearLayout.VERTICAL);
        inner.setGravity(android.view.Gravity.CENTER);
        inner.setPadding(48, 48, 48, 48);

        TextView icon = new TextView(this);
        icon.setText("\uD83D\uDD12");
        icon.setTextSize(72);
        icon.setGravity(android.view.Gravity.CENTER);

        TextView title = new TextView(this);
        title.setText("App Blocked");
        title.setTextSize(28);
        title.setTextColor(0xFFFFFFFF);
        title.setTypeface(null, android.graphics.Typeface.BOLD);
        title.setGravity(android.view.Gravity.CENTER);

        TextView subtitle = new TextView(this);
        subtitle.setText(reason);
        subtitle.setTextSize(16);
        subtitle.setTextColor(0xAAFFFFFF);
        subtitle.setGravity(android.view.Gravity.CENTER);

        TextView appText = new TextView(this);
        appText.setText(packageName.substring(packageName.lastIndexOf('.') + 1)
                .replace("android", "").replace("com", ""));
        appText.setTextSize(13);
        appText.setTextColor(0x88FFFFFF);
        appText.setGravity(android.view.Gravity.CENTER);

        Button dismiss = new Button(this);
        dismiss.setText("Go Back");
        dismiss.setBackgroundColor(0xFF6C63FF);
        dismiss.setTextColor(0xFFFFFFFF);
        dismiss.setPadding(48, 24, 48, 24);
        dismiss.setOnClickListener(v -> {
            // Navigate back to home screen
            Intent homeIntent = new Intent(Intent.ACTION_MAIN);
            homeIntent.addCategory(Intent.CATEGORY_HOME);
            homeIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(homeIntent);
            stopSelf();
        });

        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT);
        lp.setMargins(0, 32, 0, 0);

        inner.addView(icon);
        inner.addView(title);
        inner.addView(subtitle);
        inner.addView(appText);
        inner.addView(dismiss, lp);

        FrameLayout.LayoutParams flp = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT);
        flp.gravity = android.view.Gravity.CENTER;
        root.addView(inner, flp);

        return root;
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel ch = new NotificationChannel(
                    CHANNEL_ID, "Focus Lock", NotificationManager.IMPORTANCE_LOW);
            NotificationManager nm = getSystemService(NotificationManager.class);
            if (nm != null) nm.createNotificationChannel(ch);
        }
    }

    @Override
    public void onDestroy() {
        if (overlayView != null && wm != null) {
            try { wm.removeView(overlayView); } catch (Exception ignored) {}
            overlayView = null;
        }
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) { return null; }
}