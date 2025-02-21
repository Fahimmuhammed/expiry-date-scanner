# expiry_date_scanner

The Expiry Date Scanner is a Flutter-based mobile application designed to scan product expiry dates using OCR technology and inform users whether the product is safe to consume. The app utilizes Text-to-Speech (TTS) for enhanced accessibility, making it easier for users to receive expiry notifications audibly. The project is developed with a clean architecture pattern, ensuring a clear separation of concerns and maintainable code structure.

Features:

1. OCR (Optical Character Recognition): 
 - Extracts dates from product images using Google ML Kit.
 - Supports multiple date formats (DD/MM/YYYY, MM/DD/YYYY, YYYY/MM/DD).
 - Flexible date extraction with user-selected formats.

2. Expiry Date Validation
 - Checks if the extracted date is expired, approaching expiry, or safe to consume.
 - Displays expiry status with color-coded indicators:
    🟢 Green: Safe to consume (More than 7 days left).
    🟡 Yellow: Approaching expiry (Less than 7 days left).
    🔴 Red: Expired.

3. Scan History
 - Stores scanned products locally using Hive for offline access.
 - Lists all scanned products with expiry status and days remaining.

4. Text-to-Speech (TTS)
 - Reads out expiry status and product details for accessibility.
 - Utilizes Flutter TTS package for smooth voice output.

5. Voice Commands
 - Start and stop voice commands for hands-free scanning.
 - Recognizes keywords like "scan" and "pick" for seamless interaction.
 
6. Dark Mode Support
 - Toggle between light and dark themes using Riverpod for state management.

7. Lottie Animations
 - Utilizes Lottie animations for interactive loading indicators, enhancing user experience.

Folder Structure & Separation of Concerns:

lib/
│
├── assets/                
│   ├── animations/
│   │   └── loader.json
│   └── lang/
│       ├── ar-SA.json
│       └── en-US.json
│
├── core/                   
│   ├── services/            
│   │   ├── ocr_service.dart
│   │   └── tts_service.dart
│   └── route.dart
│
├── data/                  
│   ├── datasources/        
│   ├── models/             
│   └── repo/               
│
├── domain/                
│   ├── entities/           
│   ├── repo/               
│   └── usecases/           
│
├── ui/                    
│   ├── pages/              
│   │   ├── history_page.dart
│   │   ├── home_page.dart
│   │   └── scan_page.dart
│   │
│   ├── providers/          
│   │   ├── scan_provider.dart
│   │   └── theme_provider.dart
│   │
│   └── widgets/            
│       └── loader.dart
│
├── di.dart                 
└── main.dart               


Why This Structure?

1. Clean Separation of Concerns:
    - data/: Handles data sources, including Hive local storage.
    - domain/: Contains pure business logic, independent of Flutter.
    - ui/: Manages presentation logic using Riverpod for state management.

2. Maintainability: Well-organized structure facilitates easy maintenance and scalability.

3. Testability: Decoupled layers make it easier to write unit tests for business logic and data handling.



Implementation Details:

1. OCR Integration
    - ML Kit is integrated using the google_ml_kit package for accurate date extraction.
    - Date formats are normalized to handle multiple formats consistently.

2. State Management with Riverpod

    - Riverpod is used for managing the state of scanned data and theme settings.
    - StateNotifierProvider efficiently updates UI components when state changes.

3. Local Persistence with Hive
    - Scanned products are saved locally using Hive with models stored in data/models.
    - ScanHistoryModel is used for saving and retrieving scan history.

4. Voice Commands and TTS
    - TTS: Reads out expiry status and product details using flutter_tts.
    - Voice Commands: Implemented with speech_to_text for hands-free scanning.

5. Dark Mode Support
    - Utilizes StateNotifierProvider to toggle between light and dark themes.
    - The theme state is persisted using Hive, ensuring consistency across app restarts.

6. Lottie Animations
    - Enhances user experience with interactive loading indicators.
    - Integrated in scan_page.dart for a modern and appealing UI.


Project Setup & Dependencies:

Requirements:
    - Flutter SDK: >=3.0.0
    - Dart SDK: >=2.17.0

Running the App:
    - flutter run

Build the APK:
    - flutter build apk --release


License
    - This project is licensed under the MIT License. See the LICENSE file for details.

Contact
    - For questions or support, please contact @ Fahim.mdh7@gmail.com.








## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
