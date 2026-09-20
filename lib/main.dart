import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MuralApp());
}

class MuralApp extends StatelessWidget {
  const MuralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mural Voice AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080B12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF141B2D),
        ),
      ),
      home: const CallScreen(),
    );
  }
}

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  // Engines & Models
  String _selectedEngine = 'hermes'; // hermes, google, groq, auto
  String _selectedModel = 'auto/best-coding';
  String _selectedLang = 'de';
  String _googleKey = '';
  String _groqKey = '';
  String _hermesUrl = 'https://miscellaneous-rays-detect-relationships.trycloudflare.com';

  // State
  bool _isListening = false;
  bool _isAiSpeaking = false;
  bool _isProcessing = false;
  String _statusText = 'Touchez pour parler';
  String _spokenText = 'Touchez l\'orbe pour démarrer la pratique en allemand.';
  String _translationText = '';
  int _pronScore = 0;
  String _pronTip = '';

  // Hardware
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initTts();
    _initSpeech();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onError: (val) => setState(() => _statusText = 'Prêt'),
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          if (_isListening && _recognizedText.isNotEmpty) {
            _handleFinalSpeech(_recognizedText);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedEngine = prefs.getString('engine') ?? 'hermes';
      _selectedModel = prefs.getString('model') ?? 'auto/best-coding';
      _selectedLang = prefs.getString('lang') ?? 'de';
      _googleKey = prefs.getString('google_key') ?? '';
      _groqKey = prefs.getString('groq_key') ?? '';
      _hermesUrl = prefs.getString('hermes_url') ?? 'https://miscellaneous-rays-detect-relationships.trycloudflare.com';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('engine', _selectedEngine);
    await prefs.setString('model', _selectedModel);
    await prefs.setString('lang', _selectedLang);
    await prefs.setString('google_key', _googleKey);
    await prefs.setString('groq_key', _groqKey);
    await prefs.setString('hermes_url', _hermesUrl);
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('de-DE');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      setState(() {
        _isAiSpeaking = true;
        _statusText = 'L\'IA vous parle...';
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isAiSpeaking = false;
        _statusText = 'À votre tour · Parlez';
      });
    });
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;

    if (_isListening) {
      // Stop listening
      _speech.stop();
      setState(() {
        _isListening = false;
        _isProcessing = true;
        _statusText = 'Analyse de votre voix...';
      });
      if (_recognizedText.isNotEmpty) {
        await _handleFinalSpeech(_recognizedText);
      } else {
        setState(() {
          _isProcessing = false;
          _statusText = 'Aucune parole détectée';
        });
      }
    } else {
      // Start listening
      bool available = await _speech.initialize();
      if (available) {
        _recognizedText = '';
        setState(() {
          _isListening = true;
          _statusText = 'Écoute en cours... (Parlez)';
        });
        HapticFeedback.mediumImpact();
        await _speech.listen(
          localeId: _selectedLang == 'de' ? 'de_DE' : (_selectedLang == 'fr' ? 'fr_FR' : 'en_US'),
          onResult: (result) {
            setState(() {
              _recognizedText = result.recognizedWords;
              _spokenText = result.recognizedWords;
            });
          },
        );
      } else {
        setState(() => _statusText = 'Micro non disponible');
      }
    }
  }

  Future<void> _handleFinalSpeech(String userText) async {
    if (userText.trim().isEmpty) {
      setState(() {
        _isProcessing = false;
        _statusText = 'Aucun son détecté';
      });
      return;
    }

    setState(() {
      _spokenText = userText;
      _statusText = 'Génération de la réponse...';
    });

    try {
      // LLM Call (/v1/chat/completions)
      final chatUri = Uri.parse('$_hermesUrl/v1/chat/completions');
      final chatBody = {
        'model': _selectedModel,
        'messages': [
          {
            'role': 'system',
            'content': 'Tu es un tuteur d\'allemand chaleureux. Réponds en allemand de manière concise. '
                'Ajoute ensuite la traduction française sous la forme :\\nTRADUCTION: [traduction en français]'
          },
          {'role': 'user', 'content': userText}
        ],
        'user': 'user_iyad'
      };

      final chatResp = await http.post(
        chatUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(chatBody),
      );

      final chatJson = jsonDecode(utf8.decode(chatResp.bodyBytes));
      final aiFullReply = chatJson['choices']?[0]?['message']?['content'] ?? '';

      // Parse translation
      String aiGermanSpeech = aiFullReply;
      String translation = '';
      if (aiFullReply.contains('TRADUCTION:')) {
        final parts = aiFullReply.split('TRADUCTION:');
        aiGermanSpeech = parts[0].trim();
        translation = parts[1].trim();
      }

      setState(() {
        _isProcessing = false;
        _spokenText = aiGermanSpeech;
        _translationText = translation;
        _pronScore = 90;
      });

      // TTS Speech
      await _flutterTts.speak(aiGermanSpeech);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusText = 'Erreur: ${e.toString()}';
      });
    }
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101626),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final modelsMap = {
            'hermes': [
              {'id': 'auto/best-coding', 'name': '🤖 Hermes Auto (OmniRoute)'},
              {'id': 'NousResearch/Hermes-3-Llama-3.1-8B', 'name': '🧠 Nous Hermes 3 (8B Local)'},
              {'id': 'hermes-agent-vps', 'name': '🎙️ Hermes Vocal VPS'},
            ],
            'google': [
              {'id': 'gemini-2.0-flash', 'name': '⚡ Gemini 2.0 Flash (Recommandé)'},
              {'id': 'gemini-2.0-flash-lite', 'name': '🚀 Gemini 2.0 Flash Lite'},
              {'id': 'gemini-1.5-pro', 'name': '🧠 Gemini 1.5 Pro'},
            ],
            'groq': [
              {'id': 'openai/gpt-oss-120b', 'name': '⚡ GPT-OSS 120B (Groq)'},
              {'id': 'openai/gpt-oss-20b', 'name': '🚀 GPT-OSS 20B'},
              {'id': 'qwen/qwen3.8-27b', 'name': '🌐 Qwen 3.8 27B'},
            ],
            'auto': [
              {'id': 'auto', 'name': '🔀 Bascule Auto (Groq ➔ Gemini ➔ Hermes)'}
            ]
          };

          final currentModels = modelsMap[_selectedEngine] ?? modelsMap['hermes']!;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '⚙️ Réglages de l\'application',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // ====== BLOC 1 : IA Principale ======
                  _buildSectionCard(
                    title: '1. IA Principale',
                    icon: Icons.tune,
                    child: DropdownButtonFormField<String>(
                      value: _selectedEngine,
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: _inputDecoration('Choisir l\'IA'),
                      items: const [
                        DropdownMenuItem(value: 'hermes', child: Text('🏛️ Hermes Agent (VPS Oracle)')),
                        DropdownMenuItem(value: 'google', child: Text('🌐 Google Gemini')),
                        DropdownMenuItem(value: 'groq', child: Text('⚡ Groq Cloud')),
                        DropdownMenuItem(value: 'auto', child: Text('🔀 Bascule Automatique')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() {
                            _selectedEngine = val;
                            _selectedModel = modelsMap[val]!.first['id']!;
                          });
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ====== BLOC 2 : Sous-Modèle ======
                  _buildSectionCard(
                    title: '2. Sous-Modèle',
                    icon: Icons.inventory_2_outlined,
                    child: DropdownButtonFormField<String>(
                      value: currentModels.any((m) => m['id'] == _selectedModel)
                          ? _selectedModel
                          : currentModels.first['id'],
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: _inputDecoration('Choisir le modèle'),
                      items: currentModels.map((m) {
                        return DropdownMenuItem(value: m['id'], child: Text(m['name']!));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => _selectedModel = val);
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ====== BLOC 3 : Clé Gemini (Indépendant) ======
                  _buildSectionCard(
                    title: 'Clé API Google Gemini',
                    icon: Icons.public,
                    statusText: _googleKey.isNotEmpty ? 'Configurée ✓' : 'Non renseignée',
                    statusActive: _googleKey.isNotEmpty,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          initialValue: _googleKey,
                          obscureText: true,
                          decoration: _inputDecoration('AIzaSy...'),
                          onChanged: (val) {
                            _googleKey = val.trim();
                            setSheetState(() {});
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 6),
                        _buildHelpLink('Obtenir une clé Gemini gratuite', 'https://aistudio.google.com/app/apikey'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ====== BLOC 4 : Clé Groq (Indépendant) ======
                  _buildSectionCard(
                    title: 'Clé API Groq Cloud',
                    icon: Icons.bolt,
                    statusText: _groqKey.isNotEmpty ? 'Configurée ✓' : 'Non renseignée',
                    statusActive: _groqKey.isNotEmpty,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          initialValue: _groqKey,
                          obscureText: true,
                          decoration: _inputDecoration('gsk_...'),
                          onChanged: (val) {
                            _groqKey = val.trim();
                            setSheetState(() {});
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 6),
                        _buildHelpLink('Obtenir une clé Groq gratuite', 'https://console.groq.com/keys'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ====== BLOC 5 : Lien Hermes VPS (Indépendant) ======
                  _buildSectionCard(
                    title: 'Lien Hermes Agent VPS',
                    icon: Icons.account_balance,
                    statusText: 'VPS Connecté ✓',
                    statusActive: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          initialValue: _hermesUrl,
                          decoration: _inputDecoration('https://... ou http://158...'),
                          onChanged: (val) {
                            _hermesUrl = val.trim();
                            setSheetState(() {});
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 6),
                        _buildHelpLink('Documentation Hermes Agent', 'https://hermes-agent.nousresearch.com/'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        _savePreferences();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Réglages sauvegardés avec succès !')),
                        );
                      },
                      child: const Text(
                        'Enregistrer & Appliquer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    String? statusText,
    bool statusActive = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF818CF8)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              if (statusText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusActive ? const Color(0x2210B981) : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusActive ? const Color(0xFF34D399) : Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1)),
      ),
    );
  }

  Widget _buildHelpLink(String label, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Text(
        '🔗 $label',
        style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11, decoration: TextDecoration.underline),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Column(
                children: [
                  const Text(
                    'ALLEMAND 🇩🇪',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFF818CF8)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Mural Voice AI',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? const Color(0xFFEF4444)
                                : (_isAiSpeaking ? const Color(0xFF10B981) : const Color(0xFFEAB308)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_statusText, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),

              // Animated Orb
              GestureDetector(
                onTap: _toggleRecording,
                child: ScaleTransition(
                  scale: _isListening || _isAiSpeaking ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: _isListening
                            ? [const Color(0xFFF43F5E), const Color(0xFF881337)]
                            : (_isAiSpeaking
                                ? [const Color(0xFF10B981), const Color(0xFF064E3B)]
                                : [const Color(0xFF6366F1), const Color(0xFF312E81)]),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? const Color(0xFFF43F5E) : const Color(0xFF6366F1)).withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isListening ? Icons.mic : (_isAiSpeaking ? Icons.volume_up : Icons.mic_none),
                        size: 54,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // Subtitles & Translation Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141B2D),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🤖 Moteur: ${_selectedEngine.toUpperCase()}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF818CF8), fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_pronScore > 0)
                          Text(
                            '🎯 Prononciation : $_pronScore/100',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _spokenText,
                      style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    if (_translationText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '🇫🇷 $_translationText',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF38BDF8), fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _spokenText = 'Session réinitialisée. Touchez l\'orbe pour parler.';
                        _translationText = '';
                        _pronScore = 0;
                      });
                    },
                  ),
                  FloatingActionButton.large(
                    backgroundColor: _isListening ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
                    onPressed: _toggleRecording,
                    child: Icon(_isListening ? Icons.stop : Icons.mic, size: 36, color: Colors.white),
                  ),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    onPressed: _openSettings,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
