
# BloomSplash

<p align="center">
  <a href="https://bloomsplash.app" target="_blank"><img src="https://img.shields.io/badge/Website-BloomSplash-blue?style=for-the-badge" alt="Website"></a>
  <a href="https://play.google.com/store/apps/details?id=com.devindeed.bloomsplash" target="_blank"><img src="https://img.shields.io/badge/Play%20Store-Download-green?style=for-the-badge&logo=google-play" alt="Play Store"></a>
  <a href="https://github.com/IshuSinghSE/bloomsplash/releases" target="_blank"><img src="https://img.shields.io/badge/GitHub-Releases-black?style=for-the-badge&logo=github" alt="GitHub Releases"></a>
</p>

---

## Overview

BloomSplash is a modular, multi-platform wallpaper app built for performance, scalability, and maintainability. It leverages Appwrite, Firebase, and Cloudflare for a robust backend and global delivery.

**Links for Collaborators:**
- [Website](https://bloomsplash.app)
- [Play Store](https://play.google.com/store/apps/details?id=com.devindeed.bloomsplash)
- [GitHub Releases](https://github.com/IshuSinghSE/bloomsplash/releases) *(private repo access required)*

---

## Architecture Plan

**Appwrite:**
- Wallpaper image storage (safe, scalable, free)
- Wallpaper metadata (Database)
- Future functions (e.g. moderation, approval, API logic)

**Firebase:**
- Authentication (Google, Apple, etc.)
- Notifications (FCM)
- Analytics, Performance, Crashlytics
- Release & app distribution (if using Firebase App Distribution)

**Cloudflare CDN:**
- Serve wallpaper images globally with low latency and high reliability.

---

## Rules
1. Always ensure high-quality and original content is uploaded.

---

# Project Folder Structure

This project follows a modular folder structure to ensure scalability and maintainability. Below is an overview of the key folders and their purposes:

## Folder Structure

#### `app/`

### **1. `core` Folder**
- **Themes and Styles:**
  - Colors, typography, and other design-related constants.
  - Example: app_colors.dart, `core/themes/app_text_styles.dart`.

- **Utilities:**
  - Helper functions, extensions, and reusable logic.
  - Example: `core/utils/utils.dart`.

- **Constants:**
  - Static configurations, such as API endpoints, asset paths, or app-wide constants.
  - Example: config.dart.

- **Error Handling:**
  - Custom error classes or global error handlers.

### **2. `app` Folder**
- **Providers:**
  - State management logic using `Provider`, `Riverpod`, or any other state management library.
  - Example: favorites_provider.dart, `app/providers/auth_provider.dart`.

- **Services:**
  - Firebase services, API clients, or other backend-related logic.
  - Example: firebase_firestore_service.dart, `app/services/firebase_storage_service.dart`.

- **Constants:**
  - App-specific constants, such as dummy data or localized strings.
  - Example: data.dart.

- **Routing:**
  - Centralized routing logic for navigation between screens.
  - Example: `app/routes/app_routes.dart`.


### **How to Use Both Folders Together**
The `core` folder provides foundational utilities and configurations, while the `app` folder handles app-specific logic. Here's an example of how they work together:


### **Best Practices**
1. **Keep `core` Generic:**
   - Avoid adding app-specific logic to `core`. It should only contain reusable and generic utilities.

2. **Use `app` for App-Specific Logic:**
   - Place app-specific logic, such as providers and services, in the `app` folder.

3. **Organize by Feature:**
   - For feature-specific code (e.g., screens, widgets, models), create separate folders under `features`.

4. **Centralize Imports:**
   - Use `export` files to simplify imports. For example:
     ```dart
     // filepath: core/themes/themes.dart
     export 'app_colors.dart';
     export 'app_text_styles.dart';
     ```

     Then, import all themes with:
     ```dart
     import 'package:your_project_name/core/themes/themes.dart';
     ```

---

#### `features/`
Contains feature-specific code, organized by functionality.
- **`home/`**: Code related to the home screen.
- **`favorites/`**: Code for managing and displaying favorite wallpapers.
- **`upload/`**: Code for uploading wallpapers.
- **`settings/`**: Code for the settings page.
- **`wallpaper_details/`**: Code for displaying wallpaper details.

#### `models/`
Defines data models used throughout the app, such as `Wallpaper`, `Collection`, and `User`.

## Additional Folders
### `assets/`
Holds static assets such as images, icons, and fonts.

### `test/`
Contains unit and widget tests for the app.

### `web/`, `windows/`, `macos/`, `linux/`, `android/`, `ios/`
Platform-specific code for Flutter's multi-platform support.

## Example Usage

- **Adding a new feature**: Create a new folder under `features/` and include all related screens, widgets, and logic.
- **Reusing a utility**: Add it to `core/utils/` for shared usage across the app.
- **Defining a new model**: Add it to `models/` and ensure it includes `toJson` and `fromJson` methods for serialization.

This structure ensures a clean separation of concerns and makes the app easy to navigate and extend.
