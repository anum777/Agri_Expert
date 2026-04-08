# ESP32 + NPK Sensor + RS-485 Complete Wiring & Testing Guide

## 1. HARDWARE WIRING DIAGRAM

### ESP32 to RS-485 Module Connection
```
ESP32 Pin          RS-485 Module Pin
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GPIO17 (TX2)   →   DI (Data In)
GPIO16 (RX2)   →   RO (Data Out)
GPIO5  (DE)    →   DE (Driver Enable)
GPIO4  (RE)    →   RE (Receiver Enable)
GND            →   GND
3.3V           →   VCC (if 3.3V logic)
or
5V             →   VCC (if 5V logic)
```

### RS-485 Module to NPK Sensor Connection
```
RS-485 A+ (Twisted Pair)  →  NPK Sensor A (Data+)
RS-485 B- (Twisted Pair)  →  NPK Sensor B (Data-)
RS-485 GND               →  NPK Sensor GND
```

### Complete SPI Connections
```
NPK Sensor
    ↓ (Modbus RS-485)
RS-485 Module
    ↓ (UART Serial)
ESP32
    ↓ (WiFi + HTTP)
FastAPI Backend
    ↓ (HTTP + JSON)
Flutter Mobile App
```

---

## 2. PIN CONFIGURATION IN CODE

In `esp32_npk_sensor.ino`:

```cpp
// Modbus RS-485 pins
#define RX_PIN 16    // UART2 RX (ESP32)
#define TX_PIN 17    // UART2 TX (ESP32)
#define RE_PIN 4     // Receiver Enable (Receive mode when LOW)
#define DE_PIN 5     // Driver Enable (Transmit mode when HIGH)

// Serial2 initialization
Serial2.begin(9600, SERIAL_8N1, RX_PIN, TX_PIN);
```

---

## 3. NPK SENSOR MODBUS SLAVE ADDRESS & REGISTERS

```
Modbus Slave Address: 0x01 (Default, check sensor manual)

Holding Registers:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Register    Value       Description       Scale
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
0x001A      0-1400      Nitrogen (N)      ÷ 10
0x001B      0-1400      Phosphorus (P)    ÷ 10
0x001C      0-1400      Potassium (K)     ÷ 10
0x001D      0-1000      Temperature       ÷ 10
0x001E      0-1000      Humidity          ÷ 10
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Example: If sensor returns 500 for N (register 0x001A)
         Actual Nitrogen = 500 ÷ 10 = 50 mg/kg
```

---

## 4. STEP-BY-STEP SETUP

### Phase 1: Hardware Assembly
1. ✓ Connect ESP32 to RS-485 module (TX2, RX2, DE, RE, GND, 3.3V/5V)
2. ✓ Connect RS-485 module to NPK sensor (A+, B-, GND)
3. ✓ Power ESP32 via USB or battery
4. ✓ Verify all connections with multimeter

### Phase 2: Arduino Code Upload
1. Install Arduino IDE
2. Add ESP32 board: `esp32 by Espressif Systems`
3. Install library: `ArduinoJson`
4. Open `esp32_npk_sensor.ino`
5. Update WiFi credentials:
   ```cpp
   const char* ssid = "YOUR_SSID";
   const char* password = "YOUR_PASSWORD";
   const char* serverUrl = "http://192.168.x.x:8000/sensor/npk/update";
   ```
6. Select Board: `ESP32 Dev Module`
7. Select Port: `COM3` (or your ESP32 port)
8. Click Upload
9. Open Serial Monitor (9600 baud) to see debug output

### Phase 3: Test NPK Sensor Communication
Expected Serial Output:
```
Connecting to WiFi...
WiFi connected!
IP address: 192.168.1.100

N: 50.5 | P: 40.2 | K: 30.8
Sending: {"nitrogen":50.5,"phosphorus":40.2,"potassium":30.8,"timestamp":1234567890}
Data sent successfully!
```

### Phase 4: Backend API Testing
1. Ensure FastAPI is running:
   ```
   python app.py
   ```

2. Visit: `http://localhost:8000/docs`

3. Test GET `/sensor/npk`:
   - Should return latest data from ESP32
   ```json
   {
     "nitrogen": 50.5,
     "phosphorus": 40.2,
     "potassium": 30.8,
     "timestamp": "2024-03-24T10:30:00Z"
   }
   ```

4. Test POST `/predict`:
   - Input: NPK + Weather data
   - Output: Crop recommendation
   ```json
   {
     "nitrogen": 50.5,
     "phosphorus": 40.2,
     "potassium": 30.8,
     "temperature": 25,
     "humidity": 70,
     "rainfall": 120
   }
   ```

