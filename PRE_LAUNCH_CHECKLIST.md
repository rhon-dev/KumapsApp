# ✅ PRE-LAUNCH CHECKLIST

Use this checklist before considering the project "production-ready" and before final pushes to GitHub.

---

## 📋 CODE & FILES

### Model Files
- [ ] `ml_training/models/gesture_model.pkl` exists and is NOT git-ignored
- [ ] `ml_training/models/sign_mapping.json` exists and is NOT git-ignored
- [ ] Model file size is reasonable (~1-50MB, not huge or empty)
- [ ] Verify model works: `python3 ml_training/2_train_model.py` completes successfully

### Configuration Files
- [ ] `pubspec.yaml` exists and lists all Flutter dependencies
- [ ] `pubspec.lock` exists (should be committed)
- [ ] `ml_training/requirements.txt` exists with all Python packages
- [ ] `.gitignore` properly excludes build/cache/venv but includes code
- [ ] No `.env` files or files with secrets in repo (use `.env.example` instead)
- [ ] No hardcoded paths (use relative paths: `./` or `../`)
- [ ] No hardcoded IP addresses (except localhost:5001)

### Documentation
- [ ] `README.md` updated with Hand Gesture Recognition section
- [ ] `SETUP_FOR_GROUPMATES.md` complete and tested
- [ ] `QUICK_REFERENCE.md` has commands for all three OS
- [ ] `TROUBLESHOOTING.md` covers common issues
- [ ] `NETWORK_CONFIGURATION_GUIDE.md` explains port setup
- [ ] `FILE_STRUCTURE.md` explains repo layout
- [ ] All docs are accurate and tested

---

## 🔑 SECURITY & SECRETS

- [ ] No private API keys in code
- [ ] No hardcoded passwords
- [ ] No personal information in comments
- [ ] No credentials in .env files (these are .gitignored, which is good)
- [ ] Flask running on localhost (safe for local dev)
- [ ] No database passwords visible
- [ ] `.gitignore` prevents accidental secrets upload

---

## 🌐 NETWORK & PORTS

- [ ] Flask runs on port 5001 (documented in NETWORK_CONFIGURATION_GUIDE.md)
- [ ] Flask allows connections from phone on same WiFi (`host='0.0.0.0'`)
- [ ] Health endpoint (`/health`) responds with JSON
- [ ] Predict endpoint (`/predict`) works with test data
- [ ] CORS enabled in Flask (Flask-CORS in requirements.txt)
- [ ] No firewall blocks port 5001 (documented in TROUBLESHOOTING.md)

### Test Commands
```bash
# Terminal verify Flask runs
python3 flask_api.py

# Terminal 2 - test health endpoint
curl http://localhost:5001/health

# Terminal 3 - test predict
curl -X POST http://localhost:5001/predict \
  -H "Content-Type: application/json" \
  -d '{"landmarks": [0.1, 0.2, ...]}'
```

---

## 🔨 BUILD & DEPENDENCIES

### Python Setup
- [ ] `python3 --version` shows 3.10 or higher (NOT 3.14 - too new)
- [ ] Virtual environment created successfully
- [ ] `pip install -r requirements.txt` completes without errors
- [ ] All packages in requirements.txt are cross-platform compatible
- [ ] No platform-specific dependencies (or platform-specific fallbacks exist)

### Flutter Setup
- [ ] `flutter --version` shows 3.10.0 or higher
- [ ] `flutter pub get` completes without errors
- [ ] `flutter devices` shows at least one device available
- [ ] `flutter run` builds and runs successfully
- [ ] No deprecated API usage in code

### Verify Clean Build
```bash
# Python
cd ml_training
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 flask_api.py
# Should start without errors

# Flutter
cd ..
flutter clean
flutter pub get
flutter run
# Should build and run
```

---

## 📱 APP FUNCTIONALITY

- [ ] App starts without crashing
- [ ] Camera permission request works
- [ ] Camera feed displays
- [ ] Hand skeleton overlay shows
- [ ] Gesture prediction returns results
- [ ] Confidence percentage displays
- [ ] Bottom navigation works (5 tabs)
- [ ] All screens navigate correctly
- [ ] App handles phone rotation
- [ ] No crashes on real phone (Android & iOS tested if possible)

---

## 📝 DOCUMENTATION QUALITY

- [ ] No typos in setup guides
- [ ] All code examples are copy-paste ready
- [ ] Step numbers are clear and sequential
- [ ] OS-specific instructions clearly marked (Windows/Mac/Linux)
- [ ] "What You Should See" sections are accurate
- [ ] Links between docs are correct
- [ ] Commands are tested and working
- [ ] Troubleshooting covers 90% of common issues

### Checklist in Docs
- [ ] SETUP_FOR_GROUPMATES.md says "⚠️ DO THIS FIRST"
- [ ] Terminal 1 vs Terminal 2 clearly labeled
- [ ] What each command does is explained
- [ ] Error messages are explained in TROUBLESHOOTING.md

