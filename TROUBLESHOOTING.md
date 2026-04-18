# 🔧 TROUBLESHOOTING GUIDE

## Common Issues & Solutions

---

## 🐍 PYTHON & FLASK ISSUES

### ❌ "python3: command not found"

**Problem:** Python not installed or not in PATH

**Solution:**
1. **macOS**: 
   ```bash
   brew install python@3.10
   ```
   Then add to ~/.zshrc or ~/.bash_profile:
   ```bash
   export PATH="/usr/local/opt/python@3.10/bin:$PATH"
   ```
   Restart terminal: `source ~/.zshrc`

2. **Linux (Ubuntu/Debian)**:
   ```bash
   sudo apt update
   sudo apt install python3.10 python3.10-venv
   ```

3. **Windows**:
   - Download from https://www.python.org/downloads/
   - **IMPORTANT**: Check "Add Python to PATH" during install
   - Restart Command Prompt after install

**Verify:**
```bash
python3 --version  # Should show 3.10.x or higher
```

---

### ❌ "No module named 'flask'"

**Problem:** Flask not installed in virtual environment

**Solution:**
```bash
# Make sure venv is activated:
source venv/bin/activate  # macOS/Linux
# or
venv\Scripts\activate.bat  # Windows

# Then reinstall:
pip install -r requirements.txt
```

**Check installed packages:**
```bash
pip list | grep -i flask
```

---

### ❌ "ModuleNotFoundError: No module named 'sklearn'"

**Problem:** scikit-learn not installed

**Solution:**
```bash
# Activate venv first
source venv/bin/activate  # macOS/Linux
# or venv\Scripts\activate.bat  # Windows

# Install missing packages
pip install scikit-learn numpy pandas
```

---

### ❌ "Port 5001 in use" or "OSError: [Errno 48] Address already in use"

**Problem:** Port 5001 is occupied by another process

**Solution (macOS/Linux):**
```bash
# Find what's using port 5001
lsof -i :5001

# Kill the process
kill -9 <PID>
```

**Solution (Windows):**
```powershell
# Find what's using port 5001
netstat -ano | findstr :5001

# Kill the process (replace PID with the number you found)
taskkill /PID <PID> /F
```

**Alternative:** Use a different port
1. Edit `ml_training/flask_api.py`
2. Change this line:
   ```python
   app.run(host='0.0.0.0', port=5002, debug=False)
   ```
3. Update Flutter app to use new port (see NETWORK_CONFIGURATION_GUIDE.md)

---

### ❌ "Flask won't start" or random crash

**Problem:** Missing required packages or corrupted venv

**Solution - Full Reset:**
```bash
cd /path/to/KumapsApp/ml_training

# Remove old venv
rm -rf venv  # macOS/Linux
# or rmdir /s venv  # Windows

# Create fresh venv
python3 -m venv venv

# Activate
source venv/bin/activate  # macOS/Linux
# or venv\Scripts\activate.bat  # Windows

# Install everything fresh
pip install --upgrade pip
pip install -r requirements.txt

# Try starting Flask again
python3 flask_api.py
```

---

### ❌ "Model file not found: gesture_model.pkl"

**Problem:** Model file missing or in wrong location

**Solution:**
1. Check the file exists:
   ```bash
   ls -la ml_training/models/gesture_model.pkl  # macOS/Linux
   dir ml_training\models\gesture_model.pkl     # Windows
   ```

2. If missing, generate it:
   ```bash
   cd ml_training
   python3 2_train_model.py
   ```

3. Check it's committed to git:
   ```bash
   git status
   ```
   Should NOT show `gesture_model.pkl` as untracked.

---

### ❌ "Connection refused" or "Cannot connect to Flask"

**Problem:** Flask isn't running or listening on wrong address

**Solution:**
1. **Make sure Flask is running:**
   - Check Terminal 1 shows ` * Running on http://0.0.0.0:5001`

2. **Check Flask is actually running:**
   ```bash
   curl http://localhost:5001/health
   ```
   Should return JSON health check

3. **Check the Flask terminal for errors:**
   - Look at Terminal 1 for any red error messages
   - Share the output with team lead if confused

4. **Check firewall isn't blocking port 5001:**
   - macOS: System Preferences → Security & Privacy → Firewall
   - Windows: Control Panel → Windows Defender Firewall
   - Add Flask to allowed apps

---

### ❌ "Gesture prediction returns null or error"

**Problem:** Flask endpoint not working correctly

