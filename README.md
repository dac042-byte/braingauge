# NeuroLoad

**AI-Powered Neurological Performance Tracking for Combat Athletes**

NeuroLoad is a mobile application designed to help combat athletes monitor cognitive performance changes over time. This is **not a medical diagnostic tool**—it's a performance, fatigue, and cognitive-stability tracker that shows trends through weekly assessments.

---

## 🎯 Overview

NeuroLoad helps athletes track three key performance areas:

1. **Speech Analysis** - Monitors speech patterns, rate, and fluency
2. **Cognitive Function** - Tracks reaction time and working memory
3. **Visual-Motor Coordination** - Measures eye tracking and smooth pursuit

Each week, users complete a brief assessment covering all three areas. The app compares results to a personal baseline and generates a **Neuro Load Score** (0-100) that reflects cognitive drift over time.

---

## 🏗️ Architecture

### Backend (FastAPI + Python)
- **Framework**: FastAPI
- **Database**: SQLite (easily upgradeable to PostgreSQL)
- **Features**:
  - Speech feature extraction (WPM, filler words, pauses)
  - Cognitive test scoring (reaction time, working memory)
  - Visual-motor analysis (blink frequency, pursuit accuracy)
  - Weighted Neuro Load Score calculation
  - Trend analysis across weeks

### Mobile App (Flutter + Dart)
- **Framework**: Flutter (iOS & Android)
- **State Management**: Provider
- **Features**:
  - User authentication
  - Baseline establishment
  - Weekly check-in flow
  - Dashboard with score visualization
  - Trend charts and insights
  - Audio recording for speech tests
  - Interactive cognitive tests
  - Eye tracking simulation

---

## 📁 Project Structure

```
neuroload/
├── backend/
│   ├── app/
│   │   ├── models/
│   │   │   ├── database.py      # SQLAlchemy models
│   │   │   └── schemas.py       # Pydantic schemas
│   │   ├── routes/
│   │   │   ├── auth.py          # Authentication endpoints
│   │   │   ├── speech.py        # Speech analysis endpoints
│   │   │   ├── cognitive.py     # Cognitive test endpoints
│   │   │   ├── visual.py        # Visual-motor endpoints
│   │   │   └── score.py         # Scoring and trends
│   │   └── services/
│   │       ├── speech_analyzer.py
│   │       ├── cognitive_analyzer.py
│   │       ├── visual_motor_analyzer.py
│   │       └── scoring_engine.py
│   ├── main.py
│   └── requirements.txt
│
└── mobile/
    ├── lib/
    │   ├── models/              # Data models
    │   ├── screens/             # UI screens
    │   │   ├── auth/
    │   │   ├── home/
    │   │   └── assessment/
    │   ├── services/            # API service
    │   ├── utils/               # App state
    │   └── widgets/
    └── pubspec.yaml
```

---

## 🚀 Getting Started

### Prerequisites

**Backend:**
- Python 3.9+
- pip

**Mobile:**
- Flutter SDK 3.0+
- Android Studio / Xcode
- Physical device or emulator

### Backend Setup

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the server
python main.py
```

The API will be available at `http://localhost:8000`

**API Documentation:** Visit `http://localhost:8000/docs` for interactive API docs

### Mobile Setup

```bash
# Navigate to mobile directory
cd mobile

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run
```

**Update API URL:**
Edit `mobile/lib/services/api_service.dart` and change `baseUrl` to your backend URL:
```dart
static const String baseUrl = 'http://YOUR_IP:8000/api';
```

---

## 📱 User Flow

### 1. Registration & Login
- Create account with username, email, password
- Login to access the app

### 2. Baseline Creation
- Complete all three assessments (speech, cognitive, visual-motor)
- Establishes personal performance benchmarks
- Takes 5-10 minutes

### 3. Weekly Check-Ins
- Complete the same assessments weekly
- Compare to baseline
- Receive Neuro Load Score

### 4. Track Trends
- View score history on dashboard
- Analyze trends over time
- Get personalized insights

---

## 🧪 Assessment Details

### Speech Recording (2-3 minutes)
- Read a standardized passage
- Records for 20-60 seconds
- Analyzes:
  - Words per minute (WPM)
  - Filler word count
  - Average pause length
  - Speech rate

### Cognitive Tests (3-4 minutes)

**Reaction Time Test:**
- 10 trials
- Tap when target appears
- Measures: avg reaction time, consistency

**Working Memory Test (2-Back):**
- 20 trials
- Tap when current letter matches letter from 2 steps ago
- Measures: accuracy, response time

