# Android Device Testing - Setup Guide

## Problem
Android phones can't connect to `127.0.0.1:8000` - that's your **phone's localhost**, not your PC.

## Solution
Tell the app your **PC's IP address** when you build it for physical device testing.

---

## Quick Start (For Your Device)

### Step 1: Find Your PC's IP Address
```powershell
ipconfig
```
Look for **IPv4 Address** under your WiFi adapter (e.g., `192.168.1.100`)

### Step 2: Make Sure Backend is Running
```bash
cd gaia-backend
uvicorn app.main:app --reload
```

### Step 3: Build & Run for Physical Device
```bash
cd gaia-frontend/gaia
flutter clean
flutter pub get
flutter run --dart-define=API_BASE_URL=http://YOUR_IP:8000
```

**Replace `YOUR_IP` with your actual IPv4 address** (e.g., `192.168.1.100`)

---

## For Your Teammates

Each developer should use **their own PC's IP**:

```bash
# On their machine, they run:
flutter run --dart-define=API_BASE_URL=http://THEIR_IP:8000
```

**No shared configs, no IP leaks in the code.**

---

## For Web/Website Testing

No changes needed! Just run normally:
```bash
flutter run -d chrome
```
It automatically uses `http://localhost:8000`

---

## Troubleshooting

**"Can't reach server" error?**

1. ✅ Is backend running? (`netstat -ano | findstr :8000`)
2. ✅ Are phone and PC on same WiFi?
3. ✅ Did you rebuild? (`flutter clean` before running)
4. ✅ Windows Firewall blocking port 8000? Allow it through firewall

**Test connectivity from phone:**
- Enable Developer Mode on Android
- Open terminal and `ping YOUR_IP`
