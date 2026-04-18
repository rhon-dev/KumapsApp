# 🎯 KUMAPS - Complete Setup Guide for Group Members

**NO EXPERIENCE NEEDED** - Just follow these steps exactly!

This guide works for **Windows, macOS, or Linux**, with real or simulated phones.

---

## 📋 BEFORE YOU START

You need:
- This repository (cloned to your computer)
- **Python 3.10+** installed
- **Flutter & Dart** installed
- A phone (real or emulator/simulator)

**Don't have these?** See the troubleshooting section.

---

## ✅ PART 1: VERIFY YOUR SETUP

### Check Python
```bash
python3 --version
```
Should show `Python 3.10.x` or higher. If you see 3.9 or lower, [install Python 3.10+](https://www.python.org/downloads/).

### Check Flutter
```bash
flutter --version
dart --version
```

If either fails, [install Flutter](https://flutter.dev/docs/get-started/install).

### Check a Phone is Available
```bash
flutter devices
```

You should see at least one device listed (Android emulator, iOS simulator, or real phone).

---

## 🚀 PART 2: START THE FLASK BACKEND

**⚠️ DO THIS FIRST IN TERMINAL 1**

### macOS / Linux
```bash
# Navigate to the project
cd /path/to/KumapsApp

# Go to ml_training folder
cd ml_training

# Create virtual environment (one time only)
python3 -m venv venv

# Activate it
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start Flask
python3 flask_api.py
```

### Windows (Command Prompt or PowerShell)
```bash
# Navigate to the project
cd C:\path\to\KumapsApp

# Go to ml_training folder
cd ml_training

# Create virtual environment (one time only)
python -m venv venv

# Activate it - CHOOSE ONE BASED ON YOUR TERMINAL:
# For Command Prompt:
venv\Scripts\activate.bat
# For PowerShell:
venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Start Flask
python flask_api.py
```

### ✅ What You Should See in Terminal 1

```
Loading gesture recognition model...
✅ Model loaded: models/gesture_model.pkl
✅ Signs: ['HELLO', 'HOW ARE YOU', 'YES', 'ONE', 'TEN']
🚀 Gesture Recognition Flask API
 * Running on http://0.0.0.0:5001
 * Press CTRL+C to quit
```

**KEEP THIS TERMINAL RUNNING** during development!

---

## 📱 PART 3: START THE FLUTTER APP

**⚠️ DO THIS SECOND IN TERMINAL 2** (after Flask is running)

### Step 1: Open New Terminal
Open a **new terminal window** (don't close Terminal 1).

### Step 2: Navigate and Run
```bash
# Navigate to project root
cd /path/to/KumapsApp

# Get Flutter dependencies
flutter pub get

# Run the app
flutter run
```

### Step 3: Choose Your Device
When you run `flutter run`, you'll see a list like:
```
Connected devices:
1 • iPhone 15 Pro (mobile)    • ios            • iOS 17.4 (simulator)
2 • Pixel 8 Pro (mobile)       • android        • Android 14 (emulator)
3 • macOS (desktop)            • macos          • macOS 14.6 (desktop)

Which device do you want to target (or "q" to quit)? 
```

**Type the number** of the device you want (e.g., `1` for iPhone).

### ✅ What You Should See in Terminal 2

```
Using FlutterApp as the default project.

✓ Built build/app/outputs/flutter-apk/app-debug.apk (35.6 MB).
Installing and launching...
D/FlutterActivity: FlutterActivity onStart
I/Flutter: Gesture Recognition App Started
I/Flutter: Camera initialized on device
```

The app should open on your phone/simulator, showing:
- **Bottom navigation** with 5 icons
- **Home screen** with welcome message
- **Gesture recognition ready** to use

---

## 🎬 PART 4: TEST GESTURE RECOGNITION

### On Your Phone/Simulator:

1. **Tap the "Translate" tab** (bottom navigation)
2. **You'll see a camera view** with hand skeleton overlay
3. **Make one of these hand gestures:**
   - ✋ Open hand (HELLO)
   - 👍 Thumbs up (YES)
   - ☝️ One finger (ONE)
   - ✌️ Two fingers (TWO)
   - ✊ Closed fist (TEN)

4. **Watch the results** at the bottom of the screen:
   ```
   Recognized: HELLO
   Confidence: 95%
   ```

### 📹 What Happens Behind the Scenes

```
Your Phone Camera
        ↓
Flutter captures frame
        ↓
Sends hand landmarks to Flask (port 5001)
        ↓
Flask model predicts gesture
        ↓
Returns confidence score & gesture name
        ↓
Flutter shows result on screen
```

---

## 📱 PART 5: GRANT CAMERA PERMISSIONS

Your phone might ask for camera permission. **TAP "ALLOW"**

### iOS (Real Device)
- Settings → Privacy → Camera → Enable for Kumpas

### Android (Real Device)
- Settings → Apps → Kumpas → Permissions → Camera → Allow

### Simulator/Emulator
- Permissions are usually pre-granted, but if asked, tap "Allow"

---

## ⚡ DAILY WORKFLOW

### Morning: Start Development
```bash
# Terminal 1 - Flask Backend
cd /path/to/KumapsApp/ml_training
source venv/bin/activate  # (or venv\Scripts\activate.bat on Windows)
python3 flask_api.py

# Terminal 2 - Flutter App
cd /path/to/KumapsApp
flutter run
```

### During Development: Make Changes
- Edit code
- Flutter hot-reload: Press `r` in Terminal 2
- Flask will automatically reload on changes

### Quick Test: Flask is Working
```bash
# Terminal 3 - Test request
curl http://localhost:5001/health
```

Should return:
```json
{
  "status": "ok",
  "model": "gesture_recognition",
  "signs": ["HELLO", "HOW ARE YOU", "YES", "ONE", "TEN"],
  "timestamp": "2026-04-18T10:30:45.123456"
}
```

---

## 🛑 STOPPING EVERYTHING

### Stop Flask
- In Terminal 1, press **Ctrl+C**

### Stop Flutter
- In Terminal 2, press **Ctrl+C** or **q**

---

## ✋ COMMON ISSUES (See TROUBLESHOOTING.md for detailed fixes)

| Issue | Quick Fix |
|-------|-----------|
| `python3 not found` | Install Python 3.10+ |
| `flutter: command not found` | Add Flutter to PATH |
| `Port 5001 already in use` | See TROUBLESHOOTING.md |
| `Connection refused` | Make sure Flask is running in Terminal 1 |
| `Camera not working` | Check permissions (iOS/Android instructions above) |
| `App crashes` | Check logs in Terminal 2, see TROUBLESHOOTING.md |

---

## 📚 NEXT STEPS

1. **Read QUICK_REFERENCE.md** - Copy-paste commands for your OS
2. **Read FILE_STRUCTURE.md** - Understand what each folder does
3. **Read TROUBLESHOOTING.md** - Before asking for help
4. **Read NETWORK_CONFIGURATION_GUIDE.md** - Understand Flask port setup
5. **Start coding!** - Make improvements and commit

---

## 🎓 USEFUL COMMANDS

### Reset Everything (Start Fresh)
```bash
# Terminal 1
cd /path/to/KumapsApp
rm -rf ml_training/venv  # or venv on Windows
rm -rf build/

# Terminal 2
rm -rf build/
rm -rf .dart_tool/
flutter clean
flutter pub get
```

### See Flask Logs
- Check Terminal 1 running `python3 flask_api.py`

### See Flutter Logs
- Check Terminal 2 running `flutter run`
- Or run: `flutter logs` in new terminal

### Check App on Real Phone
- Connect phone via USB
- `flutter run` will detect it
- Allow USB debugging when phone asks

---

## 📞 IF YOU GET STUCK

1. **Check TROUBLESHOOTING.md** - Most common issues are there
2. **Check QUICK_REFERENCE.md** - Copy exact commands for your OS
3. **Read error messages carefully** - They usually tell you exactly what's wrong
4. **Try the "Reset Everything" commands** above
5. **Ask group lead** - Share Terminal 1 and Terminal 2 output

---

## ✅ SETUP COMPLETE

You're ready to:
- 🎬 Capture hand gestures
- 🤖 Get ML predictions
- 📊 Improve the model
- 📱 Deploy on any phone

**Questions?** Read the other documentation files in this repo!
