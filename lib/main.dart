import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:provider/provider.dart';

void main() => runApp(const QuranApp());

// ============================================================
// DATA
// ============================================================

const kBase = 'https://api.alquran.cloud/v1';

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
// APP STATE
// ============================================================

class AppState extends ChangeNotifier {
  final List<Map<String, dynamic>> _surahs = [];
  bool _surahLoading = false;
  String _reciter = 'ar.alafasy';
  String _translationLang = 'fr';

  List<Map<String, dynamic>> get surahs => _surahs;
  bool get surahLoading => _surahLoading;
  String get reciter => _reciter;
  String get translationLang => _translationLang;

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
      create: (_) => AppState()..loadSurahs(),
      child: MaterialApp(
        title: 'Lecture du Coran',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
          appBarTheme: const AppBarTheme(centerTitle: true, backgroundColor: Color(0xFF1B5E20), foregroundColor: Colors.white),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        ),
        darkTheme: ThemeData.dark(useMaterial3: true),
        themeMode: ThemeMode.dark,
        home: const RecitationScreen(),
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

class _RecitationScreenState extends State<RecitationScreen> with SingleTickerProviderStateMixin {
  // Mode: range, page, single, loop
  String _mode = 'single';
  
  // Range mode
  int _startSurah = 1, _startVerse = 1, _endSurah = 1, _endVerse = 7;
  int _pageNumber = 1;
  
  // Single mode
  int _singleSurah = 1, _singleVerse = 1;
  
  // Options
  bool _announceSurahVerse = true;    // "Sourate X, verset Y"
  bool _announceVerseOnly = false;    // Just "Verset Y" (optional separate)
  bool _speakTranslation = true;
  bool _speakRecitation = true;
  bool _infiniteLoop = false;
  final bool _showTransliteration = false;
  int _repeatCount = 1;
  bool _ttsFemaleVoice = false;
  String _lang = 'fr';
  String _reciter = 'ar.alafasy';
  
  // State
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
  
  // Google TTS cache
  final Map<String, String> _ttsUrlCache = {};
  DateTime? _lastTtsRequest;

  @override
  void initState() {
    super.initState();
    _initAudioSession();
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
    _player.setVolume(1.0);
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      session.interruptionEventStream.listen((event) {
        debugPrint('Audio interruption: ${event.type}');
        if (event.begin) {
          _player.pause();
        } else {
          _player.play();
        }
      });
      session.becomingNoisyEventStream.listen((_) {
        debugPrint('Headphones disconnected');
        _player.pause();
      });
      debugPrint('Audio session configured: music');
    } catch (e) {
      debugPrint('Audio session init error: $e');
    }
  }

