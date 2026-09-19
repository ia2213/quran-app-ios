import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const QuranApp());

// ============================================================
// DATA
// ============================================================

const kBase = 'https://api.alquran.cloud/v1';

const kReciters = [
  {'id': 'ar.alafasy', 'label': 'Mishary Rashid Al-Afasy'},
  {'id': 'ar.husary', 'label': 'Mahmoud Khalil Al-Husary'},
  {'id': 'ar.husarymujawwad', 'label': 'Mahmoud Khalil Al-Husary (Mujawwad)'},
  {'id': 'ar.minshawi', 'label': 'Mohamed Siddiq El-Minshawi'},
  {'id': 'ar.minshawimujawwad', 'label': 'Mohamed Siddiq El-Minshawi (Mujawwad)'},
  {'id': 'ar.abdulbasitmurattal', 'label': 'Abdul Basit (Murattal)'},
  {'id': 'ar.abdulbasitmujawwad', 'label': 'Abdul Basit (Mujawwad)'},
  {'id': 'ar.shaatree', 'label': 'Abu Bakr Al-Shaatree'},
  {'id': 'ar.abdurrahmaansudais', 'label': 'Abdurrahman As-Sudais'},
  {'id': 'ar.saoodshuraym', 'label': 'Saood Al-Shuraym'},
  {'id': 'ar.hudhaify', 'label': 'Ali Al-Hudhaify'},
  {'id': 'ar.mahermuaiqly', 'label': 'Maher Al Muaiqly'},
  {'id': 'ar.yasseraldossari', 'label': 'Yasser Al-Dossari'},
  {'id': 'ar.ahmedajamy', 'label': 'Ahmed Al-Ajamy'},
  {'id': 'ar.nasseralqatami', 'label': 'Nasser Al-Qatami'},
  {'id': 'ar.hanirifai', 'label': 'Hani Ar-Rifai'},
];

const kSurahNames = [
  'Al-Faatiha','Al-Baqara','Aal-i-Imraan','An-Nisaa','Al-Maaida',
  "Al-An'aam","Al-A'raaf","Al-Anfaal","At-Tawba","Yunus",
  'Hud','Yusuf',"Ar-Ra'd","Ibrahim","Al-Hijr",
  'An-Nahl','Al-Israa','Al-Kahf','Maryam','Taa-Haa',
  'Al-Anbiyaa','Al-Hajj','Al-Muminoon','An-Noor','Al-Furqaan',
  "Ash-Shu'araa","An-Naml","Al-Qasas","Al-Ankaboot","Ar-Room",
  'Luqman','As-Sajda','Al-Ahzaab','Saba','Faatir',
  'Yaseen','As-Saaffaat','Saad','Az-Zumar','Ghafir',
  'Fussilat','Ash-Shura','Az-Zukhruf','Ad-Dukhaan','Al-Jaathiya',
  'Al-Ahqaf','Muhammad','Al-Fath','Al-Hujuraat','Qaaf',
  'Adh-Dhaariyat','At-Tur','An-Najm','Al-Qamar','Ar-Rahmaan',
  'Al-Waaqia','Al-Hadid','Al-Mujaadila','Al-Hashr','Al-Mumtahana',
  'As-Saff',"Al-Jumu'a",'Al-Munaafiqoon','At-Taghaabun','At-Talaaq',
  'At-Tahrim','Al-Mulk','Al-Qalam','Al-Haaqqa',"Al-Ma'aarij",
  'Nooh','Al-Jinn','Al-Muzzammil','Al-Muddaththir','Al-Qiyaama',
  'Al-Insaan','Al-Mursalaat','An-Naba',"An-Naazi'at","Abasa","At-Takwir",
  'Al-Infitaar','Al-Mutaffifin','Al-Inshiqaaq','Al-Burooj','At-Taariq',
  "Al-A'laa","Al-Ghaashiya",'Al-Fajr','Al-Balad','Ash-Shams',
  'Al-Lail','Ad-Dhuhaa','Ash-Sharh','At-Tin','Al-Alaq',
  'Al-Qadr','Al-Bayyina','Az-Zalzala','Al-Aadiyaat',"Al-Qaari'a",
  'At-Takaathur','Al-Asr','Al-Humaza','Al-Fil','Quraish',
  "Al-Maa'un",'Al-Kawthar','Al-Kaafiroon','An-Nasr','Al-Masad',
  'Al-Ikhlaas','Al-Falaq','An-Naas',
];

const kSurahNamesArabic = [
  'الفاتحة','البقرة','آل عمران','النساء','المائدة','الأنعام','الأعراف','الأنفال','التوبة','يونس',
  'هود','يوسف','الرعد','إبراهيم','الحجر','النحل','الإسراء','الكهف','مريم','طه',
  'الأنبياء','الحج','المؤمنون','النور','الفرقان','الشعراء','النمل','القصص','العنكبوت','الروم',
  'لقمان','السجدة','الأحزاب','سبأ','فاطر','يس','الصافات','ص','الزمر','غافر',
  'فصلت','الشورى','الزخرف','الدخان','الجاثية','الأحقاف','محمد','الفتح','الحجرات','ق',
  'الذاريات','الطور','النجم','القمر','الرحمن','الواقعة','الحديد','المجادلة','الحشر','الممتحنة',
  'الصف','الجمعة','المنافقون','التغابن','الطلاق','التحريم','الملك','القلم','الحاقة','المعارج',
  'نوح','الجن','المزمل','المدثر','القيامة','الإنسان','المرسلات','النبأ','النازعات','عبس',
  'التكوير','الإنفطار','المطففين','الإنشقاق','البروج','الطارق','الأعلى','الغاشية','الفجر','البلد',
  'الشمس','الليل','الضحى','الشرح','التين','العلق','القدر','البينة','الزلزلة','العاديات',
  'القارعة','التكاثر','العصر','الهمزة','الفيل','قريش','الماعون','الكوثر','الكافرون','النصر',
  'المسد','الإخلاص','الفلق','الناس',
];

const kAyahCounts = [
  7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,
  112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,
  89,59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,
  12,30,52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,
  30,20,15,21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6,
];

// ============================================================
// HELPERS
// ============================================================

String recitationFilename(String reciter, int surah, int verse) {
  return '${reciter.replaceAll('.', '_')}_${surah.toString().padLeft(3, '0')}_${verse.toString().padLeft(3, '0')}.mp3';
}

Future<String?> fetchRecitationUrl(String reciter, int surah, int verse) async {
  try {
    final r = await http.get(Uri.parse('$kBase/ayah/$surah:$verse/$reciter'));
    if (r.statusCode == 200) {
      final d = json.decode(r.body) as Map<String, dynamic>;
      return d['data']['audio'] as String?;
    }
  } catch (e) {
    debugPrint('fetchRecitationUrl error: $e');
  }
  return null;
}