**Solution:**
1. **Test with curl:**
   ```bash
   curl -X POST http://localhost:5001/predict \
     -H "Content-Type: application/json" \
     -d '{"landmarks": [0.1, 0.2, 0.3, 0.4, 0.5]}'
   ```
   Should return: `{"error": "Invalid input size"}`

2. **Check Flask logs:**
   - Look at Terminal 1 for error messages

3. **Verify model was loaded:**
   - Terminal 1 should show: `✅ Model loaded`
   - If not, run: `python3 2_train_model.py`

---

## 📱 FLUTTER & APP ISSUES

### ❌ "flutter: command not found"

**Problem:** Flutter not installed or not in PATH

**Solution (macOS/Linux):**
```bash
# Install Flutter
git clone https://github.com/flutter/flutter.git
cd flutter/bin
./flutter --version

# Add to PATH in ~/.zshrc or ~/.bash_profile:
export PATH="$PATH:/path/to/flutter/bin"

# Reload:
source ~/.zshrc
```

**Solution (Windows):**
1. Download Flutter from https://flutter.dev/docs/get-started/install/windows
2. Extract to `C:\flutter`
3. Add `C:\flutter\bin` to Windows PATH
4. Restart Command Prompt

**Verify:**
```bash
flutter --version
flutter devices
```

---

### ❌ "No connected devices"

**Problem:** Emulator/simulator not running

**Solution:**

**Android Emulator (all platforms):**
```bash
# List available emulators
flutter emulators

# Launch one
flutter emulators --launch Pixel_5_API_30

# Or from Android Studio: Tools → Device Manager → Launch
```

**iOS Simulator (macOS only):**
```bash
# List simulators
xcrun simctl list devices

# Launch iPhone 15 simulator
open -a Simulator

# Or from Xcode: Xcode → Open Developer Tool → Simulator
```

**Real Phone:**
1. Connect via USB
2. Allow USB debugging (Android) or trust device (iOS)
3. Run: `flutter devices` (should see your phone)

---

### ❌ "App crashes on startup"

**Problem:** Flutter app has runtime error

**Solution:**
1. **Check Terminal 2 logs:**
   ```bash
   flutter logs
   ```

2. **Rebuild app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Check for common errors:**
   - **"Connection refused"** → Flask not running (check Terminal 1)
   - **"Camera not available"** → Check permissions (see next section)
   - **"Gesture model not found"** → Check model file exists

---

### ❌ "Camera won't work" or "Permission denied"

**Problem:** Camera permissions not granted

**Solution:**

**iOS (Real Phone):**
1. Settings → Privacy → Camera → Enable toggle for Kumpas
2. Settings → Privacy → Photos → Enable if using image library
3. Force close and reopen app

**iOS (Simulator):**
- Permissions usually pre-granted
- If not: Simulator → Settings → Privacy → Camera → Allow

**Android (Real Phone):**
1. Settings → Apps → Kumpas → Permissions
2. Toggle Camera to "Allow"
3. Force close and reopen app

**Android (Emulator):**
- Should be pre-granted
- If not: Emulator Settings → Privacy → Grant Camera permission

**In App:**
- App might ask for permission - tap **ALLOW**

---

### ❌ "App is very slow or freezes"

**Problem:** Performance issue, likely camera processing

**Solution:**
1. **Check device isn't overheating:**
   - Close other apps
   - Let device cool down

2. **Reduce camera resolution:**
   - Edit `lib/services/gesture_service.dart`
   - Change: `ResolutionPreset.high` → `ResolutionPreset.medium`

3. **Reduce frame processing:**
   - Edit `lib/presentation/providers/camera_provider.dart`
   - Reduce FPS or skip frames

4. **Run release build (faster):**
   ```bash
   flutter run --release
   ```

---

### ❌ "Hot reload not working"

**Problem:** Changes aren't reflecting in running app

**Solution:**
1. **Try full reload:**
   - In Terminal 2, press `R` (capital R for reload)

2. **Stop and restart:**
   ```bash
   # In Terminal 2, press Ctrl+C
   flutter run
   ```

3. **Full rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## 🔌 NETWORK & CONNECTION ISSUES

### ❌ "App can't reach Flask (localhost:5001)"

**Problem:** Flask running but app can't connect

**Solution:**

**Check Flask is running:**
```bash
curl http://localhost:5001/health
```

**Check port 5001 is listening (macOS/Linux):**
```bash
netstat -an | grep 5001
```

