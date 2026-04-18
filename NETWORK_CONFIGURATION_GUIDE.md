# 🔌 NETWORK CONFIGURATION GUIDE

Complete guide to understanding and troubleshooting Flask network setup.

---

## 🌐 What is localhost:5001?

### Localhost
- `localhost` = your current computer
- Also called `127.0.0.1` (IP address)
- Only works on the same computer

### Port 5001
- Port = communication channel
- Flask server listens on port 5001
- Like a specific door: `localhost:5001`

### Full Address
```
http://localhost:5001/predict
│     │         │     │
│     │         │     └─ Endpoint (what to do)
│     │         └──────── Port (communication channel)
│     └────────────────── Host (your computer)
└────────────────────── Protocol (web connection)
```

---

## ✅ Verify Flask is Running

### Step 1: Check Port is Listening

**macOS / Linux:**
```bash
lsof -i :5001
```

Expected output:
```
COMMAND   PID  USER   FD  TYPE            DEVICE  SIZE/OFF NODE NAME
python3 12345 user   XX  IPv6 0x1234567890abcdef   0t0  TCP *:5001 (LISTEN)
```

**Windows (Command Prompt):**
```bash
netstat -ano | findstr :5001
```

Expected output:
```
TCP  0.0.0.0:5001  0.0.0.0:0  LISTENING  12345
```

### Step 2: Test Health Endpoint

**macOS / Linux / Windows (with curl):**
```bash
curl http://localhost:5001/health
```

Expected response:
```json
{
  "status": "ok",
  "model": "gesture_recognition",
  "signs": ["HELLO", "HOW ARE YOU", "YES", "ONE", "TEN"],
  "timestamp": "2026-04-18T10:30:45.123456"
}
```

**Windows (without curl, using PowerShell):**
```powershell
Invoke-WebRequest -Uri "http://localhost:5001/health"
```

### Step 3: Check Flask Terminal Output

Terminal 1 should show:
```
✅ Model loaded: models/gesture_model.pkl
✅ Signs: ['HELLO', 'HOW ARE YOU', 'YES', 'ONE', 'TEN']
🚀 Gesture Recognition Flask API
 * Running on http://0.0.0.0:5001
 * Press CTRL+C to quit
```

---

## 🔧 Flask Configuration

### Current Setup (Default)

In `ml_training/flask_api.py`:
```python
app.run(host='0.0.0.0', port=5001, debug=False)
```

| Setting | Meaning |
|---------|---------|
| `host='0.0.0.0'` | Listen on all network interfaces |
| `port=5001` | Listen on port 5001 |
| `debug=False` | Production mode (not auto-reload) |

### Access from Different Locations

| Location | URL | How to Connect |
|----------|-----|----------------|
| Same computer | `http://localhost:5001` | Default ✅ |
| Different computer (same network) | `http://192.168.x.x:5001` | See below |
| Different computer (internet) | `http://your-ip.com:5001` | See below |
| Real phone on WiFi | `http://192.168.x.x:5001` | See below |

---

## 📱 Connecting From Real Phone (on same WiFi)

### Step 1: Get Your Computer's IP Address

**macOS / Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Look for: `inet 192.168.x.x` or `inet 10.x.x.x`

**Windows:**
```bash
ipconfig
```

Look for: `IPv4 Address: 192.168.x.x`

Example output:
```
IPv4 Address . . . . . . . . . . . : 192.168.1.100
```

### Step 2: Check Phone Can Reach Computer

From your phone on WiFi:
1. Open web browser
2. Go to: `http://192.168.1.100:5001/health`
3. Should see JSON response

### Step 3: Update Flutter App

Edit `lib/services/gesture_service.dart`:

```dart
// BEFORE (localhost - only works on same computer):
const String flaskUrl = 'http://localhost:5001';

// AFTER (your computer's IP - works from phone):
const String flaskUrl = 'http://192.168.1.100:5001';
```

### Step 4: Rebuild and Run

```bash
flutter clean
flutter pub get
flutter run
```

---

## 🔌 Port 5001 Configuration

### Why Port 5001?

- Port 80 (HTTP) & 443 (HTTPS): Already in use by other services
- Port 5000: Often conflicts with other Flask instances
- **Port 5001: Good choice, less likely to conflict**

### Change Port (if 5001 is in use)

**Step 1: Edit Flask config:**

Edit `ml_training/flask_api.py`:
```python
# Change this line:
app.run(host='0.0.0.0', port=5001, debug=False)

# To this (example with port 5002):
app.run(host='0.0.0.0', port=5002, debug=False)
```

**Step 2: Update Flutter app:**

Edit `lib/services/gesture_service.dart`:
```dart
// Change from:
const String flaskUrl = 'http://localhost:5001';

// To:
const String flaskUrl = 'http://localhost:5002';
```

**Step 3: Restart everything**
```bash
# Terminal 1: Stop Flask (Ctrl+C), then start again
python3 flask_api.py

# Terminal 2: Clean and run
flutter clean
flutter pub get
flutter run
```