Future<File?> downloadRecitation(String reciter, int surah, int verse, Directory cacheDir) async {
  final filename = recitationFilename(reciter, surah, verse);
  final file = File('${cacheDir.path}/$filename');
  if (await file.exists()) return file;

  final url = await fetchRecitationUrl(reciter, surah, verse);
  if (url == null) return null;

  try {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request);
    if (response.statusCode == 200) {
      final bytes = await response.stream.toBytes();
      await file.writeAsBytes(bytes);
      return file;
    }
  } catch (e) {
    debugPrint('downloadRecitation error: $e');
  }
  return null;
}

Future<String> fetchArabicText(int surah, int verse) async {
  try {
    final r = await http.get(Uri.parse('$kBase/ayah/$surah:$verse/quran-uthmani'));
    if (r.statusCode == 200) {
      final d = json.decode(r.body) as Map<String, dynamic>;
      return d['data']['text'] as String? ?? '';
    }
  } catch (e) {
    debugPrint('fetchArabicText error: $e');
  }
  return '';
}

Future<String> fetchTranslation(int surah, int verse, String lang) async {
  try {
    String trId = lang == 'fr' ? 'fr.hamidullah' : 'en.sahih';
    final r = await http.get(Uri.parse('$kBase/ayah/$surah:$verse/$trId'));
    if (r.statusCode == 200) {
      final d = json.decode(r.body) as Map<String, dynamic>;
      return d['data']['text'] as String? ?? '';
    }
  } catch (e) {
    debugPrint('fetchTranslation error: $e');
  }
  return '';
}

Future<String> fetchTransliteration(int surah, int verse) async {
  try {
    final r = await http.get(Uri.parse('$kBase/ayah/$surah:$verse/en.transliteration'));
    if (r.statusCode == 200) {
      final d = json.decode(r.body) as Map<String, dynamic>;
      return d['data']['text'] as String? ?? '';
    }
  } catch (e) {
    debugPrint('fetchTransliteration error: $e');
  }
  return '';
}

// ============================================================
// APP STATE
// ============================================================

class AppState extends ChangeNotifier {
  final List<Map<String, dynamic>> _surahs = [];
  bool _surahLoading = false;
  String _reciter = 'ar.alafasy';
  String _translationLang = 'fr';
  bool _isDarkMode = true;

  List<Map<String, dynamic>> get surahs => _surahs;
  bool get surahLoading => _surahLoading;
  String get reciter => _reciter;
  String get translationLang => _translationLang;
  bool get isDarkMode => _isDarkMode;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  void toggleTheme(bool val) async {
    _isDarkMode = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', val);
  }

  Future<void> loadSurahs() async {
    _surahLoading = true;
    notifyListeners();
    try {
      final r = await http.get(Uri.parse('$kBase/surah'));
      if (r.statusCode == 200) {
        final d = json.decode(r.body) as Map<String, dynamic>;
        _surahs.clear();
        for (var s in d['data'] as List) {
          _surahs.add({
            'number': s['number'],
            'name': s['name'],
            'englishName': s['englishName'],
            'numberOfAyahs': s['numberOfAyahs'],
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading surahs: $e');
    }
    _surahLoading = false;
    notifyListeners();
  }

  void setReciter(String id) { _reciter = id; notifyListeners(); }
  void setTranslationLang(String lang) { _translationLang = lang; notifyListeners(); }
}

// ============================================================
// MAIN APP
// ============================================================

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..loadSurahs()..loadTheme(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'Coran',
            debugShowCheckedModeBanner: false,
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: _lightTheme(),
            darkTheme: _darkTheme(),
            home: const QuranHome(),
          );
        },
      ),
    );
  }

  static ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF10B981),
        secondary: Color(0xFF2563EB),
        surface: Colors.white,
        onSurface: Color(0xFF111827),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFFF5F5F7),
        foregroundColor: Color(0xFF111827),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF111827)),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF374151)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFF5F5F7),
        selectedItemColor: Color(0xFF10B981),
        unselectedItemColor: Color(0xFF8E8E93),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000),
      cardTheme: CardThemeData(
        color: const Color(0xFF1C1C1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF10B981),
        secondary: Color(0xFF3B82F6),
        surface: Color(0xFF1C1C1E),
        onSurface: Color(0xFFF9FAFB),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFF000000),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFF9FAFB)),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFF9FAFB)),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1C1C1E),
        selectedItemColor: Color(0xFF10B981),
        unselectedItemColor: Color(0xFF636366),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class QuranHome extends StatefulWidget {
  const QuranHome({super.key});

  @override
  State<QuranHome> createState() => _QuranHomeState();
}

