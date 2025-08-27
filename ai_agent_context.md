# AI Agent Context: Simple Messaging App (Android)

## App Overview
- Platform: Android (Flutter)
- Purpose: Simple messaging app with QR-based chat room connection

## Minimum Working Version Features
1. Screens / Flow
   - Profile Setup Screen (First Launch)
     - Requires user to enter a username and select a profile picture
     - Shown only on first launch or when editing profile
   - Home Screen
     - Shows a list of people you have initiated chats with (recent chats)
     - Floating + button at bottom right to start a new chat
     - Settings icon/button to access Settings screen
   - Settings Screen
     - Allows user to change username and profile picture
     - Accessible from Home Screen
   - New Chat Screen
     - Option to scan a QR code (to join a chat)
     - Option to generate a QR code (to create a new chat)
     - Navigates to appropriate QR Code or Scanner screen
   - QR Code Screen
     - Displays your unique session ID as a QR code
   - QR Code Scanner Screen
     - Opens camera to scan another user's QR code
   - Chat Screen
     - Shows messages in bubbles (yours right, theirs left)
     - Text input box + send button
     - Messages stored in SQLite for persistence

2. Features
   - QR Code Generation: Use qr_flutter package
   - QR Code Scanning: Use qr_code_scanner or mobile_scanner
   - Connection: Firebase Realtime Database; scan QR to join chat room
   - Messaging: Messages stored in DB, Flutter listens for changes, updates UI
   - Persistence: Local history with sqflite (messages synced locally)

## Profile System (Simple)
- Each user has a local profile: username (display name), optional profile picture
- No authentication required (minimum version)
- Profile created/edited on first launch or via menu
- Profile data stored locally (SharedPreferences or SQLite)
- Profile info sent to chat room in Firebase when joining/starting chat
- Other user sees your profile in chat header or message bubbles
- UI: Show own profile on home screen or drawer; show other user’s profile in chat


# Proposed SQLite Database Structure

## Tables

1. user_profile
  - id (INTEGER PRIMARY KEY AUTOINCREMENT)
  - username (TEXT)
  - profile_picture (TEXT)  # Path or base64 string

2. contacts
  - id (INTEGER PRIMARY KEY AUTOINCREMENT)
  - username (TEXT)
  - profile_picture (TEXT)
  - contact_id (TEXT)  # Unique identifier from QR

3. chat_rooms
  - id (INTEGER PRIMARY KEY AUTOINCREMENT)
  - room_id (TEXT)  # Unique chat room identifier
  - contact_id (TEXT)  # Foreign key to contacts
  - last_message (TEXT)
  - last_updated (INTEGER)  # Timestamp

4. messages
  - id (INTEGER PRIMARY KEY AUTOINCREMENT)
  - room_id (TEXT)  # Foreign key to chat_rooms
  - sender_id (TEXT)  # Could be 'self' or contact_id
  - content (TEXT)
  - timestamp (INTEGER)

This structure supports local profile, contacts, chat rooms, and messages for the minimum working version.

# Proposed Firebase Realtime Database Structure

## Root Structure (JSON)

```
chat_rooms: {
  [room_id]: {
    participants: {
      [user_id]: {
        username: string,
        profile_picture: string  // URL or base64
      },
      ...
    },
    messages: {
      [message_id]: {
        sender_id: string,
        content: string,
        timestamp: integer
      },
      ...
    },
    last_message: string,
    last_updated: integer  // Timestamp
  },
  ...
}

users: {
  [user_id]: {
    username: string,
    profile_picture: string  // URL or base64
  },
  ...
}
```

## Notes
- `chat_rooms` contains all chat sessions, each with participants and messages.
- `participants` holds minimal profile info for each user in the room.
- `messages` is a map of message objects for the room.
- `users` is a global directory of user profiles (optional for minimum version, but useful for future features).
- Only shared data (chat rooms, messages, and minimal profile info) is stored in Firebase.

## Suggested File Structure

```
lib/
  main.dart
  firebase_options.dart
  screens/
    profile_setup_screen.dart
    home_screen.dart
    settings_screen.dart
    new_chat_screen.dart
    qr_code_screen.dart
    qr_scanner_screen.dart
    chat_screen.dart
  widgets/
    chat_bubble.dart
    user_avatar.dart
    chat_list_tile.dart
    profile_form.dart
  models/
    user_profile.dart
    chat_message.dart
    chat_room.dart
  services/
    firebase_service.dart
    local_db_service.dart
    qr_service.dart
    profile_service.dart
  utils/
    validators.dart
    constants.dart
```

## Future Tasks (for AI agents)
- Implement Home, QR Code, and Chat screens
- Integrate QR code generation and scanning
- Set up Firebase Realtime Database for chat rooms
- Implement local SQLite storage for messages
- Add simple profile creation/editing and local storage
- Sync profile info to chat room and display in UI
- Ensure all features work for Android target

## Theme (Design System)

This app uses a simple, consistent dark theme. Keep UI-only changes within these constraints; do not alter underlying logic.

- Mode: Dark only (ThemeMode.dark)
- Palette:
  - Background: very blackish dark blue `#0A0F1A`
  - Surface/Card: slightly lighter dark blue `#0E1624`
  - Primary accent: light blue `#90CAF9`
  - Secondary accent: light blue `#64B5F6`
- Typography: Hepta Slab (global app font)
- Shape: All rounded corners are 32 px radius for cards, dialogs, buttons, inputs, lists
- Components:
  - AppBar: centered title, surface color, no elevation
  - Cards/List tiles: use Card with 32 px radius; subtle dividers
  - Buttons: Filled/Elevated/Outlined/Text use 32 px radius and accent colors
  - Inputs: OutlineInputBorder with 32 px radius; filled on dark background
  - FAB: primary accent background with dark text/icon
- Accessibility: Prefer high-contrast text (onSurface/onBackground are light on dark)

Recent UI updates applied:
- Home screen
  - Added empty state with icon and CTA
  - Switched to Card-based chat items with chevron and initial avatar
  - Swipe-to-delete uses theme error color background
  - AppBar title centered; typography is from global font
- Global
  - Dark palette and 32 px radii applied via ThemeData
  - Hepta Slab wired as default text theme