---

## 📊 Network Troubleshooting

### Problem: "Connection refused"

**Diagnosis:**
```bash
curl http://localhost:5001/health
# Error: Failed to connect to localhost port 5001
```

**Solutions:**
1. **Flask not running:**
   - Check Terminal 1
   - Start Flask: `python3 flask_api.py`

2. **Port in use by another process:**
   ```bash
   # Find what's using it
   lsof -i :5001  # macOS/Linux
   netstat -ano | findstr :5001  # Windows
   
   # Kill the process
   kill -9 <PID>  # macOS/Linux
   taskkill /PID <PID> /F  # Windows
   
   # Restart Flask
   python3 flask_api.py
   ```

3. **Firewall blocking the port:**
   - macOS: System Preferences → Security & Privacy → Firewall → Firewall Options
   - Windows: Control Panel → Windows Defender Firewall → Allow an app through firewall
   - Add Python/Flask to allowed apps

### Problem: "Phone can't reach Flask"

**Diagnosis:**
1. Phone on WiFi: `192.168.1.50`
2. Computer on WiFi: `192.168.1.100`
3. From phone, visit: `http://192.168.1.100:5001/health`
4. **Error: Can't reach**

**Solutions:**
1. **Check computer's firewall:**
   - Is Flask allowed through?
   - Add Flask to firewall whitelist

2. **Check Flask is listening on all interfaces:**
   ```python
   # Should be:
   app.run(host='0.0.0.0', port=5001)
   
   # NOT:
   app.run(host='127.0.0.1', port=5001)  # This only works on same computer
   ```

3. **Check phone and computer are on same network:**
   - Both connected to same WiFi?
   - Computer not on VPN?

4. **Test from phone's browser first:**
   - Open: `http://192.168.1.100:5001/health`
   - Should see JSON response
   - If not, Flask isn't reachable

### Problem: "Timeout" or "Slow responses"

**Diagnosis:**
- App waits 30+ seconds before error
- Or response takes very long

**Solutions:**
1. **Network latency:**
   - Test ping: `ping 192.168.1.100`
   - If very high (>1000ms), network is slow

2. **Flask is hanging:**
   - Check Terminal 1 for errors
   - Model might be stuck processing

3. **Too many requests:**
   - Close other apps using network
   - Reduce request frequency

---

## 🧪 Test Flask API Endpoints

### Health Check
```bash
curl http://localhost:5001/health
```

Response:
```json
{
  "status": "ok",
  "model": "gesture_recognition",
  "signs": ["HELLO", "HOW ARE YOU", "YES", "ONE", "TEN"],
  "timestamp": "2026-04-18T10:30:45.123456"
}
```

### Predict Gesture
```bash
curl -X POST http://localhost:5001/predict \
  -H "Content-Type: application/json" \
  -d '{"landmarks": [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 4.0, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 5.0, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 6.0, 6.1, 6.2]}'
```

Response:
```json
{
  "sign": "HELLO",
  "label": 0,
  "confidence": 0.92,
  "probabilities": {
    "HELLO": 0.92,
    "HOW ARE YOU": 0.05,
    "YES": 0.02,
    "ONE": 0.01,
    "TEN": 0.00
  }
}
```

---

## 🔐 Security Notes

### Localhost (Same Computer)
- ✅ Safe - only you can access
- ✅ Used for development

### Local Network (192.168.x.x)
- ⚠️ Anyone on WiFi can access
- Good for testing with team
- Not for sensitive data

### Internet (Public IP)
- ❌ Not recommended without authentication
- Anyone on internet can access
- Should use HTTPS and auth tokens
- Out of scope for this app

### Current Setup is Safe for:
- Local development
- WiFi testing with teammates
- Phone connected to same WiFi

---

## 📋 Network Checklist

Before asking for help:

- [ ] Flask running? (Check Terminal 1)
- [ ] Port 5001 not in use? (`lsof -i :5001`)
- [ ] Health check works? (`curl http://localhost:5001/health`)
- [ ] Phone on same WiFi?
- [ ] Got computer's IP? (`ifconfig | grep inet`)
- [ ] Flutter app updated with correct IP?
- [ ] Firewall allows Flask?
- [ ] No VPN on computer?
- [ ] Python 3.10+ installed?
- [ ] requirements.txt installed? (`pip install -r requirements.txt`)

---

## 🚀 Quick Start (Network Ready)

```bash
# Terminal 1 - Start Flask
cd ml_training
source venv/bin/activate  # or venv\Scripts\activate.bat
python3 flask_api.py

# Verify (in Terminal 3)
curl http://localhost:5001/health

# Terminal 2 - Start Flutter
cd ..
flutter run

# On real phone:
# Connect to same WiFi
# Edit lib/services/gesture_service.dart with computer's IP
# flutter run
```

---

**Still having network issues?** Check TROUBLESHOOTING.md or ask the team lead!