### Eye Tracking (1 minute)
- Follow moving dot with eyes
- 15-second test
- Measures:
  - Blink frequency
  - Smooth pursuit accuracy
  - Tracking variance

---

## 🎯 Neuro Load Score

The Neuro Load Score (0-100) combines drift scores from all three areas:

- **Speech Drift**: 30% weight
- **Cognitive Drift**: 45% weight
- **Visual-Motor Drift**: 25% weight

**Score Interpretation:**
- **0-15**: Stable - Performance consistent with baseline
- **15-30**: Minor Changes - Normal variation or slight fatigue
- **30-100**: Significant Changes - Consider rest and recovery

---

## 🔧 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login and get token

### Speech Analysis
- `POST /api/speech/analyze` - Analyze speech transcript
- `POST /api/speech/upload` - Upload audio file
- `GET /api/speech/passages` - Get reading passages

### Cognitive Tests
- `POST /api/cognitive/analyze` - Submit cognitive test results
- `GET /api/cognitive/reaction-time-config` - Get test config
- `GET /api/cognitive/working-memory-config` - Get test config

### Visual-Motor
- `POST /api/visual/analyze` - Submit eye tracking data
- `GET /api/visual/tracking-config` - Get test config

### Scoring
- `POST /api/score/baseline` - Create baseline
- `GET /api/score/baseline` - Get active baseline
- `POST /api/score/weekly-assessment` - Submit weekly assessment
- `GET /api/score/neuro-load/{week}` - Get score for specific week
- `GET /api/score/trends` - Get trend analysis

---

## 🔐 Security Notes

**For Production:**
1. Change `SECRET_KEY` in `backend/app/routes/auth.py`
2. Use environment variables for sensitive data
3. Enable HTTPS
4. Configure CORS properly
5. Use PostgreSQL instead of SQLite
6. Implement rate limiting
7. Add input validation and sanitization

---

## 🧩 Future Enhancements

### Backend
- [ ] Integration with real speech-to-text APIs (Whisper, Google, AssemblyAI)
- [ ] Advanced analytics and ML insights
- [ ] Export data to CSV/PDF
- [ ] Multi-user comparison (anonymized)
- [ ] Coach/trainer dashboard

### Mobile
- [ ] Real camera-based eye tracking (ML Kit, ARKit)
- [ ] Offline mode with sync
- [ ] Push notifications for weekly reminders
- [ ] Training load integration
- [ ] Dark mode improvements
- [ ] Accessibility features

---

## ⚠️ Important Disclaimer

**This application is NOT a medical diagnostic tool.**

NeuroLoad is designed for:
- ✅ Performance tracking
- ✅ Training awareness
- ✅ Fatigue monitoring
- ✅ Self-awareness

It is NOT designed for:
- ❌ Medical diagnosis
- ❌ Concussion detection
- ❌ Clinical decision-making
- ❌ Replacement for medical care

**If you have health concerns, please consult a qualified healthcare professional.**

---

## 🛠️ Technology Stack

**Backend:**
- FastAPI - Modern Python web framework
- SQLAlchemy - SQL toolkit and ORM
- Pydantic - Data validation
- NumPy/SciPy - Numerical computing
- JWT - Authentication

**Mobile:**
- Flutter - Cross-platform framework
- Provider - State management
- FL Chart - Data visualization
- Record - Audio recording
- HTTP/Dio - API communication

---

## 📊 Database Schema

### Users
- id, username, email, hashed_password, created_at

### Baselines
- id, user_id, created_at, is_active
- Speech metrics (wpm, filler_count, avg_pause, speech_rate)
- Cognitive metrics (reaction_time_avg, reaction_time_std, memory_accuracy, memory_response_time)
- Visual-motor metrics (blink_frequency, smooth_pursuit_accuracy, tracking_variance)

### Weekly Assessments
- id, user_id, baseline_id, week_number, created_at
- All baseline metrics plus drift scores
- neuro_load_score, notes, raw_data

### Speech Recordings
- id, user_id, assessment_id, file_path, transcript, duration, features

---

## 🤝 Contributing

This is a demonstration project. For production use:
1. Implement proper error handling
2. Add comprehensive testing
3. Improve security measures
4. Integrate real AI/ML services
5. Add logging and monitoring

---

## 📄 License

This project is provided as-is for educational and demonstration purposes.

---

## 👥 Support

For questions or issues, please refer to the inline code documentation and API docs at `/docs` endpoint.

---

**Built for combat athletes who want to understand their cognitive performance trends over time.**

*Train smart. Recover smarter. Track your NeuroLoad.*
