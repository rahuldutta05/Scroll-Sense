package com.example.scroll_sense;

import android.app.Service;
import android.content.Intent;
import android.graphics.PixelFormat;
import android.os.IBinder;
import android.view.*;
import android.widget.*;
import com.example.scroll_sense.R;
public class LockOverlayService extends Service {

    private View overlayView;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {

        WindowManager wm = (WindowManager) getSystemService(WINDOW_SERVICE);

        overlayView = LayoutInflater.from(this).inflate(
                getResources().getIdentifier("lock_overlay", "layout", getPackageName()),
                null
        );

        WindowManager.LayoutParams params = new WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                PixelFormat.TRANSLUCENT
        );

        wm.addView(overlayView, params);

        Button plus1 = overlayView.findViewById(R.id.plus1);
        Button plus2 = overlayView.findViewById(R.id.plus2);
        Button plus5 = overlayView.findViewById(R.id.plus5);
        Button plus10 = overlayView.findViewById(R.id.plus10);

        View.OnClickListener extend = v -> {
            stopSelf(); // extend timer logic later
        };

        plus1.setOnClickListener(extend);
        plus2.setOnClickListener(extend);
        plus5.setOnClickListener(extend);
        plus10.setOnClickListener(extend);

        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}