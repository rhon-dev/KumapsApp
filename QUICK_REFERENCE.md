# ⚡ QUICK REFERENCE - Copy-Paste Commands

Use these commands based on your operating system.

---

## 🍎 macOS / Linux

### First Time Setup
```bash
# Clone the repo
git clone <repo-url>
cd KumapsApp

# Flask setup (Terminal 1)
cd ml_training
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Flutter setup (Terminal 2)
cd ..
flutter pub get
```

### Daily: Start Flask (Terminal 1)
```bash
cd /path/to/KumapsApp/ml_training
source venv/bin/activate
python3 flask_api.py
```

### Daily: Start App (Terminal 2)
```bash
cd /path/to/KumapsApp
flutter run
```

### Test Flask Works
```bash
curl http://localhost:5001/health
```

### Stop Everything
```bash
# Terminal 1: Ctrl+C
# Terminal 2: Ctrl+C or type 'q'
```

### Full Reset (if something breaks)
```bash
cd /path/to/KumapsApp
rm -rf ml_training/venv build/ .dart_tool/
cd ml_training
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cd ..
flutter clean
flutter pub get
```

---

## 🪟 Windows (Command Prompt)

### First Time Setup
```bash
# Clone the repo
git clone <repo-url>
cd KumapsApp

# Flask setup (Terminal 1)
cd ml_training
python -m venv venv
venv\Scripts\activate.bat
pip install -r requirements.txt

# Flutter setup (Terminal 2)
cd ..
flutter pub get
```

### Daily: Start Flask (Terminal 1)
```bash
cd C:\path\to\KumapsApp\ml_training
venv\Scripts\activate.bat
python flask_api.py
```

### Daily: Start App (Terminal 2)
```bash
cd C:\path\to\KumapsApp
flutter run
```

### Test Flask Works
```bash
curl http://localhost:5001/health
```

### Find What's Using Port 5001
```bash
netstat -ano | findstr :5001
# Then kill it:
taskkill /PID <PID> /F
```

### Stop Everything
```bash
# Terminal 1: Ctrl+C
# Terminal 2: Ctrl+C or type 'q'
```

### Full Reset (if something breaks)
```bash
cd C:\path\to\KumapsApp
rmdir /s ml_training\venv
rmdir /s build
rmdir /s .dart_tool

cd ml_training
python -m venv venv
venv\Scripts\activate.bat
pip install -r requirements.txt

cd ..
flutter clean
flutter pub get
```

---

## 🪟 Windows (PowerShell)

### First Time Setup
```powershell
# Clone the repo
git clone <repo-url>
cd KumapsApp

# Flask setup (Terminal 1)
cd ml_training
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt

# Flutter setup (Terminal 2)
cd ..
flutter pub get
```

### Daily: Start Flask (Terminal 1)
```powershell
cd C:\path\to\KumapsApp\ml_training
.\venv\Scripts\Activate.ps1
python flask_api.py
```

### Daily: Start App (Terminal 2)
```powershell
cd C:\path\to\KumapsApp
flutter run
```

### Test Flask Works
```powershell
Invoke-WebRequest -Uri "http://localhost:5001/health"
```

### Stop Everything
```powershell
# Terminal 1: Ctrl+C
# Terminal 2: Ctrl+C or type 'q'
```

---

## 📱 Device Selection

### List Devices
```bash
flutter devices
```

### Run on Specific Device
```bash
# macOS/Linux
flutter run -d <device-id>

# Or let Flutter ask you which one
flutter run
# Choose number from list
```

### Android Emulator
```bash
# List emulators
flutter emulators

# Launch one
flutter emulators --launch Pixel_5_API_30

# Then run app
flutter run
```

### iOS Simulator (macOS only)
```bash
# Launch simulator
open -a Simulator

# Then run app
flutter run
```

### Real Phone
```bash
# Connect via USB
# Allow debugging when phone asks
flutter devices  # Should see your phone
flutter run      # Choose it from list
```

---

## 🔍 Debugging

### View Flutter Logs
```bash
flutter logs
```

### Run with Verbose Output
```bash
flutter run -v
```

### Check what's using a port
```bash
# macOS/Linux
lsof -i :5001

# Windows Command Prompt
netstat -ano | findstr :5001

# Windows PowerShell
netstat -ano | Select-String :5001
```

### Test Flask Endpoint
```bash
# Health check
curl http://localhost:5001/health

# Predict endpoint
curl -X POST http://localhost:5001/predict \
  -H "Content-Type: application/json" \
  -d "{\"landmarks\": [0,0,0,0,0]}"
```

---

## 🔄 Common Tasks

### Update Dependencies
```bash
# Python
pip install -r requirements.txt --upgrade

# Flutter
flutter pub upgrade
```

### Clean Everything
```bash
cd /path/to/KumapsApp

# Flutter
flutter clean
rm -rf build/
rm -rf .dart_tool/
rm -rf pubspec.lock
flutter pub get

# Python
cd ml_training
rm -rf venv
python3 -m venv venv
source venv/bin/activate  # or venv\Scripts\activate.bat on Windows
pip install -r requirements.txt
```

### Retrain Model
```bash
cd ml_training
python3 2_train_model.py
```

### View Project Structure
```bash
tree -L 2  # macOS/Linux (if tree installed)
dir /s    # Windows
```

---

## 📋 File Locations

| What | Where |
|------|-------|
| Flutter app | `lib/main.dart` |
| Camera code | `lib/presentation/providers/camera_provider.dart` |
| Theme/colors | `lib/theme/app_theme.dart` |
| Flask backend | `ml_training/flask_api.py` |
| ML model | `ml_training/models/gesture_model.pkl` |
| Sign mapping | `ml_training/models/sign_mapping.json` |
| Dependencies (Dart) | `pubspec.yaml` |
| Dependencies (Python) | `ml_training/requirements.txt` |

---

## 🐛 Emergency Fixes

### "Port 5001 already in use"
```bash
# macOS/Linux
lsof -i :5001
kill -9 <PID>

# Windows
netstat -ano | findstr :5001
taskkill /PID <PID> /F
```

### "Module not found" errors
```bash
cd ml_training
pip install -r requirements.txt
```

### "App won't start"
```bash
flutter clean
flutter pub get
flutter run
```

### "Flask won't start"
```bash
cd ml_training
rm -rf venv
python3 -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
python3 flask_api.py
```

---

## 📞 Need Help?

1. Check TROUBLESHOOTING.md for your specific error
2. Read SETUP_FOR_GROUPMATES.md step-by-step
3. Read NETWORK_CONFIGURATION_GUIDE.md for port/connection issues
4. Share Terminal 1 and Terminal 2 output with team lead
