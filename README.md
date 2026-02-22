# Aye Aye Captain

AI overlay assistant that reads screen content and explains via chat bubble.

## Features

This application is a Flutter application for Android that functions as a floating chat overlay. It has the following capabilities:
- A floating chat overlay that stays on top of other apps.
- Ability to read the content of the current screen using the Accessibility Service.
- Allows the user to ask questions about the current screen context.
- Uses `google_generative_ai` to send the context and question to an LLM.
- Displays the AI's response inside the chat overlay.

## Getting Started

To get started with this project:

1. Clone the repository.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
