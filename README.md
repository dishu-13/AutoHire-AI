<div align="center">
  <h1>🚀 AutoHire AI</h1>
  <p><strong>A Next-Generation AI-Powered Job Discovery & Resume Tailoring Assistant</strong></p>

  ![Flutter Version](https://img.shields.io/badge/Flutter-%E2%89%A53.6.0-02569B?logo=flutter&logoColor=white)
  ![Dart Version](https://img.shields.io/badge/Dart-%E2%89%A53.0.0-0175C2?logo=dart&logoColor=white)
  ![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
  ![Firebase](https://img.shields.io/badge/Firebase-Integrated-FFCA28?logo=firebase&logoColor=black)
</div>

---

**AutoHire AI** is a production-ready, full-stack Flutter application designed to revolutionize the job search experience. It combines real-time job discovery, local AI-driven resume tailoring, and comprehensive application tracking into a single, beautifully designed platform.

## ✨ Key Features

- 🔍 **Smart Job Discovery**
  - Live API integration for remote and local jobs.
  - Advanced search suggestions, role-based filtering, and detailed job views.
  - Save your favorite jobs and apply directly through external links.

- 🤖 **AI-Powered Resume Tailoring**
  - Paste or upload `.txt` files to analyze your current resume.
  - Built-in **local ATS tailoring** provides real-time suggestions and improvements.
  - Export your newly polished, highly-targeted resume as a beautiful PDF.

- 📊 **Application Tracking Dashboard**
  - Keep track of saved, applied, and interviewed jobs in one central hub.
  - View success-rate analytics and an intuitive timeline of your applications.
  - Never lose track of where you stand in the interview process.

- 👤 **Seamless Profile Management**
  - Fast, secure authentication powered by Firebase.
  - Dedicated resume editor and robust settings.
  - Modern UI with a stunning Dark Mode experience.

## 🛠 Tech Stack & Architecture

- **Frontend:** Flutter & Dart (Material 3 UI implementation)
- **State Management:** `provider` using `AppState` as a centralized, reactive store.
- **Backend & Database:** Firebase Authentication & Cloud Firestore (Optimized for the no-cost Spark tier).
- **APIs:** Live public Job APIs integrated through custom service layers.
- **CI/CD:** Fully automated GitHub Actions workflow that builds and releases the Android APK on every push.

## 🚀 Installation & Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/dishu-13/AutoHire-AI.git
   cd AutoHire-AI
   ```
2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the App:**
   ```bash
   flutter run
   ```

*Note: Ensure you have an Android Emulator running or a physical Android device connected.*

## 📚 Documentation

Dive deeper into the architecture and setup by reading our comprehensive guides located in the `docs/` folder:

- 🔗 [`api_integration_guide.md`](docs/api_integration_guide.md) - Learn how we fetch live jobs.
- 🔥 [`firebase_setup.md`](docs/firebase_setup.md) - Steps to configure the Firebase backend.
- 🏗 [`production_architecture.md`](docs/production_architecture.md) - Deep dive into our state management and services.
- ⚙️ [`run_and_build_guide.md`](docs/run_and_build_guide.md) - Advanced build instructions for production.

## 🤖 CI/CD Automation

This repository is equipped with **GitHub Actions**. Every time code is pushed to the `main` branch, our pipeline automatically:
1. Sets up Java 17 and Flutter stable.
2. Fetches dependencies and builds a release-ready Android APK.
3. Uploads the fresh `.apk` directly to the **[GitHub Releases](https://github.com/dishu-13/AutoHire-AI/releases)** page under the "Latest Build" tag.

---

<div align="center">
  <i>Built with ❤️ using Flutter and Firebase</i>
</div>
