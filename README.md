# AI Questionnaire App

A comprehensive Flutter application that generates intelligent quizzes from documents (PDF and PowerPoint) using Google Gemini AI, with Firebase backend for real-time synchronization and achievement tracking.

> **🚀 FIREBASE + GEMINI AI POWERED!**
> 
> **Status:** ✅ **Production Ready** 
> - ✅ Google Gemini AI for smart question generation
> - ✅ Firebase Firestore for cloud storage & real-time sync
> - ✅ Anonymous authentication for instant access
> - ✅ Offline-first architecture with auto-sync
> - ✅ Advanced performance analytics & achievements

## 🔥 **Technology Stack**

| Component | Technology | Purpose |
|-----------|------------|---------|
| **AI Engine** | 🤖 **Google Gemini 2.0** | Smart question generation |
| **Backend** | ☁️ **Firebase Firestore** | Cloud database & sync |
| **Auth** | 🔐 **Firebase Auth** | Anonymous user sessions |
| **Frontend** | 📱 **Flutter 3.9.2+** | Cross-platform mobile app |
| **Storage** | 💾 **Offline-first** | Local cache + cloud sync |

## ✨ Features

### 📄 Document Processing
- **PDF Support**: Upload and extract text from PDF documents
- **PowerPoint Support**: Process .ppt and .pptx presentations  
- **Smart Text Extraction**: Advanced OCR and content parsing
- **Auto Subject Detection**: AI determines document subject automatically
- **Large File Handling**: Efficient processing of documents up to 10MB

### 🤖 AI-Powered Question Generation (Google Gemini)
- **Multiple Choice**: 4-option questions with detailed explanations
- **True/False**: Binary choice questions with reasoning
- **Enumeration**: List-based questions requiring multiple answers
- **Adaptive Difficulty**: Easy, Medium, Hard levels based on content
- **Content-Specific**: Questions generated from actual document content
- **Batch Processing**: Generate 5-50 questions in a single API call

### 📊 Real-Time Analytics & Performance
- **Live Sync**: Performance data synced across devices instantly
- **Subject Mastery**: Track progress by subject area
- **Detailed Statistics**: Comprehensive quiz history and trends
- **Strengths Analysis**: Identify areas of expertise and improvement
- **Progress Visualization**: Charts and graphs of learning progress

### 🏆 Achievement System
**Three Tiers of Recognition:**

| **🏅 Badges** | **🥇 Medals** | **🎗️ Ribbons** |
|---------------|---------------|----------------|
| Daily habits & streaks | Major milestones | Subject mastery |
| "5 Study Sessions" | "Perfect Score" | "English Master" |
| "30 Min Focus Time" | "First Month" | "Math Expert" |

### 🔄 Firebase Integration
- **Real-time Sync**: Automatic data synchronization across devices
- **Offline Support**: Full functionality without internet connection
- **Anonymous Auth**: No registration required - instant access
- **Cloud Backup**: Automatic backup of all progress and achievements
- **Scalable Storage**: Unlimited quiz and performance data storage

### 🎯 Quiz Customization
- **Flexible Length**: 5-50 questions per quiz
- **Mixed Question Types**: Combine multiple choice, T/F, and enumeration
- **Difficulty Scaling**: AI adapts question complexity
- **Custom Titles**: Personalized quiz naming
- **Subject Categorization**: Automatic and manual subject assignment

## 🛠️ Technical Architecture

### 📱 Tech Stack Details
```yaml
dependencies:
  # Core Framework
  flutter: ^3.9.2
  
  # Firebase Backend
  firebase_core: ^2.24.2
  cloud_firestore: ^4.13.6
  firebase_auth: ^4.15.3
  
  # AI Integration  
  http: ^1.1.0
  flutter_dotenv: ^5.1.0
  
  # Document Processing
  file_picker: ^8.0.0+1
  syncfusion_flutter_pdf: ^26.2.14
  archive: ^3.6.1
  xml: ^6.5.0
  
  # State Management
  provider: ^6.1.2
  
  # UI Enhancement
  google_fonts: ^6.2.1
  lottie: ^3.1.2
  font_awesome_flutter: ^10.7.0
```

