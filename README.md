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

Foreground app tracking via UsageStatsManager

Continuous session duration monitoring

App open frequency detection

Rapid app-switch loop detection (<5s)

Late-night binge detection (23:00–06:00)

Background monitoring using:

Android Foreground Service

Accessibility Service

🔁 Doom Scroll Detection Engine

ScrollSense continuously evaluates:

Session duration

App category (social vs productive)

Usage time (day vs night)

Continuous foreground activity

Rapid switching frequency

Scroll interaction via accessibility events

Intervention is triggered when:

Continuous usage > threshold
OR
Social media usage > 20 minutes
OR
Night social usage > 10 minutes
🚨 Adaptive Intervention System
Level	Action
L1	Gentle Notification
L2	Warning Popup
L3	Breathing Animation
L4	Temporary Lock
L5	HARD LOCK Overlay

When severe doom-scrolling is detected:

Full-screen non-dismissible overlay

Touch interaction blocked

Back gesture disabled

Live countdown timer

Behavioral breathing exercise

Timer extension options (+1 / +2 / +5 / +10 min)

📊 Behavioral Analytics Engine

ScrollSense computes real-time behavioral metrics:

Focus Score

Addiction Score

Productivity Index

Distraction Score

Night Usage Ratio

Social Media Dependency %

Displayed via:

Daily screen-time bar chart

App-wise usage pie chart

7-day focus trend line

24-hour distraction heatmap

Weekly productivity comparison

🎯 Scheduled Focus Mode

Custom work/study blocks

Selective app blocking

Night auto-lock mode

Pomodoro timer

Session completion tracking

🏆 Habit Tracking

Daily focus streak

Achievement system

Usage reduction tracking

Weekly improvement reports

🏗️ System Architecture

ScrollSense is built as a Flutter + Native Android Hybrid System.

Layer	Technology
Frontend	Flutter (Material 3)
State Management	Riverpod
Local Storage	Hive DB
Monitoring	Android Foreground Service
Scroll Detection	Accessibility Service
Usage Tracking	UsageStatsManager
Overlay Lock	SYSTEM_ALERT_WINDOW
Native Bridge	MethodChannel
Notifications	flutter_local_notifications
📱 Android Components Used

AccessibilityService

Foreground Services

Usage Stats API

Boot Receiver

Overlay Window Manager

Notification Channels

Background Flutter Service

Compatible with:

✅ Android 10 – Android 14+ (API 29–34)
Includes Android 14 Foreground Service Type Compliance.

🔐 Required Permissions

ScrollSense requires the following special Android permissions:

Usage Access Permission

Display Over Other Apps

Accessibility Service

Foreground Service

Query All Packages

These are essential for real-time behavioral monitoring and intervention.

📁 Project Structure
scrollsense/
├── lib/
│   ├── main.dart
│   ├── models/hive_adapters.dart
│   ├── screens/
│   ├── services/
│   ├── widgets/
│   └── utils/app_theme.dart
│
└── android/app/src/main/
    ├── AndroidManifest.xml
    ├── java/com/scrollsense/
    │   ├── MainActivity.java
    │   ├── ScrollSenseAccessibilityService.java
    │   ├── UsageMonitorService.java
    │   └── BootReceiver.java
    └── res/xml/accessibility_service_config.xml
⚙️ Setup Instructions
Install Dependencies
flutter pub get
Run Application
flutter run
Build Release APK
flutter build apk --release
📦 Key Dependencies
Package	Use
flutter_riverpod	State Management
hive_flutter	Local Persistence
fl_chart	Data Visualization
flutter_background_service	Background Monitoring
flutter_local_notifications	Intervention Alerts
permission_handler	Runtime Permissions
🔒 Privacy

All behavioral analytics are processed and stored locally on device.
No user data is transmitted externally.
Accessibility Service only reads app usage events and does not access messages, passwords, or personal content.

⚠️ Known Android Limitations

MIUI / ColorOS / OxygenOS may kill background services

Accessibility must be manually enabled

Overlay permission required for HARD LOCK

Usage Access required for foreground detection

📌 Use Case

Designed as a Digital Wellbeing Intervention System for:

Social media addiction reduction

Productivity enhancement

Behavioral usage analytics

Attention regulation