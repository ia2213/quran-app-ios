#!/usr/bin/env python3
import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Corriger les crossAxisAlignment dupliqués
def fix_duplicate_crossaxis(content):
    pattern = r'(crossAxisAlignment:\s*CrossAxisAlignment\.\w+,\s*\n\s+)(crossAxisAlignment:\s*CrossAxisAlignment\.\w+,)'
    count = 0
    while re.search(pattern, content):
        content = re.sub(pattern, r'\1', content)
        count += 1
    print(f'crossAxisAlignment dupliqués corrigés: {count}')
    return content

content = fix_duplicate_crossaxis(content)

# 2. Corriger la structure cassée ligne 2644-2647
old_broken = """        title: Column(
          
      crossAxisAlignment: CrossAxisAlignment.start,

          crossAxisAlignment: CrossAxisAlignment.start,
children: [
            Text(
              _currentSurahName ?? 'Sourate $_singleSurah',e: 16, fontWeight: FontWeight.w600),
            ),"""

new_fixed = """        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentSurahName ?? 'Sourate $_singleSurah',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
        ),"""

if old_broken in content:
    content = content.replace(old_broken, new_fixed)
    print('Structure lignes 2640-2661 corrigée')
else:
    print('ERREUR: structure 2640-2661 non trouvée')

