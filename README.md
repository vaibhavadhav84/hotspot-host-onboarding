# assignment_app

# Onboarding Questionnaire for Hotspot Hosts  
**Flutter Internship Assignment – 8Club**

---

## Overview
This Flutter project is developed as part of the internship assignment for **8Club**.  
The application provides a two-step onboarding experience for *Hotspot Hosts* who wish to manage social gatherings and events.  
It ensures that hosts meet the platform's standards through an experience selection questionnaire and personal motivation recording process.

---

## Features Implemented

### 1. Experience Selection Screen
- Fetches a list of experiences from the API:  
  `https://staging.chamberofsecrets.8club.co/v1/experiences?active=true`
- Displays each experience as a card with its image as background.
- Unselected state shows grayscale image.
- Multiple card selection supported.
- Multi-line text field with 250 character limit.
- Stores selected experience IDs and description in state.
- Logs the data and navigates to the next screen.
- Figma-inspired clean dark UI with responsive layout.

### 2. Onboarding Question Screen
- Multi-line text field with 600 character limit.
- Audio recording support with real-time waveform visualization.
- Cancel and delete options for recorded audio.
- Video recording support using the device camera.
- Delete option for recorded video.
- Record buttons disappear once media is recorded.
- Animated "Next" button width transition.
- Responsive dark UI design with SafeArea handling.
- Navigates to success submission screen after completion.

### 3. Success Submission Screen
- Confirms the completion of the onboarding questionnaire.
- Displays a success message and provides navigation back to the home page.

---

## Brownie Points Achieved
- Implemented **Dio** for API management.  
- Used **Riverpod** for efficient state management.  
- Achieved a **pixel-perfect dark UI** based on Figma references.  
- Added **Next button width animation** on dynamic layout change.  
- Implemented **audio waveform visualization** during recording.  
- Designed **scalable folder structure** for maintainability.

---

## Folder Structure
lib/
┣ models/
┃ ┗ experience_model.dart
┣ services/
┃ ┗ api_service.dart
┣ providers/
┃ ┗ experience_provider.dart
┣ screens/
┃ ┣ experience_selection_screen.dart
┃ ┣ onboarding_question_screen.dart
┃ ┗ success_submission_screen.dart
┣ widgets/
┃ ┣ experience_card.dart
┃ ┗ audio_recorder_widget.dart
┣ utils/
┃ ┗ theme.dart
┗ main.dart

---

##  State Management
Implemented using **Riverpod** for scalability and clean separation of concerns.

---

##  Packages Used
| Package | Purpose |
|----------|----------|
| `dio` | API integration |
| `flutter_riverpod` | State management |
| `flutter_sound` | Audio recording |
| `camera` | Video recording |
| `path_provider` | File path management |
| `permission_handler` | Runtime permissions |
| `video_player` | (Optional playback) Video preview |

---
##  Demo
Attach a short screen recording showcasing:
1. Fetching experiences  
2. Selecting and deselecting cards  
3. Writing in the text field  
4. Navigating to next page  
5. Recording and deleting audio/video  
6. Animated Next button  
---

##  Developed By
**Vaibhav Adhav**  
Email: vaibhavadhav98@gmail.com  
LinkedIn: [linkedin.com/in/vaibhavadhav84](https://linkedin.com/in/vaibhavadhav84)

---