class _QuranHomeState extends State<QuranHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          RecitationScreen(),
          DownloadScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFE5E7EB),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          backgroundColor: Colors.transparent,
          indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.headphones_outlined),
              selectedIcon: Icon(Icons.headphones),
              label: 'Lecture',
            ),
            NavigationDestination(
              icon: Icon(Icons.download_outlined),
              selectedIcon: Icon(Icons.download),
              label: 'Téléchargements',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RECITATION SCREEN
// ============================================================

class RecitationScreen extends StatefulWidget {
  const RecitationScreen({super.key});

  @override
  State<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends State<RecitationScreen> {
  // Mode
  String _mode = 'single';

  // Range
  int _startSurah = 1, _startVerse = 1, _endSurah = 1, _endVerse = 7;
  int _pageNumber = 1;

  // Single
  int _singleSurah = 1, _singleVerse = 1;

  // Options
  bool _announceSurahVerse = true;
  bool _announceVerseOnly = false;
  bool _speakTranslation = true;
  bool _speakRecitation = true;
  bool _infiniteLoop = false;
  int _repeatCount = 1;
  String _lang = 'fr';
  String _reciter = 'ar.alafasy';

  // State
  String _phase = 'idle';
  String? _currentSurahName;
  int? _currentVerseNum;
  String _arabicText = '';
  String _translationText = '';
  String _transliterationText = '';
  bool _showArabic = true;
  bool _showTransliteration = true;
  bool _showTranslation = true;
  bool _showFullScreenPlayer = false;
  bool _wasPlayingBeforeInterruption = false;
  int _lastAnnouncedSurah = -1;
  int _repeatIndex = 0;
  int _progressDone = 0;
  int _progressTotal = 0;
  String? _error;
  bool _isRunning = false;
  bool _stopFlag = false;

  // Audio
  final _player = AudioPlayer();
  final _ttsPlayer = AudioPlayer();

  // TTS
  final FlutterTts _flutterTts = FlutterTts();
  Completer<void>? _ttsCompleter;
  Map<String, String> _selectedVoice = {};
  List<Map<String, dynamic>> _availableVoices = [];

  // Controllers
  late final TextEditingController _startSurahCtrl = TextEditingController(text: '1');
  late final TextEditingController _startVerseCtrl = TextEditingController(text: '1');
  late final TextEditingController _endSurahCtrl = TextEditingController(text: '1');
  late final TextEditingController _endVerseCtrl = TextEditingController(text: '7');
  late final TextEditingController _pageNumberCtrl = TextEditingController(text: '1');
  late final TextEditingController _singleSurahCtrl = TextEditingController(text: '1');
  late final TextEditingController _singleVerseCtrl = TextEditingController(text: '1');
  late final TextEditingController _verseInputCtrl = TextEditingController(text: '1');

  Directory? _cacheDir;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _initTts();
    _loadPrefs();
  }

  Future<void> _initAudio() async {
    _player.setVolume(1.0);
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.allowBluetoothA2dp |
            AVAudioSessionCategoryOptions.allowAirPlay,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
      await session.setActive(true);
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          _wasPlayingBeforeInterruption = _isRunning && (_player.playing || _ttsPlayer.playing);
          _player.pause();
          _ttsPlayer.pause();
        } else {
          if (_wasPlayingBeforeInterruption && _isRunning && !_stopFlag) {
            _player.play();
          }
        }
      });
      session.becomingNoisyEventStream.listen((_) {
        _player.pause();
      });
    } catch (e) {
      debugPrint('Audio session init error: $e');
    }
  }

  Future<void> _initTts() async {
    try {
      if (Platform.isIOS) {
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.defaultMode,
        );
      }
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      final voices = await _flutterTts.getVoices;
      _availableVoices = List<Map<String, dynamic>>.from(
        voices.where((v) => v is Map).map((v) => Map<String, dynamic>.from(v))
      );

      await _loadPrefs();

      _flutterTts.setCompletionHandler(() {
        if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
          _ttsCompleter!.complete();
        }
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS error: $msg');
        if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
          _ttsCompleter!.complete();
        }
      });
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _reciter = prefs.getString('reciter') ?? 'ar.alafasy';
      _lang = prefs.getString('lang') ?? 'fr';
      _announceSurahVerse = prefs.getBool('announceSurahVerse') ?? true;
      _speakTranslation = prefs.getBool('speakTranslation') ?? true;
      _speakRecitation = prefs.getBool('speakRecitation') ?? true;
      _repeatCount = prefs.getInt('repeatCount') ?? 1;

      _cacheDir = Directory('${(await getApplicationDocumentsDirectory()).path}/recitations');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      final savedVoiceName = prefs.getString('ttsVoiceName') ?? '';
      final savedVoiceLocale = prefs.getString('ttsVoiceLocale') ?? '';
      if (savedVoiceName.isNotEmpty) {
        _selectedVoice = {'name': savedVoiceName, 'locale': savedVoiceLocale};
        await _flutterTts.setVoice(_selectedVoice);
      } else {
        _selectDefaultVoice();
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Load prefs error: $e');
    }
  }

  void _selectDefaultVoice() {
    final langFilter = _lang == 'fr' ? 'fr' : 'en';
    final candidates = _availableVoices.where((v) {
      final locale = (v['locale'] as String?) ?? '';
      return locale.toLowerCase().startsWith(langFilter);
    }).toList();

    if (candidates.isNotEmpty) {
      final voice = candidates.first;
      _selectedVoice = {
        'name': (voice['name'] as String?) ?? '',
        'locale': (voice['locale'] as String?) ?? '',
      };
      _flutterTts.setVoice(_selectedVoice);
    }
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
    if (value is int) await prefs.setInt(key, value);
  }

  @override
  void dispose() {
    _stopFlag = true;
    _player.stop();
    _flutterTts.stop();
    _startSurahCtrl.dispose();
    _startVerseCtrl.dispose();
    _endSurahCtrl.dispose();
    _endVerseCtrl.dispose();
    _pageNumberCtrl.dispose();
    _singleSurahCtrl.dispose();
    _singleVerseCtrl.dispose();
    _verseInputCtrl.dispose();
    super.dispose();
  }

  void _stop() {
    _stopFlag = true;
    _lastAnnouncedSurah = -1;
    _player.stop();
    _flutterTts.stop();
    if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
      _ttsCompleter!.complete();
    }
    if (mounted) {
      setState(() {
        _phase = 'idle';
        _isRunning = false;
        _repeatIndex = 0;
      });
    }
  }

  Future<void> _skipTo(int surah, int verse) async {
    _stop();
    _mode = 'single';
    _singleSurah = surah.clamp(1, 114);
    int maxV = kAyahCounts[_singleSurah - 1];
    _singleVerse = verse.clamp(1, maxV);
    _syncControllers();

    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) {
      setState(() {
        _arabicText = '';
        _transliterationText = '';
        _translationText = '';
        _currentSurahName = (surah >= 1 && surah <= 114) ? kSurahNames[surah - 1] : 'Sourate $surah';
        _currentVerseNum = _singleVerse;
      });
      _play();
    }
  }

  void _nextVerse() {
    int maxV = kAyahCounts[_singleSurah - 1];
    if (_singleVerse < maxV) {
      _skipTo(_singleSurah, _singleVerse + 1);
    } else if (_singleSurah < 114) {
      _skipTo(_singleSurah + 1, 1);
    }
  }

  void _prevVerse() {
    if (_singleVerse > 1) {
      _skipTo(_singleSurah, _singleVerse - 1);
    } else if (_singleSurah > 1) {
      _skipTo(_singleSurah - 1, kAyahCounts[_singleSurah - 2]);
    }
  }

  void _nextSurah() {
    if (_singleSurah < 114) {
      _skipTo(_singleSurah + 1, 1);
    }
  }

  void _prevSurah() {
    if (_singleSurah > 1) {
      _skipTo(_singleSurah - 1, 1);
    }
  }

  void _togglePausePlay() {
    if (_player.playing) {
      _player.pause();
      _ttsPlayer.pause();
    } else {
      _player.play();
    }
    setState(() {});
  }

  // ---- TTS ----

  Future<void> _waitForTtsPlayerStopped() async {
    try {
      await _ttsPlayer.processingStateStream.firstWhere(
        (s) => s == ProcessingState.completed || s == ProcessingState.idle || _stopFlag,
      );
    } catch (e) {
      debugPrint('Wait TTS error: $e');
    }
  }

  Future<void> _speak(String text, String lang) async {
    if (text.isEmpty || _stopFlag) return;
    bool spokeNatively = false;

    if (lang != 'ar') {
      try {
        _ttsCompleter = Completer<void>();
        final ttsLang = lang == 'fr' ? 'fr-FR' : 'en-US';
        await _flutterTts.setLanguage(ttsLang);

        if (_selectedVoice.isNotEmpty) {
          try {
            await _flutterTts.setVoice(_selectedVoice);
          } catch (_) {}
        }

        final res = await _flutterTts.speak(text);
        if (res == 1 || res == true) {
          final timeoutSeconds = (text.length / 8).ceil().clamp(5, 60);
          await _ttsCompleter!.future.timeout(
            Duration(seconds: timeoutSeconds),
            onTimeout: () {
              _flutterTts.stop();
              debugPrint('TTS native timeout, falling back to HTTP');
            },
          );
          spokeNatively = true;
        }
      } catch (e) {
        debugPrint('Native TTS error: $e');
      }
    }

    if (!spokeNatively && !_stopFlag) {
      try {
        final cleanText = text.replaceAll(RegExp(r'[()]'), '');
        final tl = lang == 'fr' ? 'fr-FR' : (lang == 'ar' ? 'ar' : 'en-US');
        final encoded = Uri.encodeComponent(cleanText);
        final url = 'https://translate.google.com/translate_tts?ie=UTF-8&tl=$tl&client=tw-ob&q=$encoded';

        await _ttsPlayer.stop();
        await _ttsPlayer.setUrl(url);
        await _ttsPlayer.play();
        await _waitForTtsPlayerStopped();
      } catch (e) {
        debugPrint('HTTP TTS error: $e');
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }
  }

  // ---- RECITATION ----

  Future<void> _waitForPlayerStopped() async {
    try {
      await _player.processingStateStream.firstWhere(
        (s) => s == ProcessingState.completed || s == ProcessingState.idle || _stopFlag,
      );
    } catch (e) {
      debugPrint('Wait player error: $e');
    }
  }

  Future<void> _playRecitation(int surah, int verse) async {
    if (_stopFlag) return;
    try {
      if (_cacheDir == null) {
        _cacheDir = Directory('${(await getApplicationDocumentsDirectory()).path}/recitations');
        if (!await _cacheDir!.exists()) await _cacheDir!.create(recursive: true);
      }

      final filename = recitationFilename(_reciter, surah, verse);
      final file = File('${_cacheDir!.path}/$filename');

      if (await file.exists()) {
        await _player.setFilePath(file.path);
      } else {
        final url = await fetchRecitationUrl(_reciter, surah, verse);
        if (url == null) return;
        try {
          final client = http.Client();
          final request = http.Request('GET', Uri.parse(url));
          final response = await client.send(request);
          if (response.statusCode == 200) {
            final bytes = await response.stream.toBytes();
            await file.writeAsBytes(bytes);
            await _player.setFilePath(file.path);
          }
          client.close();
        } catch (e) {
          debugPrint('Recitation download error: $e');
          return;
        }
      }

      if (!_stopFlag && mounted) {
        await _player.play();
        await _waitForPlayerStopped();
      }
    } catch (e) {
      debugPrint('Recitation error: $e');
    }
  }

  // ---- SEQUENCE ----

  Future<void> _runSequence(List<Map<String, int>> seq,
      {int repeats = 3, bool infinite = false, bool withTranslation = true, bool withRecitation = true}) async {
    _stopFlag = false;
    _isRunning = true;
    int done = 0;
    int rep = 0;

    while (!_stopFlag && (infinite || rep < repeats)) {
      rep++;
      if (mounted) setState(() => _repeatIndex = rep);

      for (var ref in seq) {
        if (_stopFlag) break;
        int surah = ref['surah']!;
        int verse = ref['verse']!;

        if (surah != _lastAnnouncedSurah) {
          String surahName = (surah >= 1 && surah <= 114) ? kSurahNames[surah - 1] : 'Sourate $surah';
          _lastAnnouncedSurah = surah;

          if (mounted) {
            setState(() {
              _singleSurah = surah;
              _singleVerse = verse;
              _currentSurahName = surahName;
              _currentVerseNum = verse;
            });
          }

          if (_announceSurahVerse) {
            if (mounted) setState(() => _phase = 'announcing');
            String surahNameAr = (surah >= 1 && surah <= 114) ? kSurahNamesArabic[surah - 1] : '$surah';
            String cleanNameAr = surahNameAr.endsWith('ة')
                ? '${surahNameAr.substring(0, surahNameAr.length - 1)}ه'
                : surahNameAr;
            final annAr = 'سورة. $cleanNameAr';
            await _speak(annAr, 'ar');
            await _waitForTtsPlayerStopped();
            if (_stopFlag) break;
          }
        } else if (_announceVerseOnly) {
          if (mounted) {
            setState(() {
              _singleSurah = surah;
              _singleVerse = verse;
              _currentSurahName = (surah >= 1 && surah <= 114) ? kSurahNames[surah - 1] : 'Sourate $surah';
              _currentVerseNum = verse;
              _phase = 'announcing';
            });
          }
          final verseText = _lang == 'fr' ? 'Verset $verse' : 'Verse $verse';
          await _speak(verseText, _lang);
          await _waitForTtsPlayerStopped();
          if (_stopFlag) break;
        }

        if (mounted) {
          setState(() {
            _singleSurah = surah;
            _singleVerse = verse;
            _currentSurahName = (surah >= 1 && surah <= 114) ? kSurahNames[surah - 1] : 'Sourate $surah';
            _currentVerseNum = verse;
            _phase = 'reciting';
          });
        }

        fetchArabicText(surah, verse).then((text) {
          if (mounted && text.isNotEmpty) {
            setState(() => _arabicText = text);
          }
        }).catchError((_) {});

        fetchTransliteration(surah, verse).then((text) {
          if (mounted && text.isNotEmpty) {
            setState(() => _transliterationText = text);
          }
        }).catchError((_) {});

        if (_stopFlag) break;

        if (withRecitation) {
          await _playRecitation(surah, verse);
        }

        if (withTranslation && _speakTranslation) {
          if (mounted) setState(() => _phase = 'translating');
          String trText = await fetchTranslation(surah, verse, _lang);
          if (mounted) setState(() => _translationText = trText);

          if (trText.isNotEmpty && !_stopFlag) {
            await _speak(trText, _lang);
            if (_stopFlag) break;
          }
        } else {
          if (mounted) setState(() => _translationText = '');
        }

        done++;
        if (!infinite && mounted) setState(() => _progressDone = done);
      }
    }

    if (mounted) {
      setState(() {
        _phase = _stopFlag ? 'idle' : 'done';
        _isRunning = false;
        _repeatIndex = 0;
      });
    }
  }

  Future<void> _play() async {
    _stopFlag = false;
    if (mounted) {
      setState(() {
        _error = null;
        _translationText = '';
        _progressDone = 0;
        _phase = 'announcing';
        _isRunning = true;
        _showFullScreenPlayer = true;
      });
    }
    try {
      List<Map<String, int>> seq = [];

      if (_mode == 'range') {
        int sSurah = _startSurah;
        int eSurah = _endSurah;
        if (sSurah > eSurah) { int tmp = sSurah; sSurah = eSurah; eSurah = tmp; }

        for (int s = sSurah; s <= eSurah; s++) {
          int maxAyah = kAyahCounts[s - 1];
          int startV = (s == sSurah) ? _startVerse.clamp(1, maxAyah) : 1;
          int endV = (s == eSurah) ? _endVerse.clamp(1, maxAyah) : maxAyah;
          if (startV > endV) { int t = startV; startV = endV; endV = t; }

          for (int v = startV; v <= endV; v++) {
            seq.add({'surah': s, 'verse': v});
          }
        }
      } else if (_mode == 'page') {
        try {
          final r = await http.get(Uri.parse('$kBase/page/$_pageNumber/quran-uthmani'));
          if (r.statusCode == 200) {
            final d = json.decode(r.body) as Map<String, dynamic>;
            for (var a in d['data']['ayahs'] as List) {
              seq.add({'surah': a['surah']['number'] as int, 'verse': a['numberInSurah'] as int});
            }
          }
        } catch (e) {
          debugPrint('Page fetch error: $e');
        }
      } else {
        int startS = _singleSurah.clamp(1, 114);
        int startV = _singleVerse.clamp(1, kAyahCounts[startS - 1]);
        for (int s = startS; s <= 114; s++) {
          int maxAyah = kAyahCounts[s - 1];
          int vBegin = (s == startS) ? startV : 1;
          for (int v = vBegin; v <= maxAyah; v++) {
            seq.add({'surah': s, 'verse': v});
          }
        }
      }

      if (seq.isEmpty) {
        if (mounted) setState(() => _error = 'Aucun verset trouvé');
        return;
      }

      _progressTotal = _infiniteLoop ? 0 : seq.length * _repeatCount;
      await _runSequence(seq,
          repeats: _infiniteLoop ? 999 : _repeatCount,
          infinite: _infiniteLoop,
          withTranslation: _speakTranslation,
          withRecitation: _speakRecitation);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur: $e');
    }
  }

  // ---- UI HELPERS ----

  void _syncControllers() {
    if (_startSurahCtrl.text != _startSurah.toString()) _startSurahCtrl.text = _startSurah.toString();
    if (_startVerseCtrl.text != _startVerse.toString()) _startVerseCtrl.text = _startVerse.toString();
    if (_endSurahCtrl.text != _endSurah.toString()) _endSurahCtrl.text = _endSurah.toString();
    if (_endVerseCtrl.text != _endVerse.toString()) _endVerseCtrl.text = _endVerse.toString();
    if (_pageNumberCtrl.text != _pageNumber.toString()) _pageNumberCtrl.text = _pageNumber.toString();
    if (_singleSurahCtrl.text != _singleSurah.toString()) _singleSurahCtrl.text = _singleSurah.toString();
    if (_singleVerseCtrl.text != _singleVerse.toString()) _singleVerseCtrl.text = _singleVerse.toString();
    if (_verseInputCtrl.text != _singleVerse.toString()) _verseInputCtrl.text = _singleVerse.toString();
  }

  /// Build a nice input field
  Widget _styledInput(String label, int value, int min, int max, Function(int) onChanged,
      {required TextEditingController ctrl}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D5DB);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 68,
            height: 36,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF000000),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              textAlign: TextAlign.center,
              onTap: () {
                ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
              },
              onChanged: (v) => onChanged(int.tryParse(v) ?? value),
            ),
          ),
        ],
      ),
    );
  }

  /// Surah dropdown with names
  Widget _surahDropdown(int currentSurah, Function(int) onChanged,
      {required TextEditingController ctrl}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D5DB);

    return Row(
      children: [
        const SizedBox(width: 100),
        const SizedBox(width: 12),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<int>(
            value: currentSurah,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF111827),
            ),
            items: List.generate(114, (i) => i + 1).map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(
                  '${s}. ${kSurahNames[s - 1]}',
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                onChanged(v);
                ctrl.text = v.toString();
              }
            },
          ),
        ),
      ],
    );
  }

  /// Preset buttons
  Widget _presetButton(String label, String surahName, int surah, int verse, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              _mode = 'single';
              _singleSurah = surah;
              _singleVerse = verse;
              _currentSurahName = surahName;
              _currentVerseNum = verse;
              _syncControllers();
            });
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withOpacity(0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 10),
            backgroundColor: color.withOpacity(0.08),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // ---- FULL SCREEN PLAYER ----

  Widget _buildFullScreenPlayer(BuildContext context, AppState appState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isPlaying = _player.playing || _ttsPlayer.playing;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => setState(() => _showFullScreenPlayer = false),
        ),
        title: Column(
          children: [
            Text(
              _currentSurahName ?? 'Sourate $_singleSurah',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Text(
                  'Verset ${_currentVerseNum ?? _singleVerse}',
                  style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                _phaseBadge(isDark, primaryColor),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(appState.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round),
            onPressed: () => appState.toggleTheme(!appState.isDarkMode),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Toggle chips
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _toggleChip('Arabe', _showArabic, primaryColor, isDark),
                  const SizedBox(width: 8),
                  _toggleChip('Phonétique', _showTransliteration, primaryColor, isDark),
                  const SizedBox(width: 8),
                  _toggleChip('Traduction', _showTranslation, primaryColor, isDark),
                ],
              ),
            ),

            // Verse display
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (_showArabic && _arabicText.isNotEmpty) ...[
                      _arabicVerseCard(isDark, primaryColor),
                      const SizedBox(height: 20),
                    ],
                    if (_showTransliteration && _transliterationText.isNotEmpty) ...[
                      _transliterationCard(isDark),
                      const SizedBox(height: 16),
                    ],
                    if (_showTranslation && _translationText.isNotEmpty) ...[
                      _translationCard(isDark),
                    ],
                  ],
                ),
              ),
            ),

            // Control dock
            _controlDock(isDark, primaryColor, isPlaying),
          ],
        ),
      ),
    );
  }

  Widget _phaseBadge(bool isDark, Color primaryColor) {
    final phaseColor = _phase == 'reciting'
        ? const Color(0xFF10B981)
        : (_phase == 'announcing' ? const Color(0xFF2563EB) : const Color(0xFFFF9500));
    final phaseLabel = _phase == 'idle'
        ? 'Prêt'
        : (_phase == 'announcing' ? 'Annonce' : (_phase == 'reciting' ? 'Récitation' : 'Traduction'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: phaseColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        phaseLabel,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _toggleChip(String label, bool selected, Color primary, bool isDark) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      selected: selected,
      onSelected: (v) => setState(() {
        if (label == 'Arabe') _showArabic = v;
        if (label == 'Phonétique') _showTransliteration = v;
        if (label == 'Traduction') _showTranslation = v;
      }),
      selectedColor: primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
        fontWeight: FontWeight.w500,
      ),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _arabicVerseCard(bool isDark, Color primaryColor) {
    final isReciting = _phase == 'reciting';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isReciting
            ? const Color(0xFF10B981)
            : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isReciting
              ? const Color(0xFF10B981)
              : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isReciting
                ? const Color(0xFF10B981).withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: isReciting ? 2 : 0,
          ),
        ],
      ),
      child: Text(
        _arabicText,
        style: TextStyle(
          fontSize: 34,
          height: 1.9,
          color: isReciting
              ? const Color(0xFF000000)
              : (isDark ? const Color(0xFFF9FAFB) : const Color(0xFF0F172A)),
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _transliterationCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB),
          width: 0.5,
        ),
      ),
      child: Text(
        _transliterationText,
        style: TextStyle(
          fontSize: 15,
          height: 1.5,
          color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _translationCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB),
          width: 0.5,
        ),
      ),
      child: Text(
        _translationText,
        style: TextStyle(
          fontSize: 15,
          height: 1.5,
          color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _controlDock(bool isDark, Color primaryColor, bool isPlaying) {
    final reciterLabel = kReciters.firstWhere(
      (r) => r['id'] == _reciter,
      orElse: () => {'label': 'Al-Afasy'},
    )['label'] as String;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF9F9FB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress
          if (_progressTotal > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _progressTotal > 0 ? _progressDone / _progressTotal : 0,
                    backgroundColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB),
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_progressDone / $_progressTotal',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

          // Reciter label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              reciterLabel,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _controlButton(Icons.skip_previous_rounded, 'Sourate précédente', _prevSurah, primaryColor, isDark),
              _controlButton(Icons.fast_rewind_rounded, 'Verset précédent', _prevVerse, primaryColor, isDark),
              _playButton(isPlaying, primaryColor),
              _controlButton(Icons.fast_forward_rounded, 'Verset suivant', _nextVerse, primaryColor, isDark),
              _controlButton(Icons.skip_next_rounded, 'Sourate suivante', _nextSurah, primaryColor, isDark),
            ],
          ),

          const SizedBox(height: 14),

          // Stop button
          SizedBox(
            width: 160,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                _stop();
                setState(() => _showFullScreenPlayer = false);
              },
              icon: const Icon(Icons.stop_rounded, size: 18),
              label: const Text('Arrêter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, String tooltip, VoidCallback onPressed, Color primary, bool isDark) {
    return IconButton(
      icon: Icon(icon, size: 28, color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF374151)),
      tooltip: tooltip,
      onPressed: onPressed,
      hoverColor: primary.withOpacity(0.1),
    );
  }

  Widget _playButton(bool isPlaying, Color primary) {
    return FloatingActionButton.large(
      onPressed: _togglePausePlay,
      backgroundColor: primary,
      elevation: 4,
      child: Icon(
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: 44,
        color: Colors.white,
      ),
    );
  }

  // ---- MAIN BUILD ----

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    if (_showFullScreenPlayer) {
      return _buildFullScreenPlayer(context, appState);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecture du Coran'),
        actions: [
          IconButton(
            icon: Icon(appState.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round),
            onPressed: () => appState.toggleTheme(!appState.isDarkMode),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- SELECTION CARD ----
          _glassCard(isDark, [
            const Text('Sélection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.3)),
            const SizedBox(height: 14),

            // Surah dropdown + verse input
            _surahDropdown(_singleSurah, (v) {
              setState(() {
                _mode = 'single';
                _singleSurah = v;
                _syncControllers();
              });
            }, ctrl: _singleSurahCtrl),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 100),
                const SizedBox(width: 12),
                const Text('Verset:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 68,
                  height: 36,
                  child: TextField(
                    controller: _verseInputCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D5DB),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    textAlign: TextAlign.center,
                    onTap: () {
                      _verseInputCtrl.selection = TextSelection(
                        baseOffset: 0, extentOffset: _verseInputCtrl.text.length,
                      );
                    },
                    onChanged: (v) {
                      final val = int.tryParse(v) ?? 1;
                      setState(() {
                        _singleVerse = val.clamp(1, kAyahCounts[_singleSurah - 1]);
                        _syncControllers();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Presets
            const Text('Lecture rapide', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF8E8E93))),
            const SizedBox(height: 8),
            Row(
              children: [
                _presetButton('Al-Fatiha', 'Al-Faatiha', 1, 1, primaryColor),
                _presetButton('Dernières 10', 'Al-Nas', 105, 1, primaryColor),
                _presetButton('Page 1', 'Page 1', 1, 1, primaryColor),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _presetButton('Sourate 114', 'An-Naas', 114, 1, primaryColor),
                _presetButton('Sourate 36', 'Yaseen', 36, 1, primaryColor),
                _presetButton('Sourate 55', 'Ar-Rahman', 55, 1, primaryColor),
              ],
            ),
          ]),

          const SizedBox(height: 14),

          // ---- MODE PICKER ----
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _modeChip('single', 'Verset', isDark, primaryColor),
                _modeChip('range', 'Plage', isDark, primaryColor),
                _modeChip('page', 'Page', isDark, primaryColor),
                _modeChip('loop', 'Boucle', isDark, primaryColor),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ---- MODE INPUTS ----
          if (_mode == 'range')
            _glassCard(isDark, [
              _styledInput('Sourate début', _startSurah, 1, 114, (v) => setState(() { _startSurah = v; _syncControllers(); }), ctrl: _startSurahCtrl),
              _styledInput('Verset début', _startVerse, 1, 286, (v) => setState(() { _startVerse = v; _syncControllers(); }), ctrl: _startVerseCtrl),
              const SizedBox(height: 4),
              _styledInput('Sourate fin', _endSurah, 1, 114, (v) => setState(() { _endSurah = v; _syncControllers(); }), ctrl: _endSurahCtrl),
              _styledInput('Verset fin', _endVerse, 1, 286, (v) => setState(() { _endVerse = v; _syncControllers(); }), ctrl: _endVerseCtrl),
            ]),

          if (_mode == 'page')
            _glassCard(isDark, [
              _styledInput('Page (1–604)', _pageNumber, 1, 604, (v) => setState(() { _pageNumber = v; _syncControllers(); }), ctrl: _pageNumberCtrl),
            ]),

          if (_mode == 'single' || _mode == 'loop')
            _glassCard(isDark, [
              _styledInput('Sourate', _singleSurah, 1, 114, (v) => setState(() { _singleSurah = v; _syncControllers(); }), ctrl: _singleSurahCtrl),
              _styledInput('Verset', _singleVerse, 1, 286, (v) => setState(() { _singleVerse = v; _syncControllers(); }), ctrl: _singleVerseCtrl),
            ]),

          const SizedBox(height: 14),

          // ---- OPTIONS CARD ----
          _glassCard(isDark, [
            const Text('Options de lecture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.3)),
            const SizedBox(height: 12),

            _switchRow('Annoncer la sourate', 'Ex: "Sourate Al-Fatiha"', _announceSurahVerse, (v) {
              setState(() => _announceSurahVerse = v);
              _savePref('announceSurahVerse', v);
            }, isDark: isDark),
            const SizedBox(height: 4),
            _switchRow('Annoncer le verset', 'Ex: "Verset 1"', _announceVerseOnly, (v) {
              setState(() => _announceVerseOnly = v);
            }, isDark: isDark),
            const SizedBox(height: 4),
            _switchRow('Lire la récitation', 'Audio local (fichier)', _speakRecitation, (v) {
              setState(() => _speakRecitation = v);
              _savePref('speakRecitation', v);
            }, isDark: isDark),
            const SizedBox(height: 4),
            _switchRow('Lire la traduction', 'Voix TTS française', _speakTranslation, (v) {
              setState(() => _speakTranslation = v);
              _savePref('speakTranslation', v);
            }, isDark: isDark),
            const SizedBox(height: 4),
            _switchRow('Boucle infinie', 'Répéter indéfiniment', _infiniteLoop, (v) {
              setState(() => _infiniteLoop = v);
            }, isDark: isDark),

            if (!_infiniteLoop) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Répétitions:', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: _repeatCount.toDouble(),
                      min: 1,
                      max: 99,
                      divisions: 98,
                      label: _repeatCount.toString(),
                      onChanged: (v) {
                        setState(() => _repeatCount = v.round());
                        _savePref('repeatCount', v.round());
                      },
                      activeColor: primaryColor,
                      inactiveColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D5DB),
                    ),
                  ),
                  Text(
                    'x${_repeatCount}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 24, color: Color(0xFFE5E7EB)),
            const Text('VOCODER TTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8E8E93))),
            const SizedBox(height: 4),
            const Text('Voix système — fonctionne hors-ligne', style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
            const SizedBox(height: 10),

            // Language
            Row(
              children: [
                const Text('Langue:', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Français'),
                  selected: _lang == 'fr',
                  onSelected: (v) {
                    setState(() => _lang = 'fr');
                    _savePref('lang', 'fr');
                    _selectDefaultVoice();
                  },
                  selectedColor: primaryColor,
                  labelStyle: TextStyle(
                    color: _lang == 'fr' ? Colors.white : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('English'),
                  selected: _lang == 'en',
                  onSelected: (v) {
                    setState(() => _lang = 'en');
                    _savePref('lang', 'en');
                    _selectDefaultVoice();
                  },
                  selectedColor: primaryColor,
                  labelStyle: TextStyle(
                    color: _lang == 'en' ? Colors.white : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Reciter
            Row(
              children: [
                const Text('Récitateur:', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _reciter,
                    isExpanded: true,
                    items: kReciters.map((r) => DropdownMenuItem<String>(
                      value: r['id'] as String,
                      child: Text(r['label'] as String, style: const TextStyle(fontSize: 13)),
                    )).toList(),
                    onChanged: (v) {
                      setState(() => _reciter = v!);
                      _savePref('reciter', v);
                    },
                    underline: const SizedBox(),
                    dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF111827)),
                  ),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 14),

          // ---- ACTION BUTTONS ----
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isRunning ? null : _play,
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: const Text('Lancer la lecture', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isRunning ? _stop : null,
                  icon: const Icon(Icons.stop_rounded, size: 24),
                  label: const Text('Arrêter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Error
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('⚠️ $_error', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
            ),

          // Progress
          if (_progressTotal > 0 && !_isRunning)
            Column(
              children: [
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progressDone / _progressTotal,
                  backgroundColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB),
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  'Terminé: $_progressDone / $_progressTotal',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),

          // ---- NOW PLAYING CARD (compact) ----
          if (_arabicText.isNotEmpty || _isRunning)
            _nowPlayingCard(isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _glassCard(bool isDark, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB),
          width: 0.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _modeChip(String mode, String label, bool isDark, Color primary) {
    final selected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchRow(String title, String subtitle, bool value, Function(bool) onChanged,
      {bool isDark = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 44,
              height: 26,
              decoration: BoxDecoration(
                color: value ? (color ?? const Color(0xFF10B981)) : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D5DB)),
                borderRadius: BorderRadius.circular(13),
              ),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.only(right: value ? 18 : 3),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF111827),
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF717174) : const Color(0xFF8E8E93),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nowPlayingCard(bool isDark, Color primaryColor) {
    final isReciting = _phase == 'reciting';
    final phaseColor = isReciting
        ? const Color(0xFF10B981)
        : (_phase == 'announcing' ? const Color(0xFF2563EB) : const Color(0xFFFF9500));
    final phaseLabel = _phase == 'idle'
        ? 'Prêt'
        : (_phase == 'announcing' ? 'Annonce' : (_phase == 'reciting' ? 'Récitation' : 'Traduction'));

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E).withOpacity(0.85) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isReciting ? const Color(0xFF10B981) : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isReciting ? const Color(0xFF10B981).withOpacity(0.25) : Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: isReciting ? 1 : 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: phaseColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            phaseLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isRunning)
                      Text(
                        'Rép. $_repeatIndex${_infiniteLoop ? ' ∞' : ''}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                      ),
                  ],
                ),

                if (_currentSurahName != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '$_currentSurahName',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Verset $_currentVerseNum',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Toggle chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('Arabe', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      selected: _showArabic,
                      onSelected: (v) => setState(() => _showArabic = v),
                      selectedColor: primaryColor,
                      labelStyle: TextStyle(
                        color: _showArabic ? Colors.white : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Phonétique', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      selected: _showTransliteration,
                      onSelected: (v) => setState(() => _showTransliteration = v),
                      selectedColor: primaryColor,
                      labelStyle: TextStyle(
                        color: _showTransliteration ? Colors.white : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('Traduction', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      selected: _showTranslation,
                      onSelected: (v) => setState(() => _showTranslation = v),
                      selectedColor: primaryColor,
                      labelStyle: TextStyle(
                        color: _showTranslation ? Colors.white : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ],
                ),

                if (_showArabic && _arabicText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isReciting ? const Color(0xFF10B981) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _arabicText,
                      style: TextStyle(
                        fontSize: 26,
                        height: 1.8,
                        color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],

                if (_showTransliteration && _transliterationText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _transliterationText,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                if (_showTranslation && _translationText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _translationText,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DOWNLOAD SCREEN
// ============================================================

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  String _reciter = 'ar.alafasy';
  int _startSurah = 1;
  int _endSurah = 1;
  bool _isDownloading = false;
  int _totalVerses = 0;
  int _downloadedVerses = 0;
  Directory? _cacheDir;
  Set<String> _cachedFiles = {};
  int _totalCached = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    _cacheDir = Directory('${(await getApplicationDocumentsDirectory()).path}/recitations');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    await _refreshCacheList();
    if (mounted) setState(() {});
  }

  Future<void> _refreshCacheList() async {
    if (_cacheDir == null || !await _cacheDir!.exists()) return;
    final files = await _cacheDir!.list().toList();
    _cachedFiles = files.whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
    _totalCached = _cachedFiles.length;
    if (mounted) setState(() {});
  }

  int _countCachedForSurah(int surah) {
    int count = 0;
    for (int v = 1; v <= kAyahCounts[surah - 1]; v++) {
      final fn = recitationFilename(_reciter, surah, v);
      if (_cachedFiles.contains(fn)) count++;
    }
    return count;
  }

  Future<void> _downloadSurah(int surah) async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _totalVerses = kAyahCounts[surah - 1];
      _downloadedVerses = 0;
    });

    try {
      if (_cacheDir == null) {
        _cacheDir = Directory('${(await getApplicationDocumentsDirectory()).path}/recitations');
        if (!await _cacheDir!.exists()) await _cacheDir!.create(recursive: true);
      }

      final total = kAyahCounts[surah - 1];
      for (int v = 1; v <= total; v++) {
        final fn = recitationFilename(_reciter, surah, v);
        if (_cachedFiles.contains(fn)) {
          setState(() => _downloadedVerses = v);
          continue;
        }

        final url = await fetchRecitationUrl(_reciter, surah, v);
        if (url == null) continue;

        try {
          final client = http.Client();
          final request = http.Request('GET', Uri.parse(url));
          final response = await client.send(request);
          if (response.statusCode == 200) {
            final bytes = await response.stream.toBytes();
            final file = File('${_cacheDir!.path}/$fn');
            await file.writeAsBytes(bytes);
            _cachedFiles.add(fn);
          }
          client.close();
        } catch (e) {
          debugPrint('Download verse $surah:$v error: $e');
        }

        setState(() => _downloadedVerses = v);
        await Future.delayed(const Duration(milliseconds: 300));
      }

      await _refreshCacheList();
    } catch (e) {
      debugPrint('Download surah error: $e');
    }

    setState(() => _isDownloading = false);
  }

  Future<void> _deleteSurahCache(int surah) async {
    if (_cacheDir == null || !await _cacheDir!.exists()) return;
    int deleted = 0;
    for (int v = 1; v <= kAyahCounts[surah - 1]; v++) {
      final fn = recitationFilename(_reciter, surah, v);
      final file = File('${_cacheDir!.path}/$fn');
      if (await file.exists()) {
        await file.delete();
        _cachedFiles.remove(fn);
        deleted++;
      }
    }
    await _refreshCacheList();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Supprimé: $deleted fichiers')),
      );
    }
  }

  Future<void> _deleteAllCache() async {
    if (_cacheDir == null || !await _cacheDir!.exists()) return;
    final files = await _cacheDir!.list().toList();
    int deleted = 0;
    for (var f in files) {
      if (f is File) {
        await f.delete();
        deleted++;
      }
    }
    _cachedFiles.clear();
    await _refreshCacheList();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tout supprimé: $deleted fichiers')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Téléchargements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _refreshCacheList,
          ),
          if (!_isDownloading && _totalCached > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Tout supprimer',
              onPressed: _deleteAllCache,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B980).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cache local', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        '$_totalCached fichiers en cache — Lecture hors-ligne possible',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Reciter selector
          _glassCard(isDark, [
            const Text('Récitateur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _reciter,
              isExpanded: true,
              items: kReciters.map((r) => DropdownMenuItem(
                value: r['id'] as String,
                child: Text(r['label'] as String, style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: _isDownloading ? null : (v) {
                setState(() => _reciter = v!);
                _refreshCacheList();
              },
              underline: const SizedBox(),
              dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            ),
          ]),

          const SizedBox(height: 12),

          // Range selector
          _glassCard(isDark, [
            const Text('Plage à télécharger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('De:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<int>(
                    value: _startSurah,
                    isExpanded: true,
                    items: List.generate(114, (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1}. ${kSurahNames[i]}', style: const TextStyle(fontSize: 12)),
                    )),
                    onChanged: _isDownloading ? null : (v) {
                      if (v != null && v > _endSurah) {
                        setState(() { _startSurah = v; _endSurah = v; });
                      } else if (v != null) {
                        setState(() => _startSurah = v);
                      }
                    },
                    underline: const SizedBox(),
                    dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('À:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<int>(
                    value: _endSurah,
                    isExpanded: true,
                    items: List.generate(114, (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1}. ${kSurahNames[i]}', style: const TextStyle(fontSize: 12)),
                    )),
                    onChanged: _isDownloading ? null : (v) {
                      if (v != null && v < _startSurah) {
                        setState(() { _endSurah = v; _startSurah = v; });
                      } else if (v != null) {
                        setState(() => _endSurah = v);
                      }
                    },
                    underline: const SizedBox(),
                    dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  ),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 14),

          // Download button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDownloading ? const Color(0xFF8E8E93) : const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _isDownloading ? null : () async {
                for (int s = _startSurah; s <= _endSurah; s++) {
                  await _downloadSurah(s);
                }
              },
              icon: Icon(_isDownloading ? Icons.hourglass_empty : Icons.download, size: 22),
              label: Text(
                _isDownloading
                    ? 'Téléchargement... $_downloadedVerses/$_totalVerses'
                    : 'Télécharger $_startSurah à $_endSurah',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),

          if (_isDownloading) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _totalVerses > 0 ? _downloadedVerses / _totalVerses : 0,
              backgroundColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB),
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
              '$_downloadedVerses / $_totalVerses versets',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Surah list header
          const Text('État du cache', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.3)),
          const SizedBox(height: 8),

          // Surah list
          ...List.generate(114, (i) {
            final surahNum = i + 1;
            final total = kAyahCounts[i];
            final cached = _countCachedForSurah(surahNum);
            final isComplete = cached >= total;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isComplete ? Icons.cloud_done : cached > 0 ? Icons.cloud_download : Icons.cloud_upload_outlined,
                      color: isComplete ? const Color(0xFF10B981) : cached > 0 ? const Color(0xFFFF9500) : const Color(0xFF8E8E93),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${surahNum}. ${kSurahNames[i]}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '$cached / $total versets',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF717174) : const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isComplete)
                      IconButton(
                        icon: const Icon(Icons.download, size: 18),
                        tooltip: 'Télécharger',
                        onPressed: _isDownloading ? null : () => _downloadSurah(surahNum),
                        color: primaryColor,
                        iconSize: 18,
                      ),
                    if (cached > 0)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        tooltip: 'Supprimer',
                        onPressed: _isDownloading ? null : () => _deleteSurahCache(surahNum),
                        color: const Color(0xFFEF4444),
                        iconSize: 18,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _glassCard(bool isDark, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB),
          width: 0.5,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}