---

## 🔄 GIT & VERSION CONTROL

### Repository Setup
- [ ] `.gitignore` is comprehensive and tested
- [ ] Model files (gesture_model.pkl) are tracked, NOT ignored
- [ ] `pubspec.lock` is tracked (flutter uses exact versions)
- [ ] Build/ and .dart_tool/ are ignored
- [ ] venv/ and __pycache__/ are ignored
- [ ] No large binary files (>100MB) accidentally committed

### Commits & History
- [ ] Commit history is clean (no sensitive data)
- [ ] No "WIP" or temp commits in main branch
- [ ] All important files have meaningful commit messages
- [ ] No merge conflicts remain in tracked files

### Test Git Clone
```bash
# On a different folder/computer
git clone <repo-url> test_clone
cd test_clone

# Verify essential files exist
ls -la ml_training/models/gesture_model.pkl
cat pubspec.yaml
cat ml_training/requirements.txt

# Try setup steps from SETUP_FOR_GROUPMATES.md
cd ml_training
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 flask_api.py
# Should work!
```

---

## 👥 USER TESTING

- [ ] A new team member followed SETUP_FOR_GROUPMATES.md successfully
- [ ] They could get Flask running in Terminal 1
- [ ] They could get Flutter app running in Terminal 2
- [ ] Gesture recognition worked on their phone
- [ ] They encountered no blockers

### Feedback Questions
- [ ] Was setup easy to follow?
- [ ] Were any steps confusing?
- [ ] Did they need to ask questions?
- [ ] Any errors they hit that weren't in TROUBLESHOOTING.md?

---

## 🚀 PLATFORM COMPATIBILITY

### Windows
- [ ] Tested on Windows 10/11 (Command Prompt & PowerShell)
- [ ] Activation script works: `venv\Scripts\activate.bat`
- [ ] Python installed with "Add to PATH" checked
- [ ] Flutter commands work in terminal

### macOS
- [ ] Tested on Intel Mac
- [ ] Tested on Apple Silicon (M1/M2/M3) if possible
- [ ] Activation script works: `source venv/bin/activate`
- [ ] `python3` and `pip3` commands work (or aliased to `python`/`pip`)

### Linux
- [ ] Tested on Ubuntu/Debian (if possible)
- [ ] Python 3.10+ available via package manager
- [ ] Activation script works: `source venv/bin/activate`
- [ ] No sudo needed for pip packages

### Mobile Platforms
- [ ] iOS simulator/device tested (if macOS available)
- [ ] Android emulator/device tested
- [ ] Camera permissions working on both
- [ ] Gesture recognition functional on both

---

## 📊 PERFORMANCE

- [ ] Flask server starts in <5 seconds
- [ ] /health endpoint responds in <100ms
- [ ] /predict endpoint responds in <1 second
- [ ] Flutter app starts in <10 seconds
- [ ] Camera preview smooth (no lag)
- [ ] No memory leaks on long-running app

---

## 🐛 ERROR HANDLING

- [ ] Flask handles bad input gracefully (returns error JSON)
- [ ] Flutter handles network failures
- [ ] Camera permission denial handled
- [ ] Model loading errors logged clearly
- [ ] Missing model file error is helpful

### Test Error Cases
```bash
# Test 1: Flask without model
# Remove gesture_model.pkl, start Flask
# Should show clear error message

# Test 2: Port in use
# Kill Flask, start on same port twice
# Should fail with clear error

# Test 3: Bad API input
curl -X POST http://localhost:5001/predict \
  -H "Content-Type: application/json" \
  -d '{"bad": "data"}'
# Should return error, not crash
```

---

## ✨ FINAL REVIEW

### Code Quality
- [ ] No obvious bugs in code reviews
- [ ] Naming conventions consistent
- [ ] Comments explain "why", not "what"
- [ ] No commented-out code blocks left

### Performance
- [ ] Model file not too large
- [ ] API responses fast enough
- [ ] No CPU spinning/hanging

### Accessibility
- [ ] Camera UI is easy to understand
- [ ] Results clearly displayed
- [ ] Error messages are helpful

---

## 🎯 LAUNCH READINESS

- [ ] Everything above is checked ✅
- [ ] At least 2 team members tested setup successfully
- [ ] No known show-stopping bugs
- [ ] Documentation is complete & accurate
- [ ] Ready to share with group!

---

## 📞 SIGN-OFF

**Project Lead Review:**
- [ ] I've verified the above checklist
- [ ] This project is production-ready for group collaboration
- [ ] Team members can clone and use immediately

**Date Approved:** ___________

**Approved By:** ___________

---

**Questions?** If something fails:
1. Check TROUBLESHOOTING.md
2. Review the specific section of SETUP_FOR_GROUPMATES.md
3. Ask the team lead
