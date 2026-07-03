# 🎸 Flutter Architecture Guide: Monorepo vs Multi-Repo

Comprehensive analysis and recommendations for structuring Flutter apps (web, iOS, Android) for the Guitar AI Tutor platform.

---

## 📋 Table of Contents

- [Executive Summary](#-executive-summary)
- [Architecture Comparison](#-architecture-comparison)
- [Recommendation for Guitar AI](#-recommendation-for-guitar-ai)
- [Recommended Monorepo Structure](#-recommended-monorepo-structure)
- [Implementation Guide](#-implementation-guide)
- [Tools & Best Practices](#-tools--best-practices)
- [Migration Path](#-migration-path)

---

## 🎯 Executive Summary

### **For Guitar AI: MONOREPO is RECOMMENDED** ✅

**Why:**
- ✅ Single codebase for iOS, Android, Web
- ✅ Shared business logic (audio processing, evaluation engine)
- ✅ Unified state management & dependency management
- ✅ Atomic changes across platforms
- ✅ Easier onboarding for new developers
- ✅ Consistent UI/UX across platforms
- ✅ Simpler CI/CD setup

**Scale:** For a music learning platform with 1-2 development teams, monorepo is ideal.

---

## 📊 Architecture Comparison

### **Monorepo (Single Repository)**

```
guitar-ai/
├── frontend/
│   ├── apps/
│   │   ├── app_mobile/     (iOS + Android)
│   │   ├── app_web/        (Web)
│   │   └── app_desktop/    (Optional: macOS/Windows)
│   ├── packages/           (Shared code)
│   └── melos.yaml
├── backend/                (Existing)
├── docs/
└── README.md
```

#### **Monorepo Advantages:**
| Benefit | Details |
|---------|---------|
| **Code Reuse** | 70-80% shared code (UI, logic, state management) |
| **Atomic Changes** | One PR updates mobile + web + backend |
| **Dependency Mgmt** | Single `pubspec.yaml` workspace |
| **Consistency** | Same theme, components, business logic |
| **CI/CD** | Unified testing, linting, deployment |
| **Onboarding** | Clone one repo, run setup |

#### **Monorepo Challenges:**
| Challenge | Solution |
|-----------|----------|
| **Large git operations** | Use Melos for selective operations |
| **Build complexity** | Proper module separation |
| **Access control** | GitHub code owners, branch protection |

---

### **Separate Repositories**

```
guitar-ai-backend/        (Already exists)
guitar-ai-frontend/       (Flutter web)
guitar-ai-mobile/         (Flutter iOS/Android)
guitar-ai-shared/         (Shared packages)
```

#### **Separate Repos Advantages:**
| Benefit | Details |
|---------|---------|
| **Independence** | Each platform can move at own pace |
| **Access Control** | Restrict access per repo |
| **Performance** | Smaller repos = faster git operations |
| **Teams** | Separate teams don't interfere |

#### **Separate Repos Disadvantages:**
| Challenge | Details |
|-----------|---------|
| **Duplication** | Shared logic duplicated across repos |
| **Sync Issues** | Versions can drift |
| **Integration** | Complex cross-repo updates |
| **Overhead** | Manage multiple CI/CD pipelines |

---

## ✨ Recommendation for Guitar AI

### **OPTION 1: MONOREPO (RECOMMENDED) ⭐⭐⭐⭐⭐**

**Best for Guitar AI because:**
- 🎯 **Shared Audio Processing**: Core pitch detection, evaluation logic used by all platforms
- 🎯 **Consistent UX**: Same UI components, theme across iOS, Android, Web
- 🎯 **Rapid Development**: Changes propagate across platforms instantly
- 🎯 **Team Size**: Your solo/small team can manage entire codebase
- 🎯 **Audio Streaming**: WebSocket/gRPC clients can share logic
- 🎯 **State Management**: Provider/Riverpod state shared across platforms

### **OPTION 2: HYBRID (Monorepo + Separate Backend)**

**Current setup:** ✅ This is already your architecture!
- ✅ Backend in `main guitar-ai` repo
- ✅ Frontend in `frontend/` subdirectory
- ✅ Can expand to full monorepo

### **OPTION 3: Separate Repos (NOT RECOMMENDED)**

Would result in:
- ❌ Duplicate audio processing logic
- ❌ Inconsistent UI between platforms
- ❌ Complex version management
- ❌ Sync issues between platforms

---

## 📁 Recommended Monorepo Structure for Guitar AI

### **Complete Project Structure**

```
guitar-ai/ (existing repo)
│
├── backend/                          # Existing backend
│   ├── src/
│   ├── package.json
│   └── Dockerfile
│
├── frontend/                         # NEW: Flutter Monorepo
│   ├── apps/
│   │   ├── app_mobile/              # iOS + Android (single Flutter app)
│   │   │   ├── lib/
│   │   │   │   ├── main.dart
│   │   │   │   ├── main_mobile.dart # Mobile-specific entry point
│   │   │   │   ├── src/
│   │   │   │   │   ├── presentation/
│   │   │   │   │   ├── domain/
│   │   │   │   │   └── data/
│   │   │   │   └── features/
│   │   │   ├── ios/
│   │   │   ├── android/
│   │   │   ├── pubspec.yaml
│   │   │   └── analysis_options.yaml
│   │   │
│   │   ├── app_web/                 # Web (Flutter Web)
│   │   │   ├── lib/
│   │   │   │   ├── main.dart
│   │   │   │   ├── main_web.dart    # Web-specific entry point
│   │   │   │   ├── src/
│   │   │   │   └── features/
│   │   │   ├── web/
│   │   │   ├── pubspec.yaml
│   │   │   └── analysis_options.yaml
│   │   │
│   │   └── app_desktop/             # Optional: macOS + Windows
│   │       ├── lib/
│   │       ├── macos/
│   │       ├── windows/
│   │       ├── pubspec.yaml
│   │       └── analysis_options.yaml
│   │
│   ├── packages/                    # Shared packages
│   │   ├── core/                    # Core utilities
│   │   │   ├── lib/
│   │   │   │   ├── constants/
│   │   │   │   ├── extensions/
│   │   │   │   ├── utils/
│   │   │   │   └── services/
│   │   │   └── pubspec.yaml
│   │   │
│   │   ├── features/               # Feature packages
│   │   │   ├── auth/
│   │   │   │   ├── lib/
│   │   │   │   │   ├── presentation/  (Screens, widgets)
│   │   │   │   │   ├── domain/       (Use cases, entities)
│   │   │   │   │   ├── data/         (Repositories, models)
│   │   │   │   │   └── providers.dart (Riverpod providers)
│   │   │   │   └── pubspec.yaml
│   │   │   │
│   │   │   ├── lessons/
│   │   │   ├── solos/
│   │   │   ├── chords/
│   │   │   ├── practice/           # Core practice feature
│   │   │   │   ├── lib/
│   │   │   │   │   ├── presentation/
│   │   │   │   │   ├── domain/
│   │   │   │   │   ├── data/
│   │   │   │   │   └── providers/
│   │   │   │   └── pubspec.yaml
│   │   │   │
│   │   │   ├── audio_processing/  # Audio handling
│   │   │   │   ├── lib/
│   │   │   │   │   ├── audio_recorder.dart
│   │   │   │   │   ├── pitch_detector.dart
│   │   │   │   │   └── audio_stream_manager.dart
│   │   │   │   └── pubspec.yaml
│   │   │   │
│   │   │   ├── feedback/
│   │   │   ├── progress/
│   │   │   ├── social/              # Optional: Social features
│   │   │   └── settings/
│   │   │
│   │   ├── shared_ui/              # Shared UI components
│   │   │   ├── lib/
│   │   │   │   ├── theme/
│   │   │   │   ├── widgets/
│   │   │   │   ├── dialogs/
│   │   │   │   └── utils/
│   │   │   └── pubspec.yaml
│   │   │
│   │   └── network/                # API communication
│   │       ├── lib/
│   │       │   ├── client.dart
│   │       │   ├── dio_client.dart
│   │       │   ├── websocket_client.dart
│   │       │   └── models/
│   │       └── pubspec.yaml
│   │
│   ├── analysis_options.yaml         # Shared analysis config
│   ├── melos.yaml                    # Monorepo config
│   ├── pubspec.yaml                  # Root workspace
│   ├── .gitignore
│   └── README.md
│
├── docs/                             # Existing documentation
│   ├── ARCHITECTURE.md
│   ├── AI_INTELLIGENCE_SYSTEM.md
│   ├── FLUTTER_ARCHITECTURE.md       # NEW
│   └── ...
│
├── README.md
├── docker-compose.yml
└── .gitignore
```

---

## 🛠️ Implementation Guide

### **Step 1: Setup Melos Configuration**

Create `frontend/melos.yaml`:

```yaml
name: guitar_ai_frontend
description: Flutter monorepo for Guitar AI Tutor

repository: https://github.com/Trinhleo/guitar-ai

packages:
  - packages/**
  - apps/**

scripts:
  # Format all code
  format:
    exec: dart format .
    description: Format all files in the monorepo
  
  # Analyze all packages
  analyze:
    exec: flutter analyze
    description: Analyze all packages and apps
  
  # Run tests
  test:
    exec: flutter test
    description: Run tests for all packages
  
  # Clean all packages
  clean:
    exec: flutter clean
    description: Clean all packages
    packageFilters:
      fsKeywords:
        - app
        - packages
  
  # Bootstrap packages
  bootstrap:
    exec: flutter pub get
    description: Bootstrap all packages
  
  # Build mobile
  build_mobile:
    exec: flutter build apk --release
    description: Build Android APK
    packageFilters:
      scopes:
        - app_mobile
  
  # Build web
  build_web:
    exec: flutter build web --release
    description: Build web release
    packageFilters:
      scopes:
        - app_web

version: 1.0.0
```

### **Step 2: Root pubspec.yaml**

Create `frontend/pubspec.yaml`:

```yaml
name: guitar_ai_frontend
description: Guitar AI Tutor - Flutter Monorepo
version: 1.0.0

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.16.0"

dev_dependencies:
  melos: ^5.0.0
```

### **Step 3: Shared Core Package**

Create `frontend/packages/core/pubspec.yaml`:

```yaml
name: core
description: Core utilities, constants, and services

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.16.0"

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.3.0
  shared_preferences: ^2.2.0
  logger: ^2.0.0
  get_it: ^7.5.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

### **Step 4: Feature Package (Practice)**

Create `frontend/packages/features/practice/pubspec.yaml`:

```yaml
name: practice
description: Practice session management and audio recording

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.16.0"

dependencies:
  flutter:
    sdk: flutter
  core:
    path: ../../core
  shared_ui:
    path: ../../shared_ui
  network:
    path: ../../network
  audio_processing:
    path: ../audio_processing
  
  # State management
  riverpod: ^2.4.0
  flutter_riverpod: ^2.4.0
  
  # Audio
  record: ^4.4.0
  audio_waveforms: ^1.1.0
  
  # UI
  flutter_animate: ^4.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

### **Step 5: Audio Processing Package**

Create `frontend/packages/features/audio_processing/lib/audio_processor.dart`:

```dart
// Core audio processing shared across all platforms
import 'package:record/record.dart';
import 'dart:async';

class AudioProcessor {
  final Record _record = Record();
  
  Stream<List<int>> recordAudioStream({
    required AudioSource source,
    int sampleRate = 44100,
  }) {
    return _recordStream(source: source, sampleRate: sampleRate);
  }
  
  Stream<List<int>> _recordStream({
    required AudioSource source,
    required int sampleRate,
  }) async* {
    try {
      final hasPermission = await _record.hasPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission denied');
      }
      
      await _record.start(
        path: 'temp_audio.wav',
        encoder: AudioEncoder.wav,
        samplingRate: sampleRate,
      );
      
      // Stream audio data
      yield* _streamAudioData();
    } catch (e) {
      throw Exception('Failed to record: $e');
    }
  }
  
  Stream<List<int>> _streamAudioData() async* {
    // Emit audio chunks as they're recorded
    // This will be consumed by pitch detection service
  }
  
  Future<void> stopRecording() => _record.stop();
}
```

### **Step 6: Shared UI Package**

Create `frontend/packages/shared_ui/lib/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFF6366F1);
  static const secondaryColor = Color(0xFF8B5CF6);
  static const accentColor = Color(0xFFF59E0B);
  
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
      ),
      typography: Typography.material2021(),
    );
  }
  
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
    );
  }
}
```

### **Step 7: Network Package**

Create `frontend/packages/network/lib/api_client.dart`:

```dart
// Unified API client for all platforms
import 'package:dio/dio.dart';

class ApiClient {
  late final Dio _dio;
  
  ApiClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? 'http://localhost:5000/api',
        connectTimeout: Duration(seconds: 30),
        receiveTimeout: Duration(seconds: 30),
      ),
    );
    
    // Add interceptors
    _dio.interceptors.add(LoggingInterceptor());
  }
  
  // WebSocket for real-time audio feedback
  Stream<Map<String, dynamic>> connectAudioFeedback(String sessionId) {
    return WebSocketConnection.stream(
      'ws://localhost:5000/ws/practice/$sessionId'
    );
  }
  
  Future<dynamic> post(String path, {required data}) {
    return _dio.post(path, data: data);
  }
  
  Future<dynamic> get(String path) {
    return _dio.get(path);
  }
}
```

### **Step 8: Mobile App Entry Point**

Create `frontend/apps/app_mobile/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  setupServiceLocator(); // Setup dependency injection
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Guitar AI Tutor',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
```

### **Step 9: Web App Entry Point**

Create `frontend/apps/app_web/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  setupServiceLocator();
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Guitar AI Tutor - Web',
      theme: AppTheme.lightTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1200),
              child: HomePage(),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 📚 Tools & Best Practices

### **1. Melos Commands**

```bash
# Bootstrap all packages (install dependencies)
melos bootstrap

# Format all code
melos format

# Analyze all packages
melos analyze

# Run tests
melos test

# Clean all
melos clean

# Build specific app
melos build_mobile
melos build_web
```

### **2. State Management: Riverpod**

Shared Riverpod providers in `packages/core/lib/providers/`:

```dart
// audio_provider.dart
final audioRecorderProvider = StateNotifierProvider<
  AudioRecorderNotifier,
  AsyncValue<RecordingState>
>((ref) {
  return AudioRecorderNotifier();
});

// practice_provider.dart
final practiceFeedbackProvider = StreamProvider<Map<String, dynamic>>(
  (ref) {
    final sessionId = ref.watch(currentSessionProvider);
    return ref.watch(apiClientProvider).connectAudioFeedback(sessionId);
  },
);
```

### **3. Architecture: Clean Architecture**

Each feature follows:

```
feature/
├── presentation/      # UI (Screens, Widgets)
│   ├── screens/
│   ├── widgets/
│   └── providers/
├── domain/           # Business Logic
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── data/             # Data Layer
    ├── models/
    ├── repositories/
    └── datasources/
```

### **4. Platform-Specific Code**

Use conditional imports:

```dart
// lib/services/audio_service.dart
import 'audio_service_mobile.dart'
    if (dart.library.html) 'audio_service_web.dart'
    as audio_service;

// Usage works on both platforms
final recorder = audio_service.createRecorder();
```

### **5. CI/CD Pipeline**

Create `.github/workflows/flutter-ci.yml`:

```yaml
name: Flutter CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Get dependencies
        run: |
          cd frontend
          flutter pub global activate melos
          melos bootstrap
      
      - name: Format check
        run: melos format --check
      
      - name: Analyze
        run: melos analyze
      
      - name: Test
        run: melos test
      
      - name: Build mobile
        run: flutter build apk --release
        working-directory: frontend/apps/app_mobile
      
      - name: Build web
        run: flutter build web --release
        working-directory: frontend/apps/app_web
```

---

## 🔄 Migration Path

### **If starting from scratch (RECOMMENDED):**

```
Week 1:
  ├─ Setup Melos & monorepo structure
  ├─ Create core package
  └─ Create shared_ui package

Week 2:
  ├─ Create feature packages (auth, practice, audio_processing)
  ├─ Setup app_mobile with web config
  └─ Setup app_web

Week 3:
  ├─ Implement shared providers (Riverpod)
  ├─ Setup WebSocket client for real-time audio
  └─ Setup CI/CD pipeline

Week 4:
  ├─ Build core features
  ├─ Test on iOS, Android, Web
  └─ Optimize for each platform
```

### **If migrating from existing structure:**

```
Current State:
  guitar-ai/
  ├─ backend/
  └─ (no frontend yet)

Migration:
  Step 1: Create frontend/ directory
  Step 2: Setup Flutter monorepo structure
  Step 3: Setup shared packages
  Step 4: Create app_mobile and app_web
  Step 5: Gradually move code from monolithic to modular
  Step 6: Update CI/CD to include Flutter builds
```

---

## 📊 Comparison: Current vs Recommended

### **Current (If using separate repos):**

```
guitar-ai (backend)
guitar-ai-web (Flutter web)
guitar-ai-mobile (Flutter mobile)
guitar-ai-shared (shared packages on pub.dev)
```

**Issues:**
- ❌ Duplicate business logic
- ❌ Version sync issues
- ❌ Complex integration
- ❌ Multiple CI/CD pipelines

### **Recommended (Monorepo):**

```
guitar-ai/
├── backend/
├── frontend/
│   ├── apps/
│   │   ├── app_mobile
│   │   ├── app_web
│   │   └── app_desktop
│   └── packages/
│       ├── core
│       ├── features/
│       └── shared_ui
└── docs/
```

**Benefits:**
- ✅ Single source of truth
- ✅ Atomic changes
- ✅ Shared logic
- ✅ Unified testing
- ✅ Easier maintenance

---

## 🚀 Project Setup Instructions

### **Initialize monorepo:**

```bash
# 1. Create frontend directory
mkdir frontend
cd frontend

# 2. Initialize git (already initialized for main repo)
# git init  # (skip if using existing repo)

# 3. Create initial structure
mkdir -p apps/app_mobile apps/app_web packages/{core,shared_ui,network}

# 4. Create melos.yaml, pubspec.yaml, analysis_options.yaml

# 5. Bootstrap all packages
melos bootstrap

# 6. Generate new Flutter apps in correct locations
cd apps/app_mobile
flutter create --platforms=android,ios .

cd ../app_web
flutter create --platforms=web .
```

---

## ✅ Final Decision Matrix

| Factor | Monorepo | Separate Repos |
|--------|----------|----------------|
| **Code Reuse** | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **Easy Maintenance** | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **CI/CD Simplicity** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Version Management** | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **Team Independence** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Git Performance** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Access Control** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Onboarding** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

### **Score: Monorepo = 36/40, Separate = 28/40**

**✅ RECOMMENDATION: MONOREPO**

---

## 📖 References

- [Flutter Monorepo Docs](https://docs.flutter.dev/development/packages-and-plugins/developing-packages#organizing-packages-in-a-mono-repository)
- [Melos - Monorepo Manager](https://melos.invertase.dev/)
- [Very Good Ventures - Monorepo Article](https://verygood.ventures/blog/very-good-blog/monorepo-and-flutter)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture)
- [Riverpod Documentation](https://riverpod.dev/)

---

**Ready to implement? Start with Melos setup and build out the package structure!** 🚀
