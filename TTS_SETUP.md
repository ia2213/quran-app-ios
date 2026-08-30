# Quran App - TTS Server Setup

## Démarrer le serveur TTS

```bash
# Depuis le répertoire du projet
"/c/Users/Marc Hopf/AppData/Local/hermes/hermes-agent/venv/Scripts/python.exe" tts_server.py 8766
```

Ou double-cliquez sur `start_tts.bat`.

## Configurer l'IP du serveur

Si votre IP a changé, modifiez la ligne 16 de `lib/main.dart` :
```dart
const kTtsServerUrl = 'http://VOTRE_IP:8766/tts';
```

Pour trouver votre IP :
```bash
ipconfig | findstr "IPv4"
```

## Tests

Tester le serveur TTS :
```bash
curl "http://168.192.3.101:8766/tts?text=Salam&lang=ar" -o test.mp3
curl "http://168.192.3.101:8766/tts?text=Hello&lang=en" -o test.mp3
curl "http://168.192.3.101:8766/tts?text=Bonjour&lang=fr&gender=male" -o test.mp3
curl "http://168.192.3.101:8766/tts?text=Bonjour&lang=fr&gender=female" -o test.mp3
```

## Voices disponibles

### Arabe (ar)
- Masculin: ar-SA-HamedNeural
- Féminin: ar-SA-ZariyahNeural

### Français (fr)
- Masculin: fr-FR-HenriNeural
- Féminin: fr-FR-DeniseNeural

### Anglais (en)
- Masculin: en-US-AndrewNeural
- Féminin: en-US-AriaNeural
