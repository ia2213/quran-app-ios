import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() => runApp(const QuranApp());

// ============================================================
// DATA
// ============================================================

const kBase = 'https://api.alquran.cloud/v1';
const kTotalPages = 604;

const kReciters = [
  {'id': 'ar.alafasy',      'label': 'Mishary Rashid Al-Afasy'},
  {'id': 'ar.husary',       'label': 'Mahmoud Khalil Al-Husary'},
  {'id': 'ar.minshawi',     'label': 'Mohamed Siddiq El-Minshawi'},
  {'id': 'ar.abdulbasitmurattal', 'label': 'Abdul Basit (Murattal)'},
  {'id': 'ar.abdulsamad',   'label': 'Abdul Basit (Mujawwad)'},
  {'id': 'ar.shaatree',     'label': 'Al-Shaatree'},
  {'id': 'ar.abdurrahmansudais', 'label': 'Abdurrahman As-Sudais'},
  {'id': 'ar.abdullahalmasmad', 'label': 'Abdullah Al-Masmad'},
  {'id': 'ar.maabooralmoajil', 'label': 'Maabooralmoajil'},
  {'id': 'ar.hudhaifi',     'label': 'Ali Al-Hudhaifi'},
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
  'As-Saff','Al-Jumu\'a','Al-Munaafiqoon','At-Taghaabun','At-Talaaq',
  'At-Tahrim','Al-Mulk','Al-Qalam','Al-Haaqqa','Al-Ma\'aarij',
  'Nooh','Al-Jinn','Al-Muzzammil','Al-Muddaththir','Al-Qiyaama',
  'Al-Insaan','An-Naba',"An-Naazi'at","Abasa","At-Takwir",
  'Al-Infitaar','Al-Mutaffifin','Al-Inshiqaaq','Al-Burooj','At-Taariq',
  "Al-A'laa","Al-Ghaashiya","Al-Fajr","Al-Balad","Ash-Shams",
  'Al-Lail','Ad-Dhuhaa','Ash-Sharh','At-Tin','Al-Alaq',
  'Al-Qadr','Al-Bayyina','Az-Zalzala','Al-Aadiyaat',"Al-Qaari'a",
  'At-Takaathur','Al-Asr','Al-Humaza','Al-Fil','Quraish',
  "Al-Maa'un",'Al-Kawthar','Al-Kaafiroon','An-Nasr','Al-Masad',
  'Al-Ikhlaas','Al-Falaq','An-Naas',
];

const kAyahCounts = [
  7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,
  112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,
  89,59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,
  12,30,52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,
  30,20,15,21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6,
];

// ============================================================
// MODELS
// ============================================================

class AyahData {
  final int globalNumber;
  final int surahNumber;
  final int numberInSurah;
  final String textAr;
  final String? textFr;
  final String? audioUrl;
  final int page;
  final int juz;
  AyahData({required this.globalNumber, required this.surahNumber, required this.numberInSurah,
            required this.textAr, this.textFr, this.audioUrl, required this.page, required this.juz});
}

class StudyProgress {
  final int ayahGlobalNumber;
  final int surahNumber;
  final int verseNumber;
  final double easeFactor;
  final DateTime nextReview;
  final int interval;
  final int repetitions;
  StudyProgress({required this.ayahGlobalNumber, required this.surahNumber,
                 required this.verseNumber, this.easeFactor = 2.5,
                 required this.nextReview, this.interval = 0, this.repetitions = 0});
  Map<String, dynamic> toJson() => {
    'ayahGlobalNumber': ayahGlobalNumber, 'surahNumber': surahNumber,
    'verseNumber': verseNumber, 'easeFactor': easeFactor,
    'nextReview': nextReview.toIso8601String(),
    'interval': interval, 'repetitions': repetitions,
  };
  factory StudyProgress.fromJson(Map<String, dynamic> j) => StudyProgress(
    ayahGlobalNumber: j['ayahGlobalNumber'], surahNumber: j['surahNumber'],
    verseNumber: j['verseNumber'], easeFactor: j['easeFactor']?.toDouble() ?? 2.5,
    nextReview: DateTime.parse(j['nextReview']),
    interval: j['interval'] ?? 0, repetitions: j['repetitions'] ?? 0,
  );
}

// ============================================================
// APP STATE
// ============================================================

class AppState extends ChangeNotifier {
  final List<Map<String, dynamic>> _surahs = [];
  bool _surahLoading = false;
  final List<AyahData> _ayahs = [];
  bool _ayahLoading = false;
  String? _ayahError;
  String _reciter = 'ar.alafasy';
  String _translationLang = 'fr';
  bool _showTranslation = true;
  bool _showTransliteration = false;
  final Map<String, StudyProgress> _studyProgress = {};

