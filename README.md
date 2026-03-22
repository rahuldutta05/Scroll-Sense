📵 ScrollSense — Intelligent Doom-Scroll Detection System

A hybrid Flutter + Native Android behavioral intervention system that detects addictive scrolling patterns in real time and enforces focus through automated lock overlays and usage analytics.

ScrollSense continuously monitors foreground app usage and interaction patterns to identify digital addiction behaviors such as:

Continuous social media consumption
Late-night binge usage
Rapid app switching loops
High distraction frequency

When detected, the system automatically triggers adaptive interventions including focus locks, warnings, and temporary app blocking to restore attention control.

🚀 Core Capabilities
🧠 Real-Time Usage Monitoring
* **Native Usage Tracking**: Sourced directly from Android's `UsageStatsManager` & `UsageEvents` for millisecond precision.
* **Session Duration Monitoring**: Real-time foreground app tracking with minute-level accuracy.
* **App Open Frequency**: Tracks frequent app re-launches (API 28+).
* **Anomaly Detection**: Rapid app-switch loop detection (<5s) and late-night binge patterns.

🚨 Adaptive Intervention System
Under severe doom-scrolling, ScrollSense triggers a **Level 5 HARD LOCK**:
* **Focus Capture**: The overlay aggressively hijacks window focus to **force-pause** underlying media (YouTube, Spotify, etc.).
* **Opaque Shield**: Implements a `PixelFormat.OPAQUE` overlay for total visual blocking.
* **Back Interception**: Captures system back gestures to prevent bypass while ensuring a safe exit to the launcher.

📊 Behavioral Analytics Engine (Now Real Data Driven)
* **Behavioral Scores**: Real-time Focus, Addiction, and Productivity scores calculated from active usage.
* **Hourly Heatmap**: 24-hour distraction intensity buckets powered by native system telemetry.
* **Weekly Progress**: Comparative reports against previous 7-day windows.

🎯 Scheduled Focus Mode
- Custom work/study blocks
- Selective app blocking
- Night auto-lock mode
- Pomodoro timer
- Session completion tracking

🏆 Habit Tracking
- Daily focus streak
- Achievement system
- Usage reduction tracking
- Weekly improvement reports

🏗️ System Architecture
ScrollSense is built as a Flutter + Native Android Hybrid System.

Layer | Technology
--- | ---
Frontend | Flutter (Material 3)
State Management | Riverpod
Local Storage | Hive DB
Monitoring | Android Foreground Service (API 34+ Compliant)
Scroll Detection | Accessibility Service
Usage Tracking | Native MethodChannel + UsageStatsManager
Overlay Lock | SYSTEM_ALERT_WINDOW (Focus capturing)
Native Bridge | MethodChannel

📱 Android Components Used
- AccessibilityService
- Foreground Services
- Usage Stats API
- Boot Receiver
- Overlay Window Manager
- Notification Channels
- Background Flutter Service

Compatible with:
✅ Android 10 – Android 14+ (API 29–34)
Includes Android 14 Foreground Service Type Compliance.

🔐 Required Permissions
ScrollSense requires the following special Android permissions:
- Usage Access Permission
- Display Over Other Apps
- Accessibility Service
- Foreground Service
- Query All Packages

These are essential for real-time behavioral monitoring and intervention.

📁 Project Structure
```text
scrollsense/
├── lib/
│   ├── services/           # UsageStatsService, DoomScrollDetector
│   ├── screens/            # Dashboard, Home, Focus Mode
│   └── models/             # Hive TypeAdapters
└── android/app/src/main/kotlin/com/example/scroll_sense/
    ├── MainActivity.kt               # Native MethodChannel Bridge
    ├── LockOverlayService.java       # Aggressive Focus-Hijacking Overlay
    ├── UsageMonitorService.java      # Background Usage Polling
    └── ScrollSenseAccessibilityService.java
```

⚙️ Setup Instructions
1. `flutter pub get`
2. Enable **Usage Access** & **Display over other apps** permissions.
3. Enable **ScrollSense Accessibility Service**.
4. `flutter run --release`

📦 Key Dependencies
Package | Use
--- | ---
flutter_riverpod | State Management
hive_flutter | Local Persistence
fl_chart | Data Visualization
flutter_background_service | Background Monitoring
flutter_local_notifications | Intervention Alerts
permission_handler | Runtime Permissions

🔒 Privacy
All behavioral analytics are processed and stored locally on device.
No user data is transmitted externally.
Accessibility Service only reads app usage events and does not access messages, passwords, or personal content.

⚠️ Known Android Limitations
- MIUI / ColorOS / OxygenOS may kill background services
- Accessibility must be manually enabled
- Overlay permission required for HARD LOCK
- Usage Access required for foreground detection

📌 Use Case
Designed as a Digital Wellbeing Intervention System for:
- Social media addiction reduction
- Productivity enhancement
- Behavioral usage analytics
- Attention regulation