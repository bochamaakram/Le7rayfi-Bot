# Le7rayfi Bot — Native Flutter Application 📱🤖

Application mobile native Flutter pour **le7raifiBot Mini V1**, conçue pour résoudre définitivement les limitations du navigateur Web / PWA sur smartphone Android et iOS :
- **NFC Natif 100% fiable** (Lecture & Écriture de tags NDEF) via `nfc_manager`
- **Voice Chat Natif** (Reconnaissance vocale Speech-to-Text en Darija, Arabe et Français) via `speech_to_text`
- **Lecteur Vocal (TTS Reader)** (Synthèse vocale locale pour écouter les réponses et fiches artisans) via `flutter_tts`
- **Scanner QR Natif** (Caméra haute vitesse avec Google ML Kit) via `mobile_scanner`
- **Générateur QR** via `qr_flutter`
- **Moteur de réponses locales 100% Hors-ligne** (`assets/knowledge.json`)
- **Visage de robot animé interactif** (clignement aléatoire, pupilles qui suivent le toucher, synchronisation labiale et humeurs réactives)

---

## 🚀 Démarrage Rapide

### 1. Lancer l'application en mode développement
```bash
cd hraifibot_app
flutter run
```

### 2. Compiler l'APK Android
```bash
flutter build apk --debug
```
L'APK généré sera disponible dans :
`build/app/outputs/flutter-apk/app-debug.apk`

Pour l'installer directement sur votre smartphone connecté en USB :
```bash
flutter install
# ou
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## 🌟 Fonctionnalités Matérielles Natives

| Fonction | PWA Web d'origine | Application Flutter Native |
|---|---|---|
| **Lecture NFC** | Chrome Android uniquement (Web NFC) | **Natif Android & iOS** via NDEF Manager |
| **Écriture NFC** | Chrome Android uniquement | **Natif Android & iOS** (Écrit l'URL et l'ID artisan) |
| **Reconnaissance Vocale (Voice Chat)** | `webkitSpeechRecognition` (expérimental/serveur Chrome) | **Moteur SpeechRecognizer natif** de l'OS avec support hors-ligne |
| **Lecteur Vocal (TTS Reader)** | `speechSynthesis` navigateur (voix aléatoires) | **Android Text-To-Speech natif** avec contrôle de pitch, vitesse et voix arabes |
| **Scanner QR (Reader)** | WebRTC HTML5 (permissions complexes) | **Google ML Kit Barcode Scanner** instantané (sans latence) |
| **Affichage QR** | Images statiques | **Générateur vectoriel dynamique** (`qr_flutter`) |

---

## 📁 Architecture du Code

```
hraifibot_app/
├── assets/
│   ├── knowledge.json          # Base de connaissances locale (85 fiches FR/AR/Darija)
│   ├── icon-192.png
│   └── icon-512.png
├── lib/
│   ├── models/
│   │   ├── knowledge_item.dart  # Modèle des questions & réponses locales
│   │   ├── artisan_profile.dart # Fiches artisans de démonstration (ART-DEMO-01, etc.)
│   │   └── chat_message.dart    # Historique de discussion
│   ├── services/
│   │   ├── localization_service.dart # Système trilingue (FR, AR, Darija) avec support RTL
│   │   ├── knowledge_service.dart    # Recherche floue, tokenisation et suggestions
│   │   ├── nfc_service.dart          # Lecture/Écriture NFC native (Android NdefAndroid + iOS NdefIos)
│   │   └── voice_service.dart        # STT (Microphone) + TTS (Lecteur vocal)
│   ├── widgets/
│   │   ├── robot_face.dart           # Visage de robot animé (clignement, suivi, bouche)
│   │   ├── voice_control_bar.dart    # Bouton micro lumineux + statut + annulation
│   │   ├── nfc_action_sheet.dart     # Modal radar pour lecture/écriture NFC
│   │   ├── qr_scanner_sheet.dart     # Scanner caméra Google ML Kit
│   │   ├── qr_display_sheet.dart     # Affichage des codes QR
│   │   ├── artisan_card_sheet.dart   # Fiche artisan avec bouton "Écouter la fiche"
│   │   └── quick_suggestion_chips.dart # Puces de questions rapides
│   ├── screens/
│   │   └── home_screen.dart          # Écran principal complet
│   └── main.dart                     # Configuration du thème sombre et police Tajawal
└── pubspec.yaml
```

---

## 🔒 Permissions Android incluses

Le fichier `android/app/src/main/AndroidManifest.xml` est déjà configuré avec :
- `android.permission.NFC`
- `android.permission.RECORD_AUDIO`
- `android.permission.CAMERA`
- `android.permission.VIBRATE`
- Intent query pour `android.speech.RecognitionService`