### 🏗️ Project Structure
```
lib/
├── models/                    # Data models
│   ├── question.dart         # Question with multiple types
│   ├── quiz.dart             # Quiz structure & metadata
│   ├── achievement.dart      # Achievement system
│   ├── user_answer.dart      # User response tracking
│   └── performance_analytics.dart
├── services/                 # Business logic
│   ├── ai_service.dart       # Google Gemini integration
│   ├── database_service_firebase.dart  # Firebase operations
│   ├── firebase_service.dart # Firebase initialization
│   └── document_service.dart # PDF/PPT processing
├── providers/               # State management
│   ├── quiz_provider.dart
│   ├── achievement_provider.dart
│   └── performance_provider.dart
├── screens/                # UI screens
│   ├── home_screen.dart
│   ├── quiz_creation_screen.dart
│   ├── quiz_taking_screen.dart
│   ├── achievements_screen.dart
│   └── performance_screen.dart
└── widgets/               # Reusable components
```

### 🔧 Core Models

**Question Model:**
```dart
class Question {
  final String id;
  final String text;
  final QuestionType type;  // multipleChoice, trueFalse, enumeration
  final List<String> options;
  final String correctAnswer;
  final List<String> correctAnswers;  // For enumeration
  final String subject;
  final DifficultyLevel difficulty;
  final String explanation;
  final DateTime createdAt;
}

enum QuestionType { multipleChoice, trueFalse, enumeration }
enum DifficultyLevel { easy, medium, hard }
```

**Quiz Model:**
```dart
class Quiz {
  final String id;
  final String title;
  final String subject;
  final List<Question> questions;
  final DateTime createdAt;
  final QuizStatus status;
  final Map<String, String> userAnswers;
  final double? score;
  final Duration? completionTime;
}
```

## 🚀 Quick Start Guide

### Prerequisites
- Flutter SDK 3.9.2+
- Firebase project with Firestore enabled
- Google Gemini API key
- Android Studio or VS Code with Flutter extensions

### 1. **Clone & Setup**
```bash
git clone https://github.com/yourusername/ai_questionaire.git
cd ai_questionaire
flutter pub get
```

### 2. **Environment Configuration**
Create `.env` file in project root:
```env
GEMINI_API_KEY=your_gemini_api_key_here
```

### 3. **Firebase Setup**