  @override
  void dispose() {
    _stopFlag = true;
    _player.stop();
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

  // TEST: Play a known Arabic audio URL (Bismillah from Al-Fatiha)
  Future<void> _testAudio() async {
    _stopFlag = false;
    try {
      final url = 'https://verses.quran.gov/Alafasy/001001.mp3';
      debugPrint('TEST AUDIO: playing $url');
      setState(() { _error = null; _phase = 'reciting'; });
      await _player.setUrl(url);
      await _player.play();
      await _waitForPlayerStopped();
      debugPrint('TEST AUDIO: done');
      if (mounted) setState(() => _phase = 'idle');
    } catch (e) {
      debugPrint('TEST AUDIO error: $e');
      if (mounted) setState(() => _error = 'TEST Audio erreur: $e');
    }
  }

  // TEST: Play a known TTS URL (French "salam")
  Future<void> _testTts() async {
    _stopFlag = false;
    try {
      setState(() { _error = null; _phase = 'announcing'; });
      await _speak('salam', 'fr');
      if (mounted) setState(() => _phase = 'idle');
    } catch (e) {
      debugPrint('TEST TTS error: $e');
      if (mounted) setState(() => _error = 'TEST TTS erreur: $e');
    }
  }

  // Build Google TTS URL with client signature for male/female voices
  String _buildGoogleTtsUrl(String text, String lang, bool female) {
    final clean = text.replaceAll(RegExp(r'[()]'), '');
    final encoded = Uri.encodeComponent(clean);
    final client = lang == 'ar' ? (female ? 'gws-xsn-dev' : 'tw-ob') : (female ? 'lemon' : 'tw-ob');
    final tl = lang == 'ar' ? 'ar-SA' : (lang == 'en' ? 'en-US' : 'fr-FR');
    return 'https://translate.google.com/translate_tts?ie=UTF-8&tl=$tl&client=$client&q=$encoded';
  }

  Future<String?> _getCachedTtsUrl(String text, String lang, bool female) async {
    if (text.isEmpty) return null;
    final url = _buildGoogleTtsUrl(text, lang, female);
    if (_ttsUrlCache.containsKey(url)) return url;
    _ttsUrlCache[url] = text;
    if (_ttsUrlCache.length > 50) {
      final first = _ttsUrlCache.keys.first;
      _ttsUrlCache.remove(first);
    }
    return url;
  }

  Future<void> _speak(String text, String lang) async {
    if (text.isEmpty || _stopFlag) return;
    try {
      if (_lastTtsRequest != null) {
        final elapsed = DateTime.now().difference(_lastTtsRequest!);
        if (elapsed.inMilliseconds < 500) {
          await Future.delayed(Duration(milliseconds: 500 - elapsed.inMilliseconds));
        }
      }
      _lastTtsRequest = DateTime.now();

      final url = await _getCachedTtsUrl(text, lang, _ttsFemaleVoice);
      if (url == null || _stopFlag) return;

      debugPrint('TTS: playing url=$url text="$text"');
      if (mounted) setState(() => _isTtsBuffering = true);
      await _player.stop();
      await _player.setUrl(url);
      if (mounted) setState(() { _isTtsPlaying = true; _isTtsBuffering = false; });
      await _player.play();
      debugPrint('TTS: started playback');

      int attempts = 0;
      while (!_stopFlag && attempts < 150) {
        if (!_player.playing) {
          final ps = _player.processingState;
          debugPrint('TTS: state=playing=$_player.playing processingState=$ps attempts=$attempts');
          if (ps == ProcessingState.completed || ps == ProcessingState.idle) break;
        }
        await Future.delayed(const Duration(milliseconds: 300));
        attempts++;
      }
      if (_isTtsPlaying) {
        await _player.stop();
        if (mounted) setState(() { _isTtsPlaying = false; _isTtsBuffering = false; });
      }
      debugPrint('TTS: done');
    } catch (e) {
      debugPrint('TTS error: $e');
      if (mounted) setState(() => _error = 'Erreur TTS: $e');
    }
    if (mounted) setState(() { _isTtsPlaying = false; _isTtsBuffering = false; });
  }

  Future<void> _waitForPlayerStopped() async {
    for (int i = 0; i < 120; i++) {
      if (_stopFlag) return;
      final ps = _player.processingState;
      if (ps == ProcessingState.completed || ps == ProcessingState.idle) return;
      if (!_player.playing) {
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> _runSequence(List<Map<String, int>> seq,
      {int repeats = 3, bool infinite = false, bool withTranslation = true, bool withRecitation = true}) async {
    _stopFlag = false;
    _isRunning = true;
    int done = 0;
    int rep = 0;
    String? cachedSurahName;
    int? cachedSurahNum;

    while (!_stopFlag && (infinite || rep < repeats)) {
      rep++;
      if (mounted) setState(() => _repeatIndex = rep);
      int lastSurah = -1;

      for (var ref in seq) {
        if (_stopFlag) break;
        int surah = ref['surah']!;
        int verse = ref['verse']!;

        // Announce surah when changing surah
        if (surah != lastSurah) {
          String surahName = cachedSurahName ?? '';
          if (surah != cachedSurahNum) {
            try {
              final r = await http.get(Uri.parse('$kBase/surah/$surah'));
              if (r.statusCode == 200) {
                final d = json.decode(r.body) as Map<String, dynamic>;
                surahName = d['data']['name'] as String;
                cachedSurahName = surahName;
                cachedSurahNum = surah;
              }
            } catch (e) {
              debugPrint('Surah name fetch error: $e');
            }
          }
          
          lastSurah = surah;
          
          // Announce: "Sourate X, verset Y"
          if (_announceSurahVerse && surahName.isNotEmpty) {
            if (mounted) {
              setState(() {
                _currentSurahName = surahName;
                _currentVerseNum = verse;
                _phase = 'announcing';
              });
            }
            // Speak: "Sourate [name], verset [number]"
            final announceText = _lang == 'fr' 
                ? 'Sourate $surahName, verset $verse'
                : 'Surah $surahName, verse $verse';
            await _speak(announceText, _lang);
            if (_stopFlag) break;
          }
          
          // Optional separate "Verset Y" announcement (additional, not replacement)
          if (_announceVerseOnly) {
            final verseText = _lang == 'fr' ? 'Verset $verse' : 'Verse $verse';
            await _speak(verseText, _lang);
            if (_stopFlag) break;
          }
        }

        if (mounted) {
          setState(() {
            _currentVerseNum = verse;
            _phase = 'reciting';
          });
        }

        // Fetch arabic text
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
            final r = await http.get(Uri.parse('$kBase/edition/type/transliteration'));
            if (r.statusCode == 200) {
              final d = json.decode(r.body) as Map<String, dynamic>;
              var eds = d['data'] as List;
              String? tid = eds.where((e) => (e as Map)['identifier'] == 'en.transliteration').isNotEmpty
                  ? 'en.transliteration'
                  : (eds.isNotEmpty ? eds.first['identifier'] as String : null);
              if (tid != null) {
                final r2 = await http.get(Uri.parse('$kBase/ayah/$surah:$verse/$tid'));
                if (r2.statusCode == 200) {
                  final d2 = json.decode(r2.body) as Map<String, dynamic>;
                  if (mounted) setState(() => _transliterationText = d2['data']['text'] as String? ?? '');
                }
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

        // Audio recitation
        if (withRecitation) {
          try {
            final r = await http.get(Uri.parse('$kBase/ayah/$surah:$verse/$_reciter'));
            if (r.statusCode == 200) {
              final d = json.decode(r.body) as Map<String, dynamic>;
              final url = d['data']['audio'] as String?;
              if (url != null) {
                if (!_stopFlag && mounted) {
                  try {
                    debugPrint('Audio: playing url=$url');
                    await _player.setUrl(url);
                    await _player.play();
                    debugPrint('Audio: started playback');
                    await _waitForPlayerStopped();
                    debugPrint('Audio: done');
                  } catch (e) {
                    debugPrint('Audio play error: $e');
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('Audio fetch error: $e');
          }
        }

        // Translation
        if (withTranslation && _speakTranslation) {
          if (mounted) setState(() => _phase = 'translating');
          String trText = '';
          try {
            String trId = _lang == 'fr' ? 'fr.hamidullah' : 'en.sahih';
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
          if (trText.isNotEmpty && !_stopFlag) {
            final trLang = _lang;
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
          final endV = (s == _endSurah) ? _endVerse : kAyahCounts[s - 1];
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
          withTranslation: _speakTranslation,
          withRecitation: _speakRecitation);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur: $e');
    }
  }

  Widget _card(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          SizedBox(
            width: 70,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  hintText: '1'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lecture du Coran')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mode tabs
          Row(
            children: ['single', 'range', 'page', 'loop']
                .map((m) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Material(
                          color: _mode == m ? const Color(0xFF1B5E20) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _mode = m),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Center(
                                child: Text(
                                  m == 'single' ? 'Verset' : m == 'range' ? 'Plage' : m == 'page' ? 'Page' : 'Boucle',
                                  style: TextStyle(
                                    color: _mode == m ? Colors.white : Colors.grey,
                                    fontWeight: _mode == m ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
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
              onChanged: (v) => setState(() => _announceSurahVerse = v),
            ),
            SwitchListTile(
              title: const Text('Annoncer juste "Verset X"'),
              subtitle: const Text('Optionnel, en plus de l\'annonce de sourate'),
              value: _announceVerseOnly,
              onChanged: (v) => setState(() => _announceVerseOnly = v),
            ),
            SwitchListTile(
              title: const Text('Lire la récitation'),
              value: _speakRecitation,
              onChanged: (v) => setState(() => _speakRecitation = v),
            ),
            SwitchListTile(
              title: const Text('Lire la traduction'),
              value: _speakTranslation,
              onChanged: (v) => setState(() => _speakTranslation = v),
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
                        onChanged: (v) => setState(() => _repeatCount = v.round()),
                      ),
                    ),
                    Text('x$_repeatCount'),
                  ],
                ),
              ),
            const Divider(),
            const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Voix traduction:'),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Féminin'),
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
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Langue:'),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Français'),
                  selected: _lang == 'fr',
                  onSelected: (v) => setState(() => _lang = 'fr'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('English'),
                  selected: _lang == 'en',
                  onSelected: (v) => setState(() => _lang = 'en'),
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
                              child: Text(r['label'] as String, style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _reciter = v!),
                  ),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 12),

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
                        child: Text('▶ Lancer',
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

          const SizedBox(height: 8),

          // Test buttons (debug)
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
                  style: const TextStyle(fontSize: 28, fontFamily: 'Amiri', height: 2),
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
                        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
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
                    child: Text(_translationText, style: const TextStyle(fontSize: 15)),
                  ),
                ),
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
                          style: TextStyle(color: _isPlaying ? Colors.green : Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
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
                          style: TextStyle(color: _isTtsPlaying ? Colors.blue : Colors.orange, fontSize: 14)),
                    ],
                  ),
                ),
            ]),
        ],
      ),
    );
  }
}