  List<Map<String, dynamic>> get surahs => _surahs;
  List<AyahData> get ayahs => _ayahs;
  bool get surahLoading => _surahLoading;
  bool get ayahLoading => _ayahLoading;
  String? get ayahError => _ayahError;
  String get reciter => _reciter;
  String get translationLang => _translationLang;
  bool get showTranslation => _showTranslation;
  bool get showTransliteration => _showTransliteration;
  int get totalStudied => _studyProgress.length;
  int get dueCount => _studyProgress.values.where((p) => p.nextReview.isBefore(DateTime.now())).length;

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
            'englishNameTranslation': s['englishNameTranslation'],
            'numberOfAyahs': s['numberOfAyahs'],
            'revelationType': s['revelationType'],
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading surahs: $e');
    }
    _surahLoading = false;
    notifyListeners();
  }

  Future<void> loadAyahs(int surahNumber) async {
    _ayahLoading = true;
    _ayahError = null;
    notifyListeners();
    try {
      final arR = await http.get(Uri.parse('$kBase/surah/$surahNumber/${_reciter}'));
      if (arR.statusCode != 200) throw Exception('Failed to load ayahs');
      final arD = json.decode(arR.body) as Map<String, dynamic>;

      final trId = _translationLang == 'fr' ? 'fr.hamidullah' : 'en.sahih';
      final trR = await http.get(Uri.parse('$kBase/surah/$surahNumber/$trId'));
      final Map<int, String> translations = {};
      if (trR.statusCode == 200) {
        final trD = json.decode(trR.body) as Map<String, dynamic>;
        for (var a in trD['data']['ayahs'] as List) {
          translations[a['numberInSurah'] as int] = a['text'] as String;
        }
      }

      _ayahs.clear();
      for (var a in arD['data']['ayahs'] as List) {
        final num = a['numberInSurah'] as int;
        _ayahs.add(AyahData(
          globalNumber: a['number'] as int,
          surahNumber: surahNumber,
          numberInSurah: num,
          textAr: a['text'] as String,
          textFr: translations[num] ?? '',
          audioUrl: a['audio'] as String?,
          page: a['page'] as int? ?? 0,
          juz: a['juz'] as int? ?? 0,
        ));
      }
    } catch (e) {
      _ayahError = 'Error: $e';
    }
    _ayahLoading = false;
    notifyListeners();
  }

  Future<void> loadPageAyahs(int pageNum) async {
    _ayahLoading = true;
    _ayahError = null;
    notifyListeners();
    try {
      final arR = await http.get(Uri.parse('$kBase/page/$pageNum/quran-uthmani'));
      if (arR.statusCode != 200) throw Exception('Failed to load page');
      final arD = json.decode(arR.body) as Map<String, dynamic>;

      final trId = _translationLang == 'fr' ? 'fr.hamidullah' : 'en.sahih';
      final trR = await http.get(Uri.parse('$kBase/page/$pageNum/$trId'));
      final Map<int, String> translations = {};
      if (trR.statusCode == 200) {
        final trD = json.decode(trR.body) as Map<String, dynamic>;
        for (var a in trD['data']['ayahs'] as List) {
          translations[a['numberInSurah'] as int] = a['text'] as String;
        }
      }

      _ayahs.clear();
      for (var a in arD['data']['ayahs'] as List) {
        final s = a['surah'] as Map<String, dynamic>;
        final num = a['numberInSurah'] as int;
        _ayahs.add(AyahData(
          globalNumber: a['number'] as int,
          surahNumber: s['number'] as int,
          numberInSurah: num,
          textAr: a['text'] as String,
          textFr: translations[num] ?? '',
          audioUrl: null,
          page: pageNum,
          juz: a['juz'] as int? ?? 0,
        ));
      }
    } catch (e) {
      _ayahError = 'Error: $e';
    }
    _ayahLoading = false;
    notifyListeners();
  }

  void setReciter(String id) { _reciter = id; notifyListeners(); }
  void setTranslationLang(String lang) { _translationLang = lang; notifyListeners(); }
  void toggleTranslation() { _showTranslation = !_showTranslation; notifyListeners(); }
  void toggleTransliteration() { _showTransliteration = !_showTransliteration; notifyListeners(); }

  Future<void> loadStudyProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('study_progress');
      if (data != null) {
        final jm = json.decode(data) as Map<String, dynamic>;
        _studyProgress.clear();
        jm.forEach((k, v) => _studyProgress[k] = StudyProgress.fromJson(v as Map<String, dynamic>));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading study: $e');
    }
  }

  Future<void> saveStudyProgress(StudyProgress p) async {
    final prefs = await SharedPreferences.getInstance();
    _studyProgress['${p.ayahGlobalNumber}'] = p;
    final jm = _studyProgress.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString('study_progress', jsonEncode(jm));
    notifyListeners();
  }

  void resetStudyProgress() async {
    _studyProgress.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('study_progress');
    notifyListeners();
  }

  List<StudyProgress> getDueAyahs() =>
      _studyProgress.values.where((p) => p.nextReview.isBefore(DateTime.now())).toList()
        ..sort((a, b) => a.nextReview.compareTo(b.nextReview));

  AyahData? getAyahByGlobalNumber(int n) {
    try { return _ayahs.firstWhere((a) => a.globalNumber == n); } catch (_) { return null; }
  }

  Map<String, dynamic>? getSurah(int n) {
    try { return _surahs.firstWhere((s) => s['number'] == n); } catch (_) { return null; }
  }
}

