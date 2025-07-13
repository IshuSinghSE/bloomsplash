# Copilot Instructions for BloomSplash

## Project Overview
BloomSplash is a modular Flutter app for wallpaper management, leveraging Appwrite (image storage, metadata), Firebase (auth, notifications, analytics), and Cloudflare (CDN). The architecture is designed for scalability, maintainability, and global performance.

## Key Architectural Patterns
- **Modular Structure:**
  - `lib/core/`: Generic utilities, themes, constants, error handling. Avoid app-specific logic here.
  - `lib/app/`: App-specific providers (state management), services (Firebase, API clients), routing, and constants.
  - `lib/features/`: Feature-specific code (screens, widgets, logic) organized by functionality (e.g., `home/`, `favorites/`, `upload/`).
  - `lib/models/`: Data models (e.g., `Wallpaper`, `User`) with `toJson`/`fromJson` for serialization.
- **Centralized Imports:** Use `export` files (e.g., `core/themes/themes.dart`) to simplify imports across modules.
- **Platform Support:** Multi-platform code in `android/`, `ios/`, `web/`, etc.

## Developer Workflows
- **Build:**
  - Use standard Flutter build commands (`flutter build <platform>`).
  - For Android, use Gradle scripts in `android/`.
- **Test:**
  - Run tests with `flutter test` or use the VS Code task: `mvn -B test` (for backend/Java components).
  - Tests are in `test/` and may cover unit, widget, and integration scenarios.
- **Debug:**
  - Use Flutter's built-in debugging tools and platform-specific scripts.
- **Release:**
  - Firebase App Distribution and Crashlytics are integrated for release and monitoring.

## Integration Points
- **Appwrite:** Handles wallpaper storage and metadata. API endpoints/configs are in `core/constants/` or `app/services/`.
- **Firebase:** Used for authentication, notifications, analytics, and performance. Service logic is in `app/services/`.
- **Cloudflare:** CDN for image delivery; configuration is external but referenced in documentation.

## Project-Specific Conventions
- **High-Quality Content:** Only original, high-quality wallpapers should be uploaded.
- **Feature Organization:** New features go in their own folder under `features/`.
- **Utility Reuse:** Shared utilities belong in `core/utils/`.
- **Model Serialization:** All models implement `toJson`/`fromJson`.
- **Centralized Routing:** Navigation logic is in `app/routes/app_routes.dart`.

## Example Patterns
- To add a new theme, update `core/themes/` and export via `themes.dart`.
- To add a new provider, place it in `app/providers/`.
- To add a new feature, create a folder in `features/` and include all related code.

## References
- See `README.md` for folder structure and architecture rationale.
- Key files: `lib/app.dart`, `lib/main.dart`, `lib/app/core/`, `lib/app/features/`, `lib/app/models/`, `android/`, `ios/`, `test/`.

---

If any conventions or workflows are unclear or missing, please provide feedback to improve these instructions.