Should show: `tcp4 0 0 127.0.0.1.5001 LISTEN`

**On Real Phone (not localhost):**
1. Get your computer's IP:
   ```bash
   ifconfig | grep "inet "  # macOS/Linux
   ipconfig              # Windows
   ```
   Find the IP like `192.168.x.x`

2. Edit `lib/services/gesture_service.dart`:
   ```dart
   // Change from:
   const String flaskUrl = 'http://localhost:5001';
   
   // To:
   const String flaskUrl = 'http://192.168.x.x:5001';
   ```

3. Rebuild and run

---

### ❌ "Connection reset by peer" or "Socket timeout"

**Problem:** Network connection unstable or Flask crashed

**Solution:**
1. **Check Flask is still running:**
   - Look at Terminal 1
   - Should still show server running

2. **If Flask crashed:**
   - Terminal 1 will show error
   - Restart: `python3 flask_api.py`

3. **Check your internet:**
   ```bash
   ping 8.8.8.8  # Should get responses
   ```

4. **Restart both services:**
   - Kill Flask (Ctrl+C in Terminal 1)
   - Kill app (Ctrl+C in Terminal 2)
   - Start Flask again
   - Start app again

---

## 🎯 GESTURE RECOGNITION ISSUES

### ❌ "Gesture not recognized" or "Always predicts same gesture"

**Problem:** Model accuracy low or hand not properly detected

**Solution:**
1. **Check hand is visible to camera:**
   - Hand should be clearly in frame
   - Good lighting helps

2. **Make gesture clearly:**
   - Hold for 1-2 seconds
   - Don't move too fast

3. **Train a new model:**
   ```bash
   cd ml_training
   python3 2_train_model.py
   ```

4. **Check gesture landmarks:**
   - Enable debug mode to see hand skeleton
   - Should show ~21 joints clearly

---

### ❌ "Accuracy very low" or "Predicts wrong gestures"

**Problem:** Model not trained well or needs more data

**Solution:**
1. **Collect more training data:**
   ```bash
   cd ml_training
   python3 1_extract_landmarks.py
   ```

2. **Train new model with more data:**
   ```bash
   python3 2_train_model.py
   ```

3. **Check training logs for errors:**
   - Terminal output should show accuracy metrics

---

## 💾 GIT & VERSION CONTROL ISSUES

### ❌ "Model file (.gitignore) not in repo"

**Problem:** Model file excluded from git

**Check:**
```bash
git status ml_training/models/gesture_model.pkl
```

**If not tracked:**
1. Edit `.gitignore` - remove gesture_model.pkl from exclusions
2. Then:
   ```bash
   git add ml_training/models/gesture_model.pkl
   git commit -m "Add gesture recognition model"
   git push
   ```

### ❌ "requirements.txt not being used"

**Problem:** Mismatch between requirements and installed packages

**Solution:**
```bash
# Reinstall from requirements exactly:
pip install --force-reinstall -r requirements.txt

# Or verify current environment matches:
pip freeze > requirements_current.txt
diff requirements.txt requirements_current.txt
```

---

## 📊 DEBUGGING CHECKLIST

Before asking for help:

- [ ] Followed SETUP_FOR_GROUPMATES.md exactly?
- [ ] Flask running in Terminal 1 (not crashed)?
- [ ] App running in Terminal 2?
- [ ] Device permissions granted?
- [ ] All required files exist? (`gesture_model.pkl`, `requirements.txt`, etc.)
- [ ] Python 3.10+? (Check: `python3 --version`)
- [ ] Flutter latest? (Check: `flutter upgrade`)
- [ ] `pip install -r requirements.txt` run successfully?
- [ ] `flutter pub get` run successfully?

---

## 🆘 IF STILL STUCK

1. **Get Terminal outputs:**
   - Copy everything from Terminal 1 (Flask)
   - Copy everything from Terminal 2 (Flutter)
   - Share with team lead

2. **Check logs:**
   ```bash
   # Flutter logs
   flutter logs
   
   # Or run with verbose output:
   flutter run -v
   ```

3. **Try complete reset:**
   ```bash
   cd /path/to/KumapsApp
   
   # Reset Flutter
   flutter clean
   rm -rf build/
   rm -rf .dart_tool/
   
   # Reset Flask
   cd ml_training
   rm -rf venv
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

---

**Still stuck?** Check QUICK_REFERENCE.md for your OS, or read NETWORK_CONFIGURATION_GUIDE.md for detailed Flask setup.
