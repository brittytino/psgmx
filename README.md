# 🎓 PSGMX - Placement Excellence Program

<div align="center">

  ![PSGMX Logo](assets/images/psgmx_logo.png)

  > **A mature, closed-community placement preparation ecosystem for PSG Technology - MCA.**
  
  <br>

  [![Version](https://img.shields.io/badge/version-4.0.0-blue.svg)](pubspec.yaml)
  [![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
  [![Supabase](https://img.shields.io/badge/Supabase-Production-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
  [![Firebase](https://img.shields.io/badge/Hosting-Firebase-FFCA28?logo=firebase&logoColor=white)](https://firebase.google.com)
  [![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

</div>

---

## 📖 Overview

**PSGMX** is an enterprise-grade academic management platform architected to streamline the placement lifecycle for MCA students. Version 4.0.0 introduces a fully dynamic architecture that auto-scales across multiple batches, replacing static configurations with dynamic rules. 

Built with **Flutter** for a responsive cross-platform experience and **Supabase** for robust real-time backend services, it demonstrates a modern, scalable approach to educational software.

---

## ✨ Key Features (v4.0.0)

### 🚀 **Dynamic Batch System**
- **Zero Whitelists:** Students are automatically assigned to the correct academic batch based on their roll numbers upon first sign-in.
- **Automated Lifecycle:** Seamless transitions for graduating classes and onboarding juniors, retaining historical Placement Logs automatically.

### 📈 **Readiness Scoring & Attendance**
- **Placement-Specific Attendance:** Track engagement in specialized placement classes separately from official academic attendance.
- **Readiness Score Engine:** A real-time, algorithmic score combining LeetCode momentum, Placement Attendance, Daily Five streaks, and Task completions.

### 🧠 **AI Mentor & Daily Five Engine**
- **Daily Five Quizzes:** A 5-question daily technical quiz with streak tracking, freeze tokens, and anti-cheat mechanisms.
- **AI Mentorship:** Integrated OpenRouter AI for real-time explanations of incorrect answers and simulated mock interviews.

### 🏢 **Placement Logs & Knowledge Sharing**
- **Chronological Drive Tracking:** Comprehensive company visit logs, package bands, and eligibility criteria.
- **Peer Experience Sharing:** Second-year students document specific round-by-round experiences to preserve knowledge for the junior batch.

### 👨‍🎓 **Student Hub & Core Features**
- **Live LeetCode Analytics:** Automatic profile syncing and unified dashboard.
- **Dynamic Team Management:** Reps can instantly scale and distribute students into teams of customizable sizes.
- **Role-Based Access Control (RBAC):** Granular permission flags (e.g., `schedule_placement_sessions`, `manage_company_records`) rather than rigid roles.

---

## 🛠️ Tech Stack & Architecture

| Layer | Technologies | Description |
| :--- | :--- | :--- |
| **Frontend** | Flutter 3.27+ | Material 3 Design, Responsive Layouts (Web/Mobile) |
| **State Management** | Provider | MultiProvider architecture scaling across 15+ complex models |
| **Backend** | Supabase | PostgreSQL Database, Auth, Realtime APIs, RLS Policies |
| **Hosting** | Firebase | Global CDN hosting for the Web App |
| **AI Layer** | OpenRouter | Fallback-chain LLM integration for the AI Mentor |

---

## 🚀 Getting Started

### Prerequisites
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.27 or higher)
*   A Supabase Project (Free Tier works)

### Installation

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/brittytino/psgmx-flutter.git
    cd psgmx-flutter
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Environment Setup**
    Create a `.env.flutter` file in the project root:
    ```env
    SUPABASE_URL=your_supabase_project_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    ```

4.  **Database Initialization**
    Run the SQL scripts located in `database/` inside your Supabase SQL Editor to provision the schema, RLS policies, and triggers. Check `database/README.md` for execution order.

5.  **Run the Application**
    ```bash
    flutter run --dart-define-from-file=.env.flutter
    ```

---

## 🤝 Contributing

Contributions are welcome from the active batches!

1.  **Fork** the project.
2.  **Create** your feature branch (`git checkout -b feature/AmazingFeature`).
3.  **Commit** your changes (`git commit -m 'Add some AmazingFeature'`).
4.  **Push** to the branch (`git push origin feature/AmazingFeature`).
5.  **Open** a Pull Request.

Please ensure your code passes `flutter analyze` before submitting.

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

  **Maintained by Tino Britty J**
  <br>
  [GitHub](https://github.com/brittytino) • [Portfolio](https://tinobritty.me)
  
  *Made with ❤️ for PSG Tech MCA*

</div>
