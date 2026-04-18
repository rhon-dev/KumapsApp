# 📁 FILE STRUCTURE GUIDE

This document explains what each file and folder does.

---

## 📂 Project Root

```
KumapsApp/
├── README.md                          ← Main project overview
├── SETUP_FOR_GROUPMATES.md            ← START HERE: Step-by-step setup
├── QUICK_REFERENCE.md                 ← Copy-paste commands
├── TROUBLESHOOTING.md                 ← Common issues & fixes
├── NETWORK_CONFIGURATION_GUIDE.md     ← Flask port setup
├── FILE_STRUCTURE.md                  ← YOU ARE HERE
├── GESTURE_RECOGNITION_COMPLETE_GUIDE.md  ← Detailed gesture guide
├── DEVELOPMENT.md                     ← For developers
├── IMPLEMENTATION_SUMMARY.md          ← Technical summary
├── QUICK_START.md                     ← Quick start (legacy)
├── SETUP.md                           ← Setup info (legacy)
├── pubspec.yaml                       ← Flutter dependencies
├── pubspec.lock                       ← Flutter locked versions (commit this)
├── analysis_options.yaml              ← Dart linter config
├── .gitignore                         ← What to NOT commit to git
├── .metadata                          ← Flutter metadata (auto-generated)
├── devtools_options.yaml              ← DevTools config
└── [other auto-generated files]
```

---

## 📱 Flutter Frontend (`lib/`)

This is all the mobile app code.

```
lib/
├── main.dart                           ← App entry point
│                                       ← Starts the app
│
├── theme/
│   └── app_theme.dart                 ← Colors, fonts, styling
│                                       ← Accessibility settings
│
├── models/
│   └── learning_models.dart           ← Data structures
│                                       ← User progress, gestures, etc.
│
├── presentation/
│   ├── providers/
│   │   ├── app_state_provider.dart    ← Global app state
│   │   │                              ← Navigation, camera mode
│   │   └── camera_provider.dart       ← Camera control
│   │                                  ← Hand detection
│   │                                  ← Flask API communication
│   │
│   ├── screens/
│   │   ├── main_app_shell.dart        ← Bottom navigation shell
│   │   │                              ← Contains all 5 tabs
│   │   ├── home_screen.dart           ← Dashboard
│   │   ├── learn_screen.dart          ← Learn & practice
│   │   ├── translate_screen.dart      ← Gesture recognition (main)
│   │   ├── dictionary_screen.dart     ← Browse signs
│   │   └── profile_screen.dart        ← User profile
│   │
│   └── widgets/
│       └── camera_feedback_overlay.dart  ← Camera UI overlay
│                                         ← Shows hand skeleton
│                                         ← Shows recognition results
│
└── services/
    ├── gesture_service.dart           ← Calls Flask /predict endpoint
    │                                  ← Sends hand landmarks
    └── landmark_extractor.dart        ← Extracts hand landmarks from camera
                                        ← Formats for Flask API
```

### Key Files to Edit

- **To change colors:** `lib/theme/app_theme.dart`
- **To modify camera:** `lib/presentation/providers/camera_provider.dart`
- **To change UI layout:** `lib/presentation/screens/translate_screen.dart`
- **To add gesture logic:** `lib/services/gesture_service.dart`

---

## 🐍 Python Backend (`ml_training/`)

This is all the ML and Flask code.

```
ml_training/
├── flask_api.py                       ← Flask web server
│                                       ← Runs on port 5001
│                                       ← Provides /predict endpoint
│
├── 1_extract_landmarks.py             ← Extract hand landmarks from video
│                                       ← Prepares data for training
│
├── 2_train_model.py                   ← Train gesture recognition model
│                                       ← Creates gesture_model.pkl
│
├── requirements.txt                   ← Python package list
│                                       ← pip install -r requirements.txt
│
├── models/
│   ├── gesture_model.pkl              ← ⭐ TRAINED ML MODEL
│   │                                  ← sklearn RandomForest
│   │                                  ← Predicts hand gestures
│   │
│   └── sign_mapping.json              ← ⭐ GESTURE NAMES
│                                       ← Maps numbers to gesture names
│                                       ← ["HELLO", "YES", "ONE", ...]
│
├── extracted_landmarks/
│   └── landmarks_data.json            ← Training data
│                                       ← Hand joint positions
│                                       ← Used by 2_train_model.py
│
├── venv/                              ← Virtual environment
│                                       ← NOT committed to git
│                                       ← Created with: python3 -m venv venv
│
└── README.md                          ← Python setup info
```

### Key Files to Edit

- **To train new model:** `ml_training/2_train_model.py`
- **To add Python packages:** `ml_training/requirements.txt`
- **To change Flask settings:** `ml_training/flask_api.py`
- **To change gesture names:** `ml_training/models/sign_mapping.json`

---

## 📱 Platform-Specific Code

### Android

```
android/
├── app/
│   └── src/
│       └── main/
│           ├── AndroidManifest.xml        ← Permissions
│           │                              ← Camera, Internet
│           └── res/
│
├── build.gradle                           ← Build settings
├── local.properties                       ← Local SDK paths
│                                          ← NOT committed to git
└── .gradle/                               ← Build cache
                                            ← NOT committed to git
```

### iOS / macOS