#### Create Firebase Project
1. Visit [Firebase Console](https://console.firebase.google.com)
2. Create new project: `ai-questionnaire-app`
3. Enable Google Analytics (optional)

#### Setup Firestore Database
1. Navigate to **Firestore Database**
2. Create database in **test mode** (for development)
3. Choose your preferred region

#### Enable Authentication
1. Go to **Authentication** → **Sign-in method**
2. Enable **Anonymous** authentication
3. Save configuration

#### Add Flutter Apps
1. Project Settings → Add app → Flutter
2. Package name: `com.example.ai_questionaire`
3. Download configuration files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

### 4. **Update Firebase Configuration**
Edit `lib/services/firebase_service.dart`:
```dart
static const FirebaseOptions _options = FirebaseOptions(
  apiKey: "your-web-api-key",
  authDomain: "your-project.firebaseapp.com", 
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef123456",
);
```

### 5. **Run the App**
```bash
flutter run
```

## 📖 User Guide

### Creating Your First Quiz
1. **Launch App** → Tap "Upload Document & Create Quiz"
2. **Select File** → Choose PDF or PowerPoint file
3. **Configure Quiz**:
   - Enter quiz title
   - Set number of questions (5-50)  
   - Choose difficulty level
   - Select question types
4. **Generate** → AI processes document and creates questions
5. **Ready!** → Quiz appears in your library

### Taking Quizzes
1. Navigate to **"My Quizzes"** tab
2. Select quiz from your library
3. Answer questions by type:
   - **Multiple Choice**: Select one option
   - **True/False**: Choose True or False  
   - **Enumeration**: Enter comma-separated answers
4. Submit for instant results with explanations

### Tracking Progress
- **Performance Tab**: View overall statistics and subject breakdown
- **Achievements Tab**: See unlocked badges, medals, and ribbons
- **Quiz History**: Review past performance and improvement trends

## 🔑 API Configuration

### Google Gemini API Setup
1. Visit [Google AI Studio](https://aistudio.google.com/)
2. Create new project or select existing
3. Generate API key
4. Add to `.env` file:
```env
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

**Gemini API Features Used:**
- **Model**: `gemini-2.0-flash` (latest fast model)
- **Content Analysis**: Deep document understanding
- **Structured Output**: JSON-formatted question generation
- **Safety Filters**: Built-in content moderation

## 🧪 Development & Testing

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

### Build Commands
```bash
# Android APK
flutter build apk --release

# iOS App
flutter build ios --release

# Web App  
flutter build web
```

### Development Environment
```bash
# Install dependencies
flutter pub get

# Run with hot reload
flutter run --debug

# Profile performance
flutter run --profile

# Analyze code
flutter analyze
```

## 📊 Performance Monitoring

### Firebase Analytics Integration
The app includes comprehensive analytics tracking:
- Quiz completion rates
- Question difficulty analysis  
- User engagement metrics
- Performance improvement trends

### Error Handling & Logging
- Automatic error reporting to Firebase Crashlytics
- Detailed debug logging for development
- Graceful fallbacks for offline scenarios

## 🚀 Deployment

### Android Play Store
```bash
flutter build appbundle --release
```

### iOS App Store
```bash
flutter build ios --release
```

### Web Deployment
```bash
flutter build web --release
# Deploy to Firebase Hosting, Netlify, or your preferred platform
```

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Make changes with comprehensive tests
4. Commit: `git commit -m 'feat: add amazing feature'`
5. Push: `git push origin feature/amazing-feature`  
6. Open Pull Request

### Code Standards
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Write tests for all new features
- Use conventional commit messages
- Update documentation for API changes

### Testing Guidelines
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for user flows
- Performance tests for large document processing

## 🐛 Troubleshooting

### Common Issues & Solutions

**❌ Document Upload Fails**
```bash
# Solutions:
- Verify file format (PDF/PPT/PPTX only)
- Check file size (< 10MB recommended)  
- Ensure sufficient device storage
- Restart app if picker crashes
```

**❌ AI Question Generation Fails**
```bash
# Solutions:
- Verify GEMINI_API_KEY in .env file
- Check internet connectivity
- Monitor API quotas in Google Cloud Console
- Ensure document has sufficient text content (>50 chars)
```

**❌ Firebase Sync Issues**
```bash
# Solutions:
- Check Firebase project configuration
- Verify internet connection
- Clear app data and re-authenticate
- Check Firestore security rules
```

**❌ App Performance Issues**
```bash
# Solutions:
- Clear app cache: Settings > Storage > Clear Cache
- Restart application
- Check available device memory
- Update to latest app version
```

### Debug Mode
Enable debug logging by setting:
```dart
const bool kDebugMode = true; // In main.dart
```

## 📈 Roadmap

### 🎯 Version 2.1 (Next Release)
- [ ] **File Converter**: FPDF To PPTX,DOCS To PDF
- [ ] **OCR Enhancement**: Better image-based PDF support  
- [ ] **Collaborative Quizzes**: Share quizzes with friends
- [ ] **Advanced Analytics**: Learning pattern analysis
- [ ] **Custom Achievements**: Create personal goals

### 🔮 Version 2.2 (Future)
- [ ] **Multi-language Support**: Internationalization
- [ ] **Learning Paths**: Structured curriculum creation
- [ ] **Social Features**: Leaderboards and challenges
- [ ] **Export Features**: PDF report generation
- [ ] **API Integrations**: Connect with LMS platforms

### 🌟 Long-term Vision
- [ ] **Offline AI**: Local question generation models
- [ ] **AR/VR Support**: Immersive learning experiences
- [ ] **Adaptive Learning**: Personalized difficulty adjustment
- [ ] **Enterprise Features**: Team management and reporting


## 🙏 Acknowledgments

- **Google Gemini AI** for powerful question generation capabilities
- **Firebase** for robust backend infrastructure
- **Flutter Team** for excellent cross-platform framework
- **Syncfusion** for PDF processing components
- **Community Contributors** for bug reports and feature requests

## 📞 Support & Community

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/Boniechan/ai_questionaire/issues)


**🚀 Transform Your Learning with AI-Powered Quizzes!**

*Built with ❤️ using Flutter, Firebase & Google Gemini AI*

*Last updated: September 2025*