// ============================================================
// MAIN APP
// ============================================================

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..loadSurahs()..loadStudyProgress(),
      child: MaterialApp(
        title: 'Quran Learning',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
          appBarTheme: const AppBarTheme(centerTitle: true, backgroundColor: Color(0xFF1B5E20), foregroundColor: Colors.white),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        ),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: ThemeMode.system,
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;
  late final List<Widget> _pages;
  @override
  void initState() {
    super.initState();
    _pages = [const RecitationScreen(), const StudyScreenMain(), const SurahListScreen()];
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: _pages[_idx],
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _idx, type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF1B5E20), unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Récitation'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Étude'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Sourates'),
      ],
      onTap: (i) => setState(() => _idx = i),
    ),
  );
}

// ============================================================
// SURAH LIST
// ============================================================

class SurahListScreen extends StatelessWidget {
  const SurahListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sourates')),
      body: state.surahLoading && state.surahs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.surahs.isEmpty
              ? const Center(child: Text('No surahs loaded'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.surahs.length,
                  itemBuilder: (context, i) {
                    final s = state.surahs[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1B5E20),
                          child: Text(s['number'].toString(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(s['englishName']),
                        subtitle: Text('${s['numberOfAyahs']} Ayahs · ${s['revelationType']}'),
                        trailing: Text(s['name'], style: const TextStyle(fontSize: 18, fontFamily: 'Amiri')),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SurahDetailScreen(surahNumber: s['number']),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ============================================================
// SURAH DETAIL
// ============================================================

class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  const SurahDetailScreen({super.key, required this.surahNumber});
  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = context.read<AppState>();
    _state.loadAyahs(widget.surahNumber);
  }

  Future<String?> _fetchTranslit(int surah, int ayah) async {
    try {
      final r = await http.get(Uri.parse('$kBase/edition/type/transliteration'));
      if (r.statusCode != 200) return null;
      final d = json.decode(r.body) as Map<String, dynamic>;
      var eds = d['data'] as List;
      String? tid = eds.where((e) => (e as Map)['identifier'] == 'en.transliteration').isNotEmpty
          ? 'en.transliteration'
          : (eds.isNotEmpty ? eds.first['identifier'] as String : null);
      if (tid == null) return null;
      final r2 = await http.get(Uri.parse('$kBase/ayah/$surah:$ayah/$tid'));
      if (r2.statusCode == 200) {
        final d2 = json.decode(r2.body) as Map<String, dynamic>;
        return d2['data']['text'] as String?;
      }
    } catch (e) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final surah = state.getSurah(widget.surahNumber);
    return Scaffold(
      appBar: AppBar(
        title: Text(surah?['englishName'] ?? 'Surah ${widget.surahNumber}'),
        actions: [
          IconButton(
            icon: Icon(state.showTranslation ? Icons.translate : Icons.translate_outlined),
            onPressed: state.toggleTranslation,
          ),
          IconButton(
            icon: Icon(state.showTransliteration ? Icons.language : Icons.language_outlined),
            onPressed: state.toggleTransliteration,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.mic),
            tooltip: 'Récitateur',
            onSelected: (v) {
              state.setReciter(v);
              state.loadAyahs(widget.surahNumber);
            },
            itemBuilder: (_) => kReciters
                .map((r) => PopupMenuItem<String>(
                      value: r['id'] as String,
                      child: Text(r['label'] as String),
                    ))
                .toList(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.translate),
            tooltip: 'Traduction',
            onSelected: (v) {
              state.setTranslationLang(v == 'fr' ? 'fr' : 'en');
              state.loadAyahs(widget.surahNumber);
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(value: 'fr', child: Text('Français (Hamidullah)')),
              PopupMenuItem<String>(value: 'en', child: Text('English (Sahih Intl.)')),
            ],
          ),
        ],
      ),
      body: state.ayahLoading
          ? const Center(child: CircularProgressIndicator())
          : state.ayahError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.ayahError!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => state.loadAyahs(widget.surahNumber),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.ayahs.length,
                  itemBuilder: (context, i) {
                    final a = state.ayahs[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                          color: Color(0xFF1B5E20), shape: BoxShape.circle),
                                      child: Center(
                                        child: Text('${a.numberInSurah}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Ayah ${a.numberInSurah}',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (a.juz > 0)
                                      Chip(
                                          label: Text('Juz ${a.juz}'),
                                          padding: EdgeInsets.zero,
                                          labelStyle: const TextStyle(fontSize: 11)),
                                    const SizedBox(width: 8),
                                    if (a.audioUrl != null)
                                      IconButton(
                                        icon: const Icon(Icons.play_circle),
                                        color: Colors.green,
                                        onPressed: () {
                                          // Open audio in system browser
                                          // (no audio player dependency needed)
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(a.textAr,
                                style: const TextStyle(fontSize: 28, fontFamily: 'Amiri', height: 2),
                                textAlign: TextAlign.right),
                            if (state.showTransliteration) ...[
                              const SizedBox(height: 8),
                              FutureBuilder<String?>(
                                future: _fetchTranslit(widget.surahNumber, a.numberInSurah),
                                builder: (ctx, snap) => snap.data != null && snap.data!.isNotEmpty
                                    ? Text(snap.data!,
                                        style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic))
                                    : const SizedBox.shrink(),
                              ),
                            ],
                            if (state.showTranslation &&
                                a.textFr != null &&
                                a.textFr!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(a.textFr!, style: const TextStyle(fontSize: 15)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ============================================================
// RECITATION SCREEN (VersePlayer)
// ============================================================

class RecitationScreen extends StatefulWidget {
  const RecitationScreen({super.key});
  @override
  State<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends State<RecitationScreen> {
  String _mode = 'range';
  int _startSurah = 1, _startVerse = 1, _endSurah = 1, _endVerse = 7;
  int _pageNumber = 1;
  int _singleSurah = 1, _singleVerse = 1;
  bool _translateAfter = true;
  String _lang = 'French';
  String _reciter = 'ar.alafasy';
  int _repeatCount = 3;
  bool _infiniteLoop = false;
  bool _announceEachVerse = false;
  bool _showTransliteration = false;
  bool _speakTranslation = true;
  bool _announceSurah = true;
  bool _ttsFemaleVoice = false; // false = masculine, true = feminine (if available)

  String _phase = 'idle';
  String? _currentSurahName;
  int? _currentVerseNum;
  String _arabicText = '';
  String _transliterationText = '';
  String _translationText = '';
  int _repeatIndex = 0;
  int _progressDone = 0;
  int _progressTotal = 0;
  String? _error;
  bool _isRunning = false;
  bool _stopFlag = false;
  final _player = AudioPlayer();
  String? _currentAudioUrl;
  bool _isPlaying = false;
  bool _isTtsPlaying = false;
  bool _isTtsBuffering = false;
  late final TextEditingController _startSurahCtrl = TextEditingController(text: '1');
  late final TextEditingController _startVerseCtrl = TextEditingController(text: '1');
  late final TextEditingController _endSurahCtrl = TextEditingController(text: '1');
  late final TextEditingController _endVerseCtrl = TextEditingController(text: '7');
  late final TextEditingController _pageNumberCtrl = TextEditingController(text: '1');
  late final TextEditingController _singleSurahCtrl = TextEditingController(text: '1');
  late final TextEditingController _singleVerseCtrl = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _stopFlag = true;
    _player.dispose();
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
    if (mounted) {
      setState(() {
        _phase = 'idle';
        _isRunning = false;
        _repeatIndex = 0;
      });
    }
  }

  // Google TTS cache
  final Map<String, String> _ttsUrlCache = {};
  DateTime? _lastTtsRequest;

  // Build Google TTS URL with client signature for male/female voices
  String _buildGoogleTtsUrl(String text, String lang, bool female) {
    // Remove parentheses
    final clean = text.replaceAll(RegExp(r'[()]'), '');
    // URL encode
    final encoded = Uri.encodeComponent(clean);
    // Different strategies: Arabic uses client param, French uses different client params
    final client = lang == 'ar' ? (female ? 'gws-xsn-dev' : 'tw-ob') : (female ? 'lemon' : 'tw-ob');
    // Slower rate for clarity
    final tl = lang == 'ar' ? 'ar-SA' : (lang == 'en' ? 'en-US' : 'fr-FR');
    return 'https://translate.google.com/translate_tts?ie=UTF-8&tl=$tl&client=$client&q=$encoded';
  }

  Future<String?> _getCachedTtsUrl(String text, String lang, bool female) async {
    if (text.isEmpty) return null;
    final url = _buildGoogleTtsUrl(text, lang, female);
    // Check cache (search by key, not value)
    if (_ttsUrlCache.containsKey(url)) return url;
    _ttsUrlCache[url] = text;
    // Limit cache size
    if (_ttsUrlCache.length > 50) {
      final first = _ttsUrlCache.keys.first;
      _ttsUrlCache.remove(first);
    }
    return url;
  }

  Future<void> _speak(String text, String lang) async {
    if (text.isEmpty || _stopFlag) return;
    try {
      // Rate limit: prevent spamming Google TTS
      if (_lastTtsRequest != null) {
        final elapsed = DateTime.now().difference(_lastTtsRequest!);
        if (elapsed.inMilliseconds < 500) {
          await Future.delayed(Duration(milliseconds: 500 - elapsed.inMilliseconds));
        }
      }
      _lastTtsRequest = DateTime.now();

      final url = await _getCachedTtsUrl(text, lang, _ttsFemaleVoice);
      if (url == null || _stopFlag) return;

      if (mounted) setState(() => _isTtsBuffering = true);
      await _player.stop();
      await _player.setUrl(url);
      if (mounted) setState(() { _isTtsPlaying = true; _isTtsBuffering = false; });
      await _player.play();
      // FIX: Wait for actual audio completion by checking player state, NOT _isTtsPlaying
      // (which is never set to false by playerStateStream — was causing 60s hangs)
      int attempts = 0;
      while (!_stopFlag && attempts < 150) {
        // If player is no longer playing, we're done
        if (!_player.playing) {
          final ps = _player.processingState;
          if (ps == ProcessingState.completed || ps == ProcessingState.idle) break;
        }
        await Future.delayed(const Duration(milliseconds: 300));
        attempts++;
      }
      // Force stop if still stuck (45s max)
      if (_isTtsPlaying) {
        await _player.stop();
        if (mounted) setState(() { _isTtsPlaying = false; _isTtsBuffering = false; });
      }
    } catch (e) {
      debugPrint('TTS error: $e');
    }
    if (mounted) setState(() { _isTtsPlaying = false; _isTtsBuffering = false; });
  }

  // Wait for audio to finish playing (handles all player states correctly)
  Future<void> _waitForPlayerStopped() async {
    for (int i = 0; i < 120; i++) {
      if (_stopFlag) return;
      final ps = _player.processingState;
      // Terminal states: audio completed or errored
      if (ps == ProcessingState.completed || ps == ProcessingState.idle) return;
      // Player is buffering/loading — wait for it to start
      if (!_player.playing) {
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }
      // Player is playing — keep waiting until it stops
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> _runSequence(List<Map<String, int>> seq,
      {int repeats = 3, bool infinite = false, bool withTranslation = true}) async {
    _stopFlag = false;
    _isRunning = true;
    int done = 0;
    int rep = 0;

    while (!_stopFlag && (infinite || rep < repeats)) {
      rep++;
      if (mounted) setState(() => _repeatIndex = rep);
      int lastSurah = -1;

      for (var ref in seq) {
        if (_stopFlag) break;
        int surah = ref['surah']!;
        int verse = ref['verse']!;

        if (mounted) {
          setState(() {
            _currentVerseNum = verse;
            _phase = 'announcing';
          });
        }

        // Announce surah name
        if (surah != lastSurah || _announceEachVerse) {
          String surahEnglish = '';
          String surahArabic = '';
          try {
            final r = await http.get(Uri.parse('$kBase/surah/$surah'));
            if (r.statusCode == 200) {
              final d = json.decode(r.body) as Map<String, dynamic>;
              surahArabic = d['data']['name'] as String;
              surahEnglish = d['data']['englishName'] as String;
              if (mounted) {
                setState(() {
                  _currentSurahName = '$surah · $surahEnglish ($surahArabic)';
                });
              }
            }
          } catch (e) {}
          lastSurah = surah;
          // Announce surah name in Arabic if enabled
          if (_announceSurah && surahArabic.isNotEmpty) {
            if (mounted) setState(() => _phase = 'announcing');
            await _speak(surahArabic, 'ar');
            if (_stopFlag) break;
          }
        }
        if (_stopFlag) break;

        // Announce verse number only if "announce each verse" is checked
        if (_announceSurah && _announceEachVerse) {
          final lang = _lang == 'French' ? 'fr' : 'en';
          final prefix = lang == 'fr' ? 'Verset' : 'Verse';
          await _speak('$prefix $verse', lang);
          if (_stopFlag) break;
        }

        // Fetch arabic text
        if (mounted) setState(() => _phase = 'reciting');
        try {
          final r = await http.get(Uri.parse('$kBase/ayah/$surah:$verse/quran-uthmani'));
          if (r.statusCode == 200) {
            final d = json.decode(r.body) as Map<String, dynamic>;
            if (mounted) setState(() => _arabicText = d['data']['text'] as String? ?? '');
          }
        } catch (e) {
          if (mounted) setState(() => _arabicText = '(texte indisponible)');
        }

        // Transliteration
        if (_showTransliteration) {
          try {
            final tid = await _getTranslitId();
            if (tid != null) {
              final r = await http.get(Uri.parse('$kBase/ayah/$surah:$verse/$tid'));
              if (r.statusCode == 200) {
                final d = json.decode(r.body) as Map<String, dynamic>;
                if (mounted)
                  setState(() => _transliterationText = d['data']['text'] as String? ?? '');
              }
            }
          } catch (e) {
            if (mounted) setState(() => _transliterationText = '');
          }
        } else {
          if (mounted) setState(() => _transliterationText = '');
        }

        await Future.delayed(const Duration(milliseconds: 450));
        if (_stopFlag) break;

        // Audio
        try {
          final r = await http.get(Uri.parse('$kBase/ayah/$surah:$verse/$_reciter'));
          if (r.statusCode == 200) {
            final d = json.decode(r.body) as Map<String, dynamic>;
            final url = d['data']['audio'] as String?;
            if (url != null) {
              if (mounted) setState(() => _currentAudioUrl = url);
              if (!_stopFlag && mounted) {
                try {
                  await _player.setUrl(url);
                  await _player.play();
                  await _waitForPlayerStopped();
                } catch (e) {
                  if (mounted) {
                    setState(() => _currentAudioUrl = null);
                  }
                }
              }
            }
          }
        } catch (e) {}

        // Translation
        if (withTranslation) {
          if (mounted) setState(() => _phase = 'translating');
          String trText = '';
          try {
            String trId = _lang == 'French' ? 'fr.hamidullah' : 'en.sahih';
            final r = await http.get(Uri.parse('$kBase/ayah/$surah:$verse/$trId'));
            if (r.statusCode == 200) {
              final d = json.decode(r.body) as Map<String, dynamic>;
              trText = d['data']['text'] as String? ?? '';
              if (mounted) setState(() => _translationText = trText);
            }
          } catch (e) {
            if (mounted) setState(() => _translationText = '(traduction indisponible)');
          }
          // Speak translation aloud
          if (_speakTranslation && trText.isNotEmpty && !_stopFlag) {
            final trLang = _lang == 'French' ? 'fr' : 'en';
            await _speak(trText, trLang);
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

  Future<String?> _getTranslitId() async {
    try {
      final r = await http.get(Uri.parse('$kBase/edition/type/transliteration'));
      if (r.statusCode == 200) {
        final d = json.decode(r.body) as Map<String, dynamic>;
        var eds = d['data'] as List;
        return eds.where((e) => (e as Map)['identifier'] == 'en.transliteration').isNotEmpty
            ? 'en.transliteration'
            : (eds.isNotEmpty ? eds.first['identifier'] as String : null);
      }
    } catch (e) {}
    return null;
  }

  Future<void> _play() async {
    _stopFlag = false;
    if (mounted) {
      setState(() {
        _error = null;
        _translationText = '';
        _transliterationText = '';
        _progressDone = 0;
        _phase = 'announcing';
        _isRunning = true;
      });
    }
    try {
      List<Map<String, int>> seq = [];

      if (_mode == 'range') {
        for (int s = _startSurah; s <= _endSurah; s++) {
          final startV = (s == _startSurah) ? _startVerse : 1;
          final endV = (s == _endSurah) ? _endVerse : (kAyahCounts[s - 1] ?? 30);
          for (int v = startV; v <= endV; v++) {
            seq.add({'surah': s, 'verse': v});
          }
        }
      } else if (_mode == 'page') {
        final r = await http.get(Uri.parse('$kBase/page/$_pageNumber/quran-uthmani'));
        if (r.statusCode == 200) {
          final d = json.decode(r.body) as Map<String, dynamic>;
          for (var a in d['data']['ayahs'] as List) {
            seq.add({'surah': a['surah']['number'] as int, 'verse': a['numberInSurah'] as int});
          }
        }
      } else {
        seq.add({'surah': _singleSurah, 'verse': _singleVerse});
      }

      if (seq.isEmpty) {
        if (mounted) setState(() => _error = 'Aucun verset trouvé');
        return;
      }

      _progressTotal = _infiniteLoop ? 0 : seq.length * _repeatCount;
      await _runSequence(seq,
          repeats: _infiniteLoop ? 999 : _repeatCount,
          infinite: _infiniteLoop,
          withTranslation: _translateAfter);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur: $e');
    }
  }

  Widget _card(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          SizedBox(
            width: 80,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
              textAlign: TextAlign.center,
              onChanged: (v) => onChanged(int.tryParse(v) ?? value),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Récitation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mode tabs
          Row(
            children: ['range', 'page', 'single']
                .map((m) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Material(
                          color: _mode == m ? const Color(0xFF1B5E20) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _mode = m),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Center(
                                child: Text(
                                  m == 'range' ? 'Plage' : m == 'page' ? 'Page' : 'Verset',
                                  style: TextStyle(
                                    color: _mode == m ? Colors.white : Colors.grey,
                                    fontWeight: _mode == m ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

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
              _inputRow('Page (1–$kTotalPages)', _pageNumber, 1, kTotalPages,
                  (v) => setState(() { _pageNumber = v; _syncControllers(); }), ctrl: _pageNumberCtrl),
            ]),
          if (_mode == 'single')
            _card([
              _inputRow('Sourate', _singleSurah, 1, 114, (v) => setState(() { _singleSurah = v; _syncControllers(); }), ctrl: _singleSurahCtrl),
              _inputRow('Verset', _singleVerse, 1, 286, (v) => setState(() { _singleVerse = v; _syncControllers(); }), ctrl: _singleVerseCtrl),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Lire la traduction après'),
                value: _translateAfter,
                onChanged: (v) => setState(() => _translateAfter = v),
              ),
            ]),

          const SizedBox(height: 16),

          // Settings card
          _card([
            Row(
              children: [
                const Text('Répétitions:'),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _repeatCount.toDouble(),
                    min: 1,
                    max: 99,
                    divisions: 98,
                    label: _repeatCount.toString(),
                    onChanged: _infiniteLoop ? null : (v) => setState(() => _repeatCount = v.round()),
                  ),
                ),
                Text('x$_repeatCount'),
              ],
            ),
            SwitchListTile(
              title: const Text('Boucle continue'),
              subtitle: const Text('Répéter indéfiniment'),
              value: _infiniteLoop,
              onChanged: (v) => setState(() => _infiniteLoop = v),
            ),
            SwitchListTile(
              title: const Text('Annoncer à chaque verset'),
              value: _announceEachVerse,
              onChanged: (v) => setState(() => _announceEachVerse = v),
            ),
            SwitchListTile(
              title: const Text('Afficher translittération'),
              value: _showTransliteration,
              onChanged: (v) => setState(() => _showTransliteration = v),
            ),
            SwitchListTile(
              title: const Text('Lire traduction à voix haute'),
              subtitle: const Text('Google TTS - voix naturelle'),
              value: _speakTranslation,
              onChanged: (v) => setState(() => _speakTranslation = v),
            ),
            SwitchListTile(
              title: const Text('Annoncer le nom de la sourate'),
              subtitle: const Text('Dit "Sourate X" avant la lecture'),
              value: _announceSurah,
              onChanged: (v) => setState(() => _announceSurah = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Voix trad.:'),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Feminin'),
                        selected: _ttsFemaleVoice,
                        onSelected: (v) => setState(() => _ttsFemaleVoice = v),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Masculin'),
                        selected: !_ttsFemaleVoice,
                        onSelected: (v) => setState(() => _ttsFemaleVoice = !v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Langue trad.:'),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Français'),
                        selected: _lang == 'French',
                        onSelected: (v) => setState(() => _lang = 'French'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('English'),
                        selected: _lang == 'English',
                        onSelected: (v) => setState(() => _lang = 'English'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                              child: Text(r['label'] as String),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _reciter = v!),
                  ),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 16),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _isRunning ? Colors.grey : const Color(0xFF1B5E20)),
                  onPressed: _isRunning ? null : _play,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: Text('▶ Lancer la récitation',
                            style: TextStyle(color: Colors.white, fontSize: 16))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                  onPressed: _isRunning ? _stop : null,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: Text('⏹ Arrêter', style: TextStyle(color: Colors.white, fontSize: 16))),
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
                const SizedBox(height: 16),
                LinearProgressIndicator(
                    value: _progressTotal > 0 ? _progressDone / _progressTotal : 0),
                Text('$_progressDone / $_progressTotal'),
              ],
            ),

          // Display
          if (_arabicText.isNotEmpty || _isRunning)
            _card([
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(_phase == 'idle'
                        ? 'Prêt'
                        : _phase == 'announcing'
                            ? '🔊 Annonce'
                            : _phase == 'reciting'
                                ? '📖 Récitation'
                                : '🌍 Traduction'),
                    backgroundColor: _phase == 'reciting'
                        ? Colors.green.shade100
                        : _phase == 'announcing'
                            ? Colors.blue.shade100
                            : _phase == 'translating'
                                ? Colors.orange.shade100
                                : Colors.grey.shade100,
                  ),
                  Text('Répétition $_repeatIndex${_infiniteLoop ? ' (boucle)' : ''}'),
                ],
              ),
              if (_currentSurahName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('$_currentSurahName — verset $_currentVerseNum',
                      style: const TextStyle(color: Colors.grey)),
                ),
              const SizedBox(height: 16),
              Text(_arabicText,
                  style: const TextStyle(fontSize: 30, fontFamily: 'Amiri', height: 2),
                  textAlign: TextAlign.right),
              if (_showTransliteration && _transliterationText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(_transliterationText,
                        style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
                  ),
                ),
              if (_translationText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(_translationText, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              // Audio status bar
              if (_isRunning || _isPlaying)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isPlaying ? Icons.music_note : Icons.hourglass_empty,
                          color: _isPlaying ? Colors.green : Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(_isPlaying ? 'Lecture en cours...' : 'Chargement...',
                          style: TextStyle(
                              color: _isPlaying ? Colors.green : Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
              // TTS status bar
              if (_isTtsBuffering || _isTtsPlaying)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isTtsPlaying ? Icons.volume_up : Icons.hourglass_empty,
                          color: _isTtsPlaying ? Colors.blue : Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(_isTtsPlaying ? 'Traduction lue...' : 'Chargement TTS...',
                          style: TextStyle(
                              color: _isTtsPlaying ? Colors.blue : Colors.orange, fontSize: 14)),
                    ],
                  ),
                ),
            ]),
        ],
      ),
    );
  }
}

// ============================================================
// STUDY SCREEN
// ============================================================

class StudyScreenMain extends StatefulWidget {
  const StudyScreenMain({super.key});
  @override
  State<StudyScreenMain> createState() => _StudyScreenMainState();
}

class _StudyScreenMainState extends State<StudyScreenMain> {
  AyahData? _current;
  int _surahNum = 1;
  bool _showAnswer = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNext();
  }

  Future<void> _loadNext() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final state = context.read<AppState>();
    final due = state.getDueAyahs();
    if (due.isEmpty) {
      await state.loadAyahs(1);
      setState(() => _surahNum = 1);
    } else {
      await state.loadAyahs(due.first.surahNumber);
      setState(() => _surahNum = due.first.surahNumber);
    }
    if (mounted) {
      setState(() => _loading = false);
      _prepare(state);
    }
  }

  void _prepare(AppState quran) {
    if (quran.ayahs.isEmpty) return;
    final study = context.read<AppState>();
    final due = study.getDueAyahs();
    AyahData? ayah;
    if (due.isNotEmpty) {
      ayah = quran.getAyahByGlobalNumber(due.first.ayahGlobalNumber);
    }
    if (ayah == null && quran.ayahs.isNotEmpty) {
      ayah = quran.ayahs[DateTime.now().millisecondsSinceEpoch % quran.ayahs.length];
    }
    if (ayah != null && mounted) {
      setState(() {
        _current = ayah;
        _showAnswer = false;
      });
    }
  }

  void _rate(int quality) {
    if (_current == null) return;
    context.read<AppState>().saveStudyProgress(StudyProgress(
          ayahGlobalNumber: _current!.globalNumber,
          surahNumber: _surahNum,
          verseNumber: _current!.numberInSurah,
          nextReview: DateTime.now().add(Duration(days: quality >= 2 ? 1 : 0)),
        ));
    if (mounted) {
      setState(() => _showAnswer = false);
      _loadNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Étude'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNext)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _current == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book, size: 80, color: Color(0xFF1B5E20)),
                      const SizedBox(height: 24),
                      const Text('Mode Étude',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text(
                          'Choisissez une sourate dans l\'onglet Sourates.\nLes versets étudiés apparaîtront ici.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                          onPressed: _loadNext,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Commencer')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    LinearProgressIndicator(
                        value: state.dueCount > 0
                            ? state.totalStudied / (state.totalStudied + state.dueCount)
                            : 0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Due: ${state.dueCount}'),
                          Text('Studied: ${state.totalStudied}'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _showAnswer = true),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withAlpha(25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4))
                                    ]),
                                child: Column(
                                  children: [
                                    Chip(
                                        label: Text('Ayah ${_current!.numberInSurah}'),
                                        backgroundColor: const Color(0xFF1B5E20),
                                        labelStyle: const TextStyle(color: Colors.white)),
                                    const SizedBox(height: 24),
                                    Text(_current!.textAr,
                                        style:
                                            const TextStyle(fontSize: 32, fontFamily: 'Amiri', height: 2),
                                        textAlign: TextAlign.center),
                                    if (_showAnswer) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(12)),
                                        child: const Text('Translation (French):',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold, color: Colors.blue)),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(12)),
                                        child: Text(_current!.textFr ?? '',
                                            style: const TextStyle(fontSize: 16)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_showAnswer)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _RateBtn(label: 'Noir', color: Colors.black, q: 0, onRate: _rate),
                                  _RateBtn(label: 'Rouge', color: Colors.red, q: 1, onRate: _rate),
                                  _RateBtn(label: 'Orange', color: Colors.orange, q: 2, onRate: _rate),
                                  _RateBtn(label: 'Vert', color: Colors.green, q: 3, onRate: _rate),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _RateBtn extends StatelessWidget {
  final String label;
  final Color color;
  final int q;
  final Function(int) onRate;
  const _RateBtn(
      {required this.label, required this.color, required this.q, required this.onRate});
  @override
  Widget build(BuildContext context) => Column(
        children: [
          InkWell(
            onTap: () => onRate(q),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: color.withAlpha(51),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2)),
              child: Icon(q >= 2 ? Icons.check : Icons.close, color: color, size: 24),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );
}