```
ios/                                       ← iOS app code
├── Runner/
│   ├── Info.plist                        ← Permissions
│   └── Assets.xcassets/
│
├── Podfile                               ← CocoaPods dependencies
└── Pods/                                 ← Dependency libraries
                                          ← NOT committed to git

macos/                                    ← macOS app code
├── Runner/
│   ├── Info.plist                        ← Permissions
│   └── Assets.xcassets/
│
├── Podfile                               ← CocoaPods dependencies
└── Pods/                                 ← Dependency libraries
                                          ← NOT committed to git
```

---

## 🔨 Build Artifacts (NOT committed to git)

These are created when you build/run the app:

```
build/                                   ← Build outputs
├── app/
│   └── outputs/flutter-apk/             ← Android APK file
│
├── ios/                                 ← iOS build
└── ...

.dart_tool/                              ← Dart analysis cache
.flutter-plugins-dependencies            ← Plugin metadata
.pub-cache/                              ← Downloaded packages
```

---

## 📚 Documentation Files

```
README.md                                ← Main documentation
SETUP_FOR_GROUPMATES.md                  ← Setup instructions
QUICK_REFERENCE.md                       ← Copy-paste commands
TROUBLESHOOTING.md                       ← Common issues
NETWORK_CONFIGURATION_GUIDE.md           ← Flask & networking
FILE_STRUCTURE.md                        ← This file
GESTURE_RECOGNITION_COMPLETE_GUIDE.md    ← Detailed gesture guide
DEVELOPMENT.md                           ← Developer notes
IMPLEMENTATION_SUMMARY.md                ← Technical summary
QUICK_START.md                           ← Quick start (legacy)
SETUP.md                                 ← Setup info (legacy)
```

---

## 📊 Data Flow

```
                          USER MAKES GESTURE
                                  ↓
                        Camera captures frame
                                  ↓
        ┌───────────────── lib/services/landmark_extractor.dart
        │                 Extracts 21 hand joints (MediaPipe)
        │                 Returns 63 landmark values (21 joints × 3 coords)
        │
        ├───────────────── lib/services/gesture_service.dart
        │                 Sends to Flask API:
        │                 POST http://localhost:5001/predict
        │                 Body: {"landmarks": [63 values]}
        │
        └────────────────→ ml_training/flask_api.py
                          Loads model from gesture_model.pkl
                          Predicts gesture + confidence
                          Returns: {"sign": "HELLO", "confidence": 0.95}
                                  ↓
                          lib/presentation/providers/camera_provider.dart
                          Updates UI with prediction
                                  ↓
                          lib/presentation/widgets/camera_feedback_overlay.dart
                          Shows on screen:
                          - Hand skeleton visualization
                          - Recognized gesture name
                          - Confidence percentage
```

---

## 🎯 Important Files for Different Tasks

### I want to...

**Change app appearance (colors, fonts)**
→ Edit: `lib/theme/app_theme.dart`

**Improve gesture recognition accuracy**
→ Edit: `ml_training/2_train_model.py`

**Add a new gesture**
→ 1. Add to `ml_training/models/sign_mapping.json`
→ 2. Train model: `python3 ml_training/2_train_model.py`

**Modify camera behavior**
→ Edit: `lib/presentation/providers/camera_provider.dart`

**Add a new screen/tab**
→ Create: `lib/presentation/screens/my_screen.dart`
→ Edit: `lib/presentation/screens/main_app_shell.dart`

**Fix gesture prediction errors**
→ Check: `ml_training/flask_api.py` logs

**Add Python dependency**
→ 1. Edit: `ml_training/requirements.txt`
→ 2. Run: `pip install -r requirements.txt`

**Add Flutter dependency**
→ 1. Edit: `pubspec.yaml`
→ 2. Run: `flutter pub get`

**Setup on new machine**
→ Follow: `SETUP_FOR_GROUPMATES.md`

**When something breaks**
→ Check: `TROUBLESHOOTING.md`

**Need exact commands**
→ Check: `QUICK_REFERENCE.md`

---

## 🔑 Key Files That MUST Be Committed to Git

✅ These files are ESSENTIAL and must be in the repository:

- `pubspec.yaml` - Flutter dependencies specification
- `pubspec.lock` - Exact versions of Flutter packages
- `ml_training/requirements.txt` - Python packages specification
- `ml_training/models/gesture_model.pkl` - Trained ML model ⭐
- `ml_training/models/sign_mapping.json` - Gesture names mapping ⭐
- All `.md` files (documentation)
- All `.dart` files (Flutter code)
- All `.py` files (Python code)
- `.gitignore` - Git configuration

❌ These files should NOT be committed:

- `.dart_tool/` - Generated cache
- `build/` - Build artifacts
- `ml_training/venv/` - Virtual environment
- `.env` or `.env.local` - Secrets/credentials
- `*.log` - Log files
- `.DS_Store` - macOS files
- `__pycache__/` - Python cache

---

## 🚀 Quick Navigate

To quickly find something:

1. **Mobile UI** → Look in `lib/presentation/`
2. **Camera/Gesture** → Look in `lib/services/` and `lib/presentation/providers/`
3. **Flask/ML** → Look in `ml_training/`
4. **Colors/Theme** → Look in `lib/theme/`
5. **Data Models** → Look in `lib/models/`
6. **Documentation** → Look in repo root (`*.md` files)

---

**Questions?** Check the relevant `.md` file or ask the team lead!