# 3. Ajouter les nouveaux écrans à la FIN du fichier
last_brace_idx = content.rfind('\n}')
if last_brace_idx >= 0:
    insert_pos = last_brace_idx + 1
    screens = '''
// ============================================================
// ADULT HOME SCREEN
// ============================================================

class AdultHomeScreen extends StatelessWidget {
  const AdultHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Text(
                'Qu\'ran',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Theme.of(context).colorScheme.onSurface
                      : const Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choisissez votre mode',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _modeCard(
                      context: context,
                      icon: Icons.auto_awesome,
                      title: 'Essayer',
                      subtitle: 'Écouter une récitation',
                      color: const Color(0xFF10B981),
                      onTap: () => _goToMode(context, appState, 'try'),
                    ),
                    _modeCard(
                      context: context,
                      icon: Icons.school,
                      title: 'Apprendre',
                      subtitle: 'Tajweed, traduction',
                      color: const Color(0xFF2563EB),
                      onTap: () => _goToMode(context, appState, 'learn'),
                    ),
                    _modeCard(
                      context: context,
                      icon: Icons.gamepad,
                      title: 'Exercices',
                      subtitle: 'Quiz, mémorisation',
                      color: const Color(0xFF7C3AED),
                      onTap: () => _goToMode(context, appState, 'exercise'),
                    ),
                    _modeCard(
                      context: context,
                      icon: Icons.menu_book,
                      title: 'Autre',
                      subtitle: 'Prières, Adhkar...',
                      color: const Color(0xFFD97706),
                      onTap: () => _goToMode(context, appState, 'other'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Theme.of(context).colorScheme.onSurface
                    : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToMode(BuildContext context, AppState appState, String mode) {
    appState.enterKidsMode(mode);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KidsModeScreen()),
    );
  }
}

// ============================================================
// KIDS MODE SCREEN
// ============================================================

class KidsModeScreen extends StatefulWidget {
  const KidsModeScreen({super.key});

  @override
  State<KidsModeScreen> createState() => _KidsModeScreenState();
}

class _KidsModeScreenState extends State<KidsModeScreen> {
  final _controller = TextEditingController();
  bool _showGate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (!appState.isUnlockSequenceCorrect) {
        setState(() => _showGate = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final modeType = appState.kidsModeType;
    
    final modeConfig = {
      'try': ('Écouter', Icons.audio_file, 'Écoute la récitation', Colors.teal),
      'learn': ('Apprendre', Icons.school, 'Tajweed et traduction', Colors.indigo),
      'exercise': ('Exercices', Icons.gamepad, 'Quiz et mémorisation', Colors.purple),
      'other': ('Autre', Icons.menu_book, 'Prières et Adhkar', Colors.orange),
    };
    
    final (title, icon, desc, cardColor) = modeConfig[modeType] ?? modeConfig['learn']!;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: isDark
            ? Theme.of(context).colorScheme.surface
            : const Color(0xFFF5F5F7),
        appBar: AppBar(
          leading: const SizedBox.shrink(),
          title: Row(
            children: [
              Icon(icon, color: primaryColor, size: 28),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
            ],
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            GestureDetector(
              onTap: () => setState(() => _showGate = true),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).colorScheme.outlineVariant : const Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 20),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cardColor.withValues(alpha: 0.2), cardColor.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 56, color: cardColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Theme.of(context).colorScheme.onSurface : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Theme.of(context).colorScheme.onSurfaceVariant : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 80, color: cardColor.withValues(alpha: 0.6)),
                      const SizedBox(height: 20),
                      Text(
                        'Mode $title',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Theme.of(context).colorScheme.onSurface : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tu es en mode "$title". Appuie sur Retour pour quitter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Theme.of(context).colorScheme.onSurfaceVariant : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Theme.of(context).colorScheme.surface,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => setState(() => _showGate = true),
                        icon: const Icon(Icons.arrow_back, size: 24),
                        label: const Text('Retour'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showParentalGate(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            const Text('Mode Parental'),
          ],
        ),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tape les chiffres dans l\'ordre pour quitter :', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _digitBox(context, 1, appState.kidsUnlockSequence.length >= 1 ? appState.kidsUnlockSequence[0] : 0),
                  _digitBox(context, 2, appState.kidsUnlockSequence.length >= 2 ? appState.kidsUnlockSequence[1] : 0),
                  _digitBox(context, 3, appState.kidsUnlockSequence.length >= 3 ? appState.kidsUnlockSequence[2] : 0),
                  _digitBox(context, 4, appState.kidsUnlockSequence.length >= 4 ? appState.kidsUnlockSequence[3] : 0),
                  _digitBox(context, 5, appState.kidsUnlockSequence.length >= 5 ? appState.kidsUnlockSequence[4] : 0),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Ordre : 2 → 4 → 6 → 8 → 10', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Tape 5 chiffres',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (value) => _checkSequence(context, appState, value),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _chip(context, '2'), const SizedBox(width: 6), _chip(context, '4'),
                  const SizedBox(width: 6), _chip(context, '6'), const SizedBox(width: 6),
                  _chip(context, '8'), const SizedBox(width: 6), _chip(context, '10'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              appState.clearKidsUnlockSequence();
              Navigator.pop(dialogContext);
              setState(() => _showGate = false);
            },
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _digitBox(BuildContext context, int position, int value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFilled = value > 0;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isFilled ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
            : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB)),
        shape: BoxShape.circle,
        border: Border.all(
          color: isFilled ? Theme.of(context).colorScheme.primary
              : (isDark ? Theme.of(context).colorScheme.outlineVariant : const Color(0xFFD1D5DB)),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          isFilled ? value.toString() : '?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isFilled ? Theme.of(context).colorScheme.primary
                : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF9CA3AF)),
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String digit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        digit,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _checkSequence(BuildContext context, AppState appState, String value) {
    final numbers = value.split(RegExp(r'[,\s]+')).where((s) => s.isNotEmpty).map(int.parse).toList();
    if (numbers.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tape exactement 5 chiffres')));
      return;
    }
    final correct = numbers[0] == 2 && numbers[1] == 4 && numbers[2] == 6 && numbers[3] == 8 && numbers[4] == 10;
    if (correct) {
      appState.clearKidsUnlockSequence();
      setState(() => _showGate = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mode parental déblocable'), backgroundColor: Colors.green),
      );
    } else {
      appState.clearKidsUnlockSequence();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Séquence incorrecte'), backgroundColor: Colors.red),
      );
    }
  }
}
'''
    
    content = content[:insert_pos] + '\n' + screens + content[insert_pos:]
    print('Nouveaux écrans ajoutés')
else:
    print('ERREUR: dernière accolade non trouvée')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print(f'Fichier modifié: {len(content)} caractères')
