# Playbook

Playbook is a modern, responsive, and feature-rich Flutter application designed for managing interactive AI roleplay characters, world lore (World Books), and chat conversations. It offers full customization for API configurations, allowing you to connect to any OpenAI-compatible API endpoints.

[English](./README.md) | [简体中文](./README.zh-CN.md)

---

## Key Features

- 🎭 **Character Creator & Editor**: Easily build, configure, and customize characters. Define their name, avatar, personality descriptions, prompt contexts, first messages, and system instructions.
- 📚 **World Book (Lore) Management**: Create and manage world lore entries, terms, and backgrounds. Let your characters reference background information dynamically during conversations.
- 💬 **Interactive Chat Room**:
  - Immersive dialogue interface supporting full **Markdown** rendering.
  - Interactive input box with token estimation and real-time validation.
  - Multi-session management with historical chat threads.
- ⚙️ **Custom API Configuration**: Set up custom API endpoints (OpenAI-compatible), custom model names, API keys, temperature, and maximum token outputs.
- 🎨 **Modern & Adaptive UI**:
  - Material 3 Design with **Dynamic Color** theming (syncs with OS accent color).
  - Fully supports **Dark Mode** and Light Mode.
  - **Responsive Layout**: Seamlessly transitions between Mobile (navigation bar) and Desktop (collapsed/expanded sidebar layout).
- 💾 **Data Independence & Portability**: Export your entire database (characters, world books, chat histories, settings) to a single file, or import it back anytime.
- 📡 **Offline Monitoring**: Real-time connection checker with offline banner warning to ensure stable API requests.

---

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.12.0)
- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc) (BLoC pattern)
- **Database**: [sqflite](https://pub.dev/packages/sqflite) (with FFI support on Desktop & Web)
- **Dependency Injection**: [get_it](https://pub.dev/packages/get_it) & [injectable](https://pub.dev/packages/injectable)
- **Routing**: [go_router](https://pub.dev/packages/go_router)
- **Networking**: [dio](https://pub.dev/packages/dio)
- **Theme**: [dynamic_color](https://pub.dev/packages/dynamic_color)
- **Rich Text Rendering**: [flutter_markdown](https://pub.dev/packages/flutter_markdown)

---

## Getting Started

### Prerequisites

Make sure you have [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your system (stable channel recommended).

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/tylevnovik/playbook.git
   cd playbook
   ```

2. **Get dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run code generation**:
   This project uses `build_runner` and `injectable` for dependency injection and serialization. Run the following command to generate the required configuration files:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application**:
   - Run on connected device (Mobile, Desktop, or Web):
     ```bash
     flutter run
     ```
   - For Release build:
     ```bash
     flutter build apk  # For Android APK
     flutter build windows  # For Windows Desktop
     flutter build web  # For Web app
     ```

---

## Project Structure

```text
lib/
├── app.dart                               # Main Application entry widget
├── main.dart                              # App entry main() function
├── core/                                  # Common/Core modules
│   ├── constants/                         # Global constants & key mapping
│   ├── di/                                # Dependency injection setup (injectable)
│   ├── error/                             # Failure and exception definitions
│   ├── localization/                      # Multi-language l10n logic
│   ├── theme/                             # ThemeData & color palettes
│   └── utils/                             # Helpers (Token Estimator, File Saver, Connection Checker)
├── data/                                  # Data layer implementation
│   ├── datasources/                       # Local DB, SharedPreferences, API export services
│   ├── models/                            # Data models & serializations
│   └── repositories/                      # Repository implementations
├── domain/                                # Domain layer (interfaces & core models)
│   ├── models/                            # Plain entity classes (Character, Chat, WorldBook)
│   └── repositories/                      # Repository abstract contracts
└── presentation/                          # Presentation layer (UI & state)
    ├── common/                            # Common widgets (Responsive, Sidebar, Scaffolds)
    ├── router/                            # Routing configuration (go_router)
    └── features/                          # Feature blocks
        ├── character/                     # Character Creator/Edit page and BLoC
        ├── chat/                          # Chat Interface, Bubble, Input, and BLoC
        ├── home/                          # Home screen Grid and BLoC
        ├── settings/                      # Config panel, Theme/Data settings, and BLoC
        └── splash/                        # Splash loading page
```

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.
