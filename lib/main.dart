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

/// Build recitation filename for local cache
String recitationFilename(String reciter, int surah, int verse) {
  return '${reciter.replaceAll('.', '_')}_${surah.toString().padLeft(3, '0')}_${verse.toString().padLeft(3, '0')}.mp3';
}

/// Get recitation audio URL from API
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

/// Download and cache a recitation MP3
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

/// Fetch arabic text for an ayah
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

/// Fetch translation for an ayah
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

/// Fetch transliteration for an ayah
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
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF9FAFB),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF2563EB),
                surface: Colors.white,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                backgroundColor: Color(0xFFF9FAFB),
                foregroundColor: Color(0xFF111827),
                elevation: 0,
                scrolledUnderElevation: 0,
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF000000),
              cardTheme: CardThemeData(
                color: const Color(0xFF1C1C1E),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF2C2C2E), width: 1),
                ),
              ),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF3B82F6),
                surface: Color(0xFF1C1C1E),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                backgroundColor: Color(0xFF000000),
                foregroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            home: const QuranHome(),
          );
        },
      ),
    );
  }
}

// ============================================================
// HOME (tab navigation)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

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
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB), width: 0.5)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          backgroundColor: Colors.transparent,
          indicatorColor: primaryColor.withOpacity(0.15),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.play_circle_outline, color: Colors.grey),
              selectedIcon: Icon(Icons.play_circle_fill, color: primaryColor),
              label: 'Lecture',
            ),
            NavigationDestination(
              icon: const Icon(Icons.cloud_download_outlined, color: Colors.grey),
              selectedIcon: Icon(Icons.cloud_download, color: primaryColor),
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
  // Mode: range, page, single, loop
  String _mode = 'single';

  // Range mode
  int _startSurah = 1, _startVerse = 1, _endSurah = 1, _endVerse = 7;
  int _pageNumber = 1;

  // Single mode
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
  int _repeatIndex = 0;
  int _progressDone = 0;
  int _progressTotal = 0;
  String? _error;
  bool _isRunning = false;
  bool _stopFlag = false;

  // Audio players - recitation + TTS
  final _player = AudioPlayer();
  final _ttsPlayer = AudioPlayer();

  // Local TTS
  final FlutterTts _flutterTts = FlutterTts();
  Completer<void>? _ttsCompleter;
  Map<String, String> _selectedVoice = {}; // {'name': '...', 'locale': '...'}
  List<Map<String, dynamic>> _availableVoices = [];

  // Controllers
  late final TextEditingController _startSurahCtrl = TextEditingController(text: '1');
  late final TextEditingController _startVerseCtrl = TextEditingController(text: '1');
  late final TextEditingController _endSurahCtrl = TextEditingController(text: '1');
  late final TextEditingController _endVerseCtrl = TextEditingController(text: '7');
  late final TextEditingController _pageNumberCtrl = TextEditingController(text: '1');
  late final TextEditingController _singleSurahCtrl = TextEditingController(text: '1');
  late final TextEditingController _singleVerseCtrl = TextEditingController(text: '1');

  // Cache directory
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
      ));
      await session.setActive(true);
      session.interruptionEventStream.listen((event) {
        debugPrint('Audio interruption: begin=${event.begin}, type=${event.type}');
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
        debugPrint('Headphones disconnected');
        _player.pause();
      });
      debugPrint('Audio session configured: music (background-ready)');
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

      // Load available voices
      final voices = await _flutterTts.getVoices;
      _availableVoices = List<Map<String, dynamic>>.from(
        voices.where((v) => v is Map).map((v) => Map<String, dynamic>.from(v))
      );
      debugPrint('Available TTS voices: ${_availableVoices.length}');

      // Load saved voice or pick defaults
      await _loadPrefs();

      // Set completion handler
      _flutterTts.setCompletionHandler(() {
        debugPrint('TTS: completion handler called');
        if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
          _ttsCompleter!.complete();
        }
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS error: $msg');
        if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
          _ttsCompleter!.complete();
        }
        if (mounted) setState(() { _error = 'Erreur TTS: $msg'; });
      });

      debugPrint('TTS initialized OK');
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

      // Load cache dir
      _cacheDir = Directory('${(await getApplicationDocumentsDirectory()).path}/recitations');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      // Load voice selection
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
    // DO NOT dispose _player (known flutter bug)
    _flutterTts.stop();
    _startSurahCtrl.dispose();
    _startVerseCtrl.dispose();
    _endSurahCtrl.dispose();
    _endVerseCtrl.dispose();
    _pageNumberCtrl.dispose();
    _singleSurahCtrl.dispose();
    _singleVerseCtrl.dispose();
    super.dispose();
  }

  void _stop() {
    _stopFlag = true;
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

  // -----------------------------------------------------------
  // LOCAL TTS
  // -----------------------------------------------------------

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

    // Use native TTS for French/English if available
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
          await _ttsCompleter!.future.timeout(
            const Duration(seconds: 3),
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

    // HTTP Google TTS is 100% reliable on iOS for Arabic & fallbacks
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

  // -----------------------------------------------------------
  // RECITATION PLAYBACK (with local cache)
  // -----------------------------------------------------------

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
        // Play from local cache
        debugPrint('Recitation: playing from cache ${file.path}');
        await _player.setFilePath(file.path);
      } else {
        // Download and play
        final url = await fetchRecitationUrl(_reciter, surah, verse);
        if (url == null) {
          debugPrint('Recitation: no URL for $surah:$verse');
          return;
        }
        debugPrint('Recitation: downloading $url');
        try {
          final client = http.Client();
          final request = http.Request('GET', Uri.parse(url));
          final response = await client.send(request);
          if (response.statusCode == 200) {
            final bytes = await response.stream.toBytes();
            await file.writeAsBytes(bytes);
            debugPrint('Recitation: saved to cache ${file.path}');
            await _player.setFilePath(file.path);
          } else {
            debugPrint('Recitation: download failed ${response.statusCode}');
            return;
          }
          client.close();
        } catch (e) {
          debugPrint('Recitation download error: $e');
          return;
        }
      }

      if (!_stopFlag && mounted) {
        await _player.play();
        debugPrint('Recitation: started playback');
        await _waitForPlayerStopped();
        debugPrint('Recitation: done');
      }
    } catch (e) {
      debugPrint('Recitation error: $e');
    }
  }

  // -----------------------------------------------------------
  // TEST BUTTONS
  // -----------------------------------------------------------

  Future<void> _testAudio() async {
    _stopFlag = false;
    try {
      final filename = recitationFilename(_reciter, 1, 1);
      final file = File('${_cacheDir?.path ?? ''}/$filename');
      setState(() { _error = null; _phase = 'reciting'; });

      if (await file.exists()) {
        debugPrint('TEST: playing from cache');
        await _player.setFilePath(file.path);
      } else {
        final url = 'https://verses.quran.gov/Alafasy/001001.mp3';
        debugPrint('TEST: playing $url');
        await _player.setUrl(url);
      }
      await _player.play();
      await _waitForPlayerStopped();
      debugPrint('TEST: done');
      if (mounted) setState(() => _phase = 'idle');
    } catch (e) {
      debugPrint('TEST error: $e');
      if (mounted) setState(() => _error = 'TEST erreur: $e');
    }
  }

  Future<void> _testTts() async {
    _stopFlag = false;
    try {
      setState(() { _error = null; _phase = 'announcing'; });
      await _speak('Sourate Al-Fatiha, verset 1. Loué soit Dieu, maître de l\'univers', _lang);
      if (mounted) setState(() => _phase = 'idle');
    } catch (e) {
      debugPrint('TEST TTS error: $e');
      if (mounted) setState(() => _error = 'TEST TTS erreur: $e');
    }
  }

  // -----------------------------------------------------------
  // MAIN SEQUENCE
  // -----------------------------------------------------------

  Future<void> _runSequence(List<Map<String, int>> seq,
      {int repeats = 3, bool infinite = false, bool withTranslation = true, bool withRecitation = true}) async {
    _stopFlag = false;
    _isRunning = true;
    int done = 0;
    int rep = 0;
    int lastSurah = -1;

    while (!_stopFlag && (infinite || rep < repeats)) {
      rep++;
      if (mounted) setState(() => _repeatIndex = rep);

      for (var ref in seq) {
        if (_stopFlag) break;
        int surah = ref['surah']!;
        int verse = ref['verse']!;

        // Announce surah name & initial verse ONCE when entering a new surah
        if (surah != lastSurah) {
          String surahName = (surah >= 1 && surah <= 114) ? kSurahNames[surah - 1] : 'Sourate $surah';
          String surahNameAr = (surah >= 1 && surah <= 114) ? kSurahNamesArabic[surah - 1] : '$surah';
          lastSurah = surah;

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
            await _speak('سورة $surahNameAr', 'ar');
            await _waitForTtsPlayerStopped();
            if (_stopFlag) break;

            final verseText = _lang == 'fr' ? 'Verset $verse' : 'Verse $verse';
            await _speak(verseText, _lang);
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

        // Asynchronous Arabic & Transliteration text fetch (non-blocking)
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

        // Audio recitation (LOCAL CACHE)
        if (withRecitation) {
          await _playRecitation(surah, verse);
        }

        // Translation (still spoken by local TTS)
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

  // -----------------------------------------------------------
  // UI HELPERS
  // -----------------------------------------------------------

  Widget _card(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  void _syncControllers() {
    if (_startSurahCtrl.text != _startSurah.toString()) _startSurahCtrl.text = _startSurah.toString();
    if (_startVerseCtrl.text != _startVerse.toString()) _startVerseCtrl.text = _startVerse.toString();
    if (_endSurahCtrl.text != _endSurah.toString()) _endSurahCtrl.text = _endSurah.toString();
    if (_endVerseCtrl.text != _endVerse.toString()) _endVerseCtrl.text = _endVerse.toString();
    if (_pageNumberCtrl.text != _pageNumber.toString()) _pageNumberCtrl.text = _pageNumber.toString();
    if (_singleSurahCtrl.text != _singleSurah.toString()) _singleSurahCtrl.text = _singleSurah.toString();
    if (_singleVerseCtrl.text != _singleVerse.toString()) _singleVerseCtrl.text = _singleVerse.toString();
  }

  Widget _inputRow(String label, int value, int min, int max, Function(int) onChanged,
      {required TextEditingController ctrl}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF111827))),
          SizedBox(
            width: 75,
            height: 38,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF111827)),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

  // -----------------------------------------------------------
  // FULL SCREEN MUSIC PLAYER VIEW
  // -----------------------------------------------------------

  Widget _buildFullScreenPlayer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isPlaying = _player.playing || _ttsPlayer.playing;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => setState(() => _showFullScreenPlayer = false),
          tooltip: 'Réduire',
        ),
        title: Column(
          children: [
            Text(
              _currentSurahName ?? 'Sourate $_singleSurah',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Verset ${_currentVerseNum ?? _singleVerse}',
              style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _phase == 'reciting'
                  ? const Color(0xFF10B981)
                  : (_phase == 'announcing' ? Colors.blue : Colors.orange),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _phase == 'idle'
                    ? 'Prêt'
                    : (_phase == 'announcing' ? '🔊 Annonce' : (_phase == 'reciting' ? '📖 Récitation' : '🌍 Traduction')),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Option Toggles (Arabe, Phonétique, Traduction)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilterChip(
                    label: const Text('Arabe', style: TextStyle(fontSize: 12)),
                    selected: _showArabic,
                    onSelected: (v) => setState(() => _showArabic = v),
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(color: _showArabic ? Colors.white : null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Phonétique', style: TextStyle(fontSize: 12)),
                    selected: _showTransliteration,
                    onSelected: (v) => setState(() => _showTransliteration = v),
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(color: _showTransliteration ? Colors.white : null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Traduction', style: TextStyle(fontSize: 12)),
                    selected: _showTranslation,
                    onSelected: (v) => setState(() => _showTranslation = v),
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(color: _showTranslation ? Colors.white : null),
                  ),
                ],
              ),
            ),

            // Scrollable Verse Display
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (_showArabic && _arabicText.isNotEmpty) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _phase == 'reciting'
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _phase == 'reciting'
                                ? const Color(0xFF10B981)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _phase == 'reciting'
                                  ? const Color(0xFF10B981)
                                  : Colors.black,
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          _arabicText,
                          style: TextStyle(
                            fontSize: 32,
                            height: 1.9,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],

                    if (_showTransliteration && _transliterationText.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _transliterationText,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    if (_showTranslation && _translationText.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _translationText,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Music Player Control Dock
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                  if (_progressTotal > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        value: _progressTotal > 0 ? _progressDone / _progressTotal : 0,
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        color: primaryColor,
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 34),
                        tooltip: 'Sourate précédente',
                        onPressed: _prevSurah,
                      ),
                      IconButton(
                        icon: const Icon(Icons.fast_rewind_rounded, size: 30),
                        tooltip: 'Verset précédent',
                        onPressed: _prevVerse,
                      ),
                      FloatingActionButton.large(
                        onPressed: _togglePausePlay,
                        backgroundColor: primaryColor,
                        elevation: 4,
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fast_forward_rounded, size: 30),
                        tooltip: 'Verset suivant',
                        onPressed: _nextVerse,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 34),
                        tooltip: 'Sourate suivante',
                        onPressed: _nextSurah,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: 140,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        _stop();
                        setState(() => _showFullScreenPlayer = false);
                      },
                      icon: const Icon(Icons.stop_rounded, size: 18),
                      label: const Text('Arrêter', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // BUILD
  // -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_showFullScreenPlayer) {
      return _buildFullScreenPlayer(context);
    }

    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecture du Coran'),
        actions: [
          IconButton(
            icon: Icon(appState.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round),
            tooltip: appState.isDarkMode ? 'Passer en mode clair' : 'Passer en mode sombre',
            onPressed: () => appState.toggleTheme(!appState.isDarkMode),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // iOS Segmented Mode Picker
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFD1D5DB), width: 1),
            ),
            child: Row(
              children: ['single', 'range', 'page', 'loop'].map((m) {
                final selected = _mode == m;
                final label = m == 'single' ? 'Verset' : m == 'range' ? 'Plage' : m == 'page' ? 'Page' : 'Boucle';
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mode = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: selected && !isDark
                            ? [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: selected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Mode-specific inputs
          if (_mode == 'range')
            _card([
              _inputRow('Sourate début', _startSurah, 1, 114, (v) => setState(() { _startSurah = v; _syncControllers(); }), ctrl: _startSurahCtrl),
              _inputRow('Verset début', _startVerse, 1, 286, (v) => setState(() { _startVerse = v; _syncControllers(); }), ctrl: _startVerseCtrl),
              _inputRow('Sourate fin', _endSurah, 1, 114, (v) => setState(() { _endSurah = v; _syncControllers(); }), ctrl: _endSurahCtrl),
              _inputRow('Verset fin', _endVerse, 1, 286, (v) => setState(() { _endVerse = v; _syncControllers(); }), ctrl: _endVerseCtrl),
            ]),
          if (_mode == 'page')
            _card([
              _inputRow('Page (1–604)', _pageNumber, 1, 604,
                  (v) => setState(() { _pageNumber = v; _syncControllers(); }), ctrl: _pageNumberCtrl),
            ]),
          if (_mode == 'single' || _mode == 'loop')
            _card([
              _inputRow('Sourate', _singleSurah, 1, 114, (v) => setState(() { _singleSurah = v; _syncControllers(); }), ctrl: _singleSurahCtrl),
              _inputRow('Verset', _singleVerse, 1, 286, (v) => setState(() { _singleVerse = v; _syncControllers(); }), ctrl: _singleVerseCtrl),
            ]),

          const SizedBox(height: 12),

          // Settings card
          _card([
            const Text('Options de lecture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            SwitchListTile(
              title: const Text('Annoncer Sourate + Verset'),
              subtitle: const Text('"Sourate Al-Fatiha, verset 1"'),
              value: _announceSurahVerse,
              onChanged: (v) {
                setState(() => _announceSurahVerse = v);
                _savePref('announceSurahVerse', v);
              },
            ),
            SwitchListTile(
              title: const Text('Annoncer juste "Verset X"'),
              subtitle: const Text('Optionnel, en plus de l\'annonce de sourate'),
              value: _announceVerseOnly,
              onChanged: (v) => setState(() => _announceVerseOnly = v),
            ),
            SwitchListTile(
              title: const Text('Lire la récitation'),
              subtitle: const Text('Audio local (cached)'),
              value: _speakRecitation,
              onChanged: (v) {
                setState(() => _speakRecitation = v);
                _savePref('speakRecitation', v);
              },
            ),
            SwitchListTile(
              title: const Text('Lire la traduction'),
              value: _speakTranslation,
              onChanged: (v) {
                setState(() => _speakTranslation = v);
                _savePref('speakTranslation', v);
              },
            ),
            SwitchListTile(
              title: const Text('Boucle infinie'),
              subtitle: const Text('Répéter indéfiniment'),
              value: _infiniteLoop,
              onChanged: (v) => setState(() => _infiniteLoop = v),
            ),
            if (!_infiniteLoop)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Text('Répétitions: '),
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
                      ),
                    ),
                    Text('x$_repeatCount'),
                  ],
                ),
              ),
            const Divider(),

            // ---- VOICE SELECTION ----
            const Text('🗣 Voix TTS (local)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Voix système — fonctionne hors-ligne', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),

            // Language selector
            Row(
              children: [
                const Text('Langue:'),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Français'),
                  selected: _lang == 'fr',
                  onSelected: (v) {
                    setState(() => _lang = 'fr');
                    _savePref('lang', 'fr');
                    _selectDefaultVoice();
                  },
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
                ),
              ],
            ),
            const SizedBox(height: 8),



            // ---- RECITER ----
            Row(
              children: [
                const Text('Récitateur:'),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _reciter,
                    isExpanded: true,
                    items: kReciters
                        .map((r) => DropdownMenuItem<String>(
                              value: r['id'] as String,
                              child: Text(r['label'] as String, style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _reciter = v!);
                      _savePref('reciter', v);
                    },
                  ),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 12),

          // iOS Style Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isRunning ? null : _play,
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text('Lancer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    disabledBackgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isRunning ? _stop : null,
                  icon: const Icon(Icons.stop_rounded, size: 22),
                  label: const Text('Arrêter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Test buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isRunning ? null : _testAudio,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: Text('🔊 TEST Audio', style: TextStyle(fontSize: 13))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isRunning ? null : _testTts,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: Text('🗣 TEST TTS', style: TextStyle(fontSize: 13))),
                  ),
                ),
              ),
            ],
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('⚠️ $_error', style: const TextStyle(color: Colors.red)),
            ),

          if (_progressTotal > 0)
            Column(
              children: [
                const SizedBox(height: 12),
                LinearProgressIndicator(
                    value: _progressTotal > 0 ? _progressDone / _progressTotal : 0),
                Text('$_progressDone / $_progressTotal'),
              ],
            ),

          // Display (iOS Liquid Glass Now Playing Player Card)
          if (_arabicText.isNotEmpty || _isRunning)
            Container(
              margin: const EdgeInsets.only(top: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _phase == 'reciting'
                            ? const Color(0xFF10B981)
                            : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB)),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _phase == 'reciting'
                              ? const Color(0xFF10B981)
                              : Colors.black,
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: _phase == 'reciting'
                                    ? const Color(0xFF10B981)
                                    : _phase == 'announcing'
                                        ? Colors.blue
                                        : Colors.orange,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _phase == 'reciting'
                                      ? const Color(0xFF10B981)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _phase == 'reciting'
                                          ? const Color(0xFF10B981)
                                          : _phase == 'announcing'
                                              ? Colors.blue
                                              : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _phase == 'idle'
                                        ? 'Prêt'
                                        : _phase == 'announcing'
                                            ? '🔊 Annonce'
                                            : _phase == 'reciting'
                                                ? '📖 Récitation'
                                                : '🌍 Traduction',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _phase == 'reciting'
                                          ? const Color(0xFF10B981)
                                          : _phase == 'announcing'
                                              ? Colors.blue
                                              : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Répétition $_repeatIndex${_infiniteLoop ? ' (∞)' : ''}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        if (_currentSurahName != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            '$_currentSurahName — Verset $_currentVerseNum',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981), letterSpacing: 0.3),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Toggles mode lecture (Arabe, Phonétique, Traduction)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilterChip(
                              label: const Text('Arabe', style: TextStyle(fontSize: 11)),
                              selected: _showArabic,
                              onSelected: (v) => setState(() => _showArabic = v),
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 6),
                            FilterChip(
                              label: const Text('Phonétique', style: TextStyle(fontSize: 11)),
                              selected: _showTransliteration,
                              onSelected: (v) => setState(() => _showTransliteration = v),
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 6),
                            FilterChip(
                              label: const Text('Traduction', style: TextStyle(fontSize: 11)),
                              selected: _showTranslation,
                              onSelected: (v) => setState(() => _showTranslation = v),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),

                        if (_showArabic && _arabicText.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: _phase == 'reciting'
                                  ? const Color(0xFF10B981)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _arabicText,
                              style: TextStyle(
                                fontSize: 28,
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
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _transliterationText,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        if (_showTranslation && _translationText.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _translationText,
                              style: TextStyle(
                                fontSize: 15,
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
            ),
        ],
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
        await Future.delayed(const Duration(milliseconds: 300)); // Rate limit
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Supprimé: $deleted fichiers')),
      );
      setState(() {});
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tout supprimé: $deleted fichiers')),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Téléchargements'),
        actions: [
          if (!_isDownloading)
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
          _cardInfo(
            icon: Icons.info_outline,
            title: 'Cache local',
            subtitle: 'Téléchargez les récitations pour une lecture hors-ligne',
          ),

          const SizedBox(height: 12),

          // Reciter selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Récitateur', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _reciter,
                    isExpanded: true,
                    items: kReciters
                        .map((r) => DropdownMenuItem(
                              value: r['id'] as String,
                              child: Text(r['label'] as String, style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: _isDownloading ? null : (v) {
                      setState(() => _reciter = v!);
                      _refreshCacheList();
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Range selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Plage à télécharger', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('De: '),
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
                        ),
                      ),
                      const Text('  À: '),
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
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Download button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDownloading ? Colors.grey : const Color(0xFF1B5E20),
              padding: const EdgeInsets.all(16),
            ),
            onPressed: _isDownloading ? null : () async {
              for (int s = _startSurah; s <= _endSurah; s++) {
                await _downloadSurah(s);
              }
            },
            icon: Icon(_isDownloading ? Icons.hourglass_empty : Icons.download),
            label: Text(
              _isDownloading
                  ? 'Téléchargement... $_downloadedVerses/$_totalVerses'
                  : 'Télécharger Sourate $_startSurah à $_endSurah',
              style: const TextStyle(color: Colors.white),
            ),
          ),

          if (_isDownloading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _totalVerses > 0 ? _downloadedVerses / _totalVerses : 0,
            ),
          ],

          const SizedBox(height: 20),

          // List of surahs with cache status
          const Text('État du cache par sourate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),

          ...List.generate(114, (i) {
            final surahNum = i + 1;
            final total = kAyahCounts[i];
            final cached = _countCachedForSurah(surahNum);
            final isComplete = cached >= total;

            return Card(
              child: ListTile(
                leading: Icon(
                  isComplete ? Icons.cloud_done : cached > 0 ? Icons.cloud_download : Icons.cloud_upload_outlined,
                  color: isComplete ? Colors.green : cached > 0 ? Colors.orange : Colors.grey,
                ),
                title: Text('${i + 1}. ${kSurahNames[i]}', style: const TextStyle(fontSize: 13)),
                subtitle: Text('$cached/$total versets', style: const TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isComplete)
                      IconButton(
                        icon: const Icon(Icons.download, size: 20),
                        tooltip: 'Télécharger',
                        onPressed: _isDownloading ? null : () => _downloadSurah(surahNum),
                      ),
                    if (cached > 0)
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        tooltip: 'Supprimer',
                        onPressed: _isDownloading ? null : () => _deleteSurahCache(surahNum),
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

  Widget _cardInfo({required IconData icon, required String title, required String subtitle}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1B5E20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