### Phase 5: Flutter App Integration
1. Update backend IP in `crop_prediction_service.dart`:
   ```dart
   static const String backendUrl = "http://192.168.1.100:8000";
   ```

2. Update OpenWeatherMap API key in the app

3. Run Flutter app:
   ```
   flutter run -d chrome
   ```

4. Navigate to Crop Prediction Screen

5. App should display:
   - NPK Sensor Data (from ESP32)
   - Weather Data (from OpenWeatherMap)
   - Recommended Crop + Confidence

---

## 5. TROUBLESHOOTING

### Problem: Serial Monitor shows garbage data
**Solution**: 
- Check baud rate in `Serial2.begin(9600, ...)`
- Verify RX/TX pins are correct
- Check USB cable connection

### Problem: "No data from sensor"
**Solution**:
- Verify RS-485 A/B wiring is not swapped
- Check sensor Modbus address (0x01 default)
- Use Modbus tester to confirm sensor responds
- Verify CRC calculation in code

### Problem: "WiFi not connected"
**Solution**:
- Check SSID and password
- Ensure ESP32 is in range
- Restart ESP32

### Problem: Backend not receiving data
**Solution**:
- Verify backend IP in ESP32 code
- Check firewall allows port 8000
- Test with: `curl http://192.168.x.x:8000/`
- Check backend logs for errors

### Problem: Flutter showing "Backend not responding"
**Solution**:
- Verify backend URL in Flutter is correct
- Ensure backend and mobile are on same network
- Test with Postman: `GET http://backend-ip:8000/sensor/npk`

---

## 6. LIVE DATA FLOW

```
┌─────────────────────────────────────────────────────────┐
│                  REAL-TIME DATA FLOW                     │
└─────────────────────────────────────────────────────────┘

TIME 0s:
  ESP32 reads NPK from sensor via RS-485
  └─→ Nitrogen: 50, Phosphorus: 40, Potassium: 30

TIME 1s:
  ESP32 sends HTTP POST to FastAPI backend
  └─→ POST http://backend:8000/sensor/npk/update
      {nitrogen: 50, phosphorus: 40, potassium: 30}

TIME 2s:
  Backend stores latest NPK data in memory
  └─→ GET /sensor/npk returns stored data

TIME 3s:
  Flutter app fetches NPK data
  └─→ GET http://backend:8000/sensor/npk
      Returns: {nitrogen: 50, phosphorus: 40, potassium: 30}

TIME 4s:
  Flutter app fetches weather from OpenWeatherMap
  └─→ Returns: {temp: 25, humidity: 70, rainfall: 120}

TIME 5s:
  Flutter sends crop prediction request
  └─→ POST /predict with all 6 parameters
      {nitrogen: 50, phosphorus: 40, potassium: 30,
       temperature: 25, humidity: 70, rainfall: 120}

TIME 6s:
  Backend ML model predicts crop
  └─→ Returns: {recommended_crop: "rice", confidence: 0.95}

TIME 7s:
  Flutter displays result to farmer
  └─→ "Recommended Crop: RICE (95% confidence)"
```

---

## 7. TESTING CHECKLIST

- [ ] ESP32 uploads successfully
- [ ] Serial Monitor shows NPK readings
- [ ] ESP32 connects to WiFi
- [ ] Data reaches backend (check http://backend:8000/sensor/npk)
- [ ] FastAPI `/predict` returns crop recommendation
- [ ] Flutter app displays NPK data
- [ ] Flutter app displays weather data
- [ ] Flutter app displays crop prediction
- [ ] Update database with prediction (for farmer history)

---

## 8. EXPECTED ACCURACY

With Kaggle dataset and RandomForest model:
- **Training Accuracy**: ~99%
- **Test Accuracy**: ~95%
- **Prediction Time**: <100ms
- **Model Size**: ~2-5 MB

---

## 9. QUICK START COMMANDS

```bash
# 1. Start backend
cd C:\Users\anushka\Agri_Expert\backend
python app.py

# 2. Test backend API
curl http://localhost:8000/sensor/npk

# 3. Run Flutter
cd C:\Users\anushka\Agri_Expert\mobile
flutter run -d chrome

# 4. Monitor ESP32
# Open Arduino IDE → Tools → Serial Monitor → 9600 baud
```

---

## Contact & Support
For issues or questions, check:
- ESP32 board log: Arduino IDE Serial Monitor
- FastAPI logs: Terminal output
- Flutter logs: VSCode Debug Console
