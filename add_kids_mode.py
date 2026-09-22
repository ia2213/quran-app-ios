import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the last closing brace and add new screens before it
# Find the last } that ends the file

# Kids Mode colors
kidsColors = '''
// ============================================================
// KIDS MODE COLORS
// ============================================================

const kKidsPrimary = Color(0xFF7C3AED);      // Purple
const kKidsSecondary = Color(0xFFEC4899);    // Pink
const kKidsSurface = Color(0xFFF5F3FF);      // Light purple
const kKidsSurfaceDark = Color(0xFF2E1068);  // Dark purple
const kKidsOnSurface = Color(0xFF1C1917);    // Dark text
const kKidsOnSurfaceDark = Color(0xFFF5F3FF); // Light text
'''

adultScreen = '''
// ============================================================
// ADULT HOME SCREEN
// ============================================================

class AdultHomeScreen extends StatelessWidget {
  const AdultHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Header
              Text(
                'Bienvenue',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez un mode pour commencer',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // 4 Cards
              _adultCard(
                context: context,
                icon: Icons.headphones,
                title: 'Essayer',
                subtitle: 'Écouter & Réciter le Coran',
                color: colorScheme.primary,
                onTap: () => _showKidsGate(context, appState, 'essayer'),
              ),
              const SizedBox(height: 16),
              _adultCard(
                context: context,
                icon: Icons.school,
                title: 'Apprendre',
                subtitle: 'Tajweed & Mémorisation',
                color: colorScheme.secondary,
                onTap: () => _showKidsGate(context, appState, 'apprendre'),
              ),
              const SizedBox(height: 16),
              _adultCard(
                context: context,
                icon: Icons.fitness_center,
                title: 'Exercices',
                subtitle: 'Pratique du Tajweed',
                color: Colors.amber,
                onTap: () => _showKidsGate(context, appState, 'exercices'),
              ),
              const SizedBox(height: 16),
              _adultCard(
                context: context,
                icon: Icons.settings,
                title: 'Autre',
                subtitle: 'Paramètres & Prières',
                color: Colors.teal,
                onTap: () => _showKidsGate(context, appState, 'autre'),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              // Kids Mode Toggle (Adult only)
              _kidsModeCard(context: context, appState: appState, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adultCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1C1C1E).withOpacity(0.9)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? const Color(0xFF636366) : const Color(0xFF8E8E93),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kidsModeCard({
    required BuildContext context,
    required AppState appState,
    required bool isDark,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2E1068).withOpacity(0.3)
            : const Color(0xFFF5F3FF).withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kKidsPrimary.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kKidsPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.child_friendly, color: kKidsPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Enfant',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kKidsPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appState.isKidsMode ? 'Activé - Appuyez pour désactiver' : 'Désactivé - Appuyez pour activer',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: appState.isKidsMode,
            onChanged: (val) {
              if (val) {
                // Entering kids mode - show gate first
                appState.startKidsGate(useMath: false);
                _showParentalGateDialog(context, appState, isDark);
              } else {
                appState.exitKidsMode();
              }
            },
            activeColor: kKidsPrimary,
            activeTrackColor: kKidsPrimary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  void _showKidsGate(BuildContext context, AppState appState, String modeType) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: kKidsPrimary.withOpacity(0.3),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kKidsPrimary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, color: kKidsPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirmation Adultes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vous allez accéder au mode « $modeType ».\\n\\nAppuyez sur les chiffres suivants pour continuer :',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              // Sequence indicator
              _gateSequenceIndicator(currentStep: appState.kidsGateStep),
              const SizedBox(height: 8),
              Text(
                'Sequence : 2 → 4 → 6 → 8 → 10',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kKidsPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'OU appuyez sur "Challenge Maths" pour un défi alternatif',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? const Color(0xFF636366) : const Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showParentalGateDialog(context, appState, isDark);
            },
            child: const Text('Challenge Maths'),
          ),
        ],
      ),
    );
  }

  Widget _gateSequenceIndicator({required int currentStep}) {
    const sequence = [2, 4, 6, 8, 10];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: sequence.asMap().entries.map((entry) {
        final index = entry.key;
        final digit = entry.value;
        final isActive = index <= currentStep;
        final isCompleted = index < currentStep;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? kKidsPrimary
                  : (isActive ? kKidsPrimary.withOpacity(0.3) : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? kKidsPrimary : const Color(0xFFD1D5DB),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                digit.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.white : (isActive ? kKidsPrimary : const Color(0xFF9CA3AF)),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showParentalGateDialog(BuildContext context, AppState appState, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kKidsPrimary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fingerprint, color: kKidsPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Gate Parental',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show current gate state
                  if (appState.kidsMathChallengeActive)
                    _mathChallengeWidget(context, appState, setState)
                  else
                    _sequenceGateWidget(context, appState, setState, isDark),
                ],
              ),
            ),
            actions: [
              if (!appState.kidsMathChallengeActive)
                TextButton(
                  onPressed: () {
                    appState.startKidsGate(useMath: true);
                    setState(() {});
                  },
                  child: const Text('Défi Maths'),
                ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sequenceGateWidget(BuildContext context, AppState appState, StateSetter setState, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(
          'Entrez la séquence :',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        // Display dots for current sequence
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final isFilled = index < appState.kidsGateStep;
            return Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isFilled ? kKidsPrimary : kKidsPrimary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isFilled ? '✓' : '${index + 1}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isFilled ? Colors.white : kKidsPrimary,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        // Number pad
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (int i = 1; i <= 9; i++)
              _numberButton(i, appState, setState, isDark),
            const SizedBox(height: 8),
            _numberButton(0, appState, setState, isDark),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: const Center(),
            ),
            IconButton(
              icon: const Icon(Icons.backspace, color: Color(0xFF6B7280)),
              onPressed: () {
                if (appState.kidsGateStep > 0) {
                  // For simplicity, reset to 0
                  appState.startKidsGate(useMath: false);
                  setState(() {});
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          appState.kidsGateStep > 0
              ? '${appState.kidsGateStep}/5 chiffres entrés'
              : 'Appuyez sur 2, 4, 6, 8, 10',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF636366) : const Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  Widget _mathChallengeWidget(BuildContext context, AppState appState, StateSetter setState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Text(
                '🧮 Défi Maths',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Quel est le résultat de :',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${appState.kidsMathAnswer > 0 ? "?" : "Calcul..."}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Entrez le résultat :',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        // Simple number input pad
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i <= 9; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ElevatedButton(
                    onPressed: () {
                      final result = appState.validateKidsMathChallenge(i);
                      if (result) {
                        Navigator.of(context).pop();
                        // Success - show confirmation
                        _showGateSuccess(context, appState, isDark);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Réponse incorrecte'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(44, 44),
                    ),
                    child: Text(
                      i.toString(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _numberButton(int digit, AppState appState, StateSetter setState, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ElevatedButton(
        onPressed: () {
          if (appState.kidsGateStep < 5) {
            final success = appState.validateKidsGateSequence(digit);
            setState(() {});
            if (success) {
              Navigator.of(context).pop();
              _showGateSuccess(context, appState, isDark);
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(60, 60),
        ),
        child: Text(
          digit.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showGateSuccess(BuildContext context, AppState appState, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Accès Autorisé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Mode Enfant activé avec succès.\\nL\'enfant ne pourra pas quitter ce mode.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.maxFinite,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // Navigate to KidsModeScreen with the selected mode
                appState.setKidsMode(true, modeType: appState.kidsModeType);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kKidsPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Continuer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// KIDS MODE SCREEN (Locked)
// ============================================================

class KidsModeScreen extends StatefulWidget {
  const KidsModeScreen({super.key});

  @override
  State<KidsModeScreen> createState() => _KidsModeScreenState();
}

class _KidsModeScreenState extends State<KidsModeScreen> {
  int _currentTab = 0;

  // Mode-specific content
  final List<String> _modeTitles = ['Essayer', 'Apprendre', 'Exercices', 'Autre'];
  final List<IconData> _modeIcons = [Icons.headphones, Icons.school, Icons.fitness_center, Icons.settings];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Get the mode type (with fallback)
    final modeIndex = _getModeIndex(appState.kidsModeType);

    return WillPopScope(
      onWillPop: () async => false, // Block back button
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F7),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: null, // No back button
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '👶 Mode Enfant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kKidsPrimary,
                ),
              ),
              Text(
                _modeTitles[modeIndex],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          actions: [
            // Only show exit button that requires parental gate
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: kKidsPrimary),
              onPressed: () => _showExitGate(context, appState, isDark),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1C1C1E), const Color(0xFF2E1068)]
                  : [Colors.white, const Color(0xFFF5F3FF)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Mode indicator at top
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kKidsPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: kKidsPrimary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kKidsPrimary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.child_friendly, color: kKidsPrimary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bienvenue dans le mode',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _modeTitles[modeIndex],
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: kKidsPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content based on mode
                Expanded(
                  child: _buildModeContent(context, modeIndex, appState, isDark, colorScheme),
                ),
                // Bottom navigation
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: List.generate(4, (index) {
                      final isSelected = index == modeIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (index != modeIndex) {
                              setState(() {
                                _currentTab = index;
                                // Update mode type in app state
                                final newMode = ['essayer', 'apprendre', 'exercices', 'autre'][index];
                                appState.setKidsMode(true, modeType: newMode);
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? kKidsPrimary.withOpacity(0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _modeIcons[index],
                                  color: isSelected ? kKidsPrimary : const Color(0xFF9CA3AF),
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _modeTitles[index],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? kKidsPrimary : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getModeIndex(String? modeType) {
    switch (modeType) {
      case 'essayer':
        return 0;
      case 'apprendre':
        return 1;
      case 'exercices':
        return 2;
      case 'autre':
        return 3;
      default:
        return 0;
    }
  }

  Widget _buildModeContent(BuildContext context, int modeIndex, AppState appState, bool isDark, ColorScheme colorScheme) {
    final content = [
      _essayerContent(context, appState, isDark),
      _apprendreContent(context, appState, isDark),
      _exercicesContent(context, appState, isDark),
      _autreContent(context, appState, isDark),
    ];
    return content[modeIndex];
  }

  Widget _essayerContent(BuildContext context, AppState appState, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Écouter le Coran',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Simple audio player
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Surah selector
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sourate', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.book, color: Color(0xFF10B981), size: 18),
                                SizedBox(width: 8),
                                Text('Al-Faatiha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Version', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.headphones, color: Colors.amber, size: 18),
                                SizedBox(width: 8),
                                Text('Mishary Al-Afasy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Play button
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Appuyez pour écouter',
                        style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Quick access buttons
                const Text('Sélection Rapide', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _quickChip('Sourate 1', Icons.book),
                    _quickChip('Sourate 2', Icons.book),
                    _quickChip('Sourate 3', Icons.book),
                    _quickChip('Sourate 55', Icons.book),
                    _quickChip('Sourate 78', Icons.book),
                    _quickChip('Sourate 112', Icons.book),
                    _quickChip('Sourate 113', Icons.book),
                    _quickChip('Sourate 114', Icons.book),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kKidsPrimary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kKidsPrimary, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kKidsPrimary)),
        ],
      ),
    );
  }

  Widget _apprendreContent(BuildContext context, AppState appState, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Apprendre le Tajweed',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Leçons de Tajweed',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _lessonCard('Makhraj', Icons.record_voice_over, 'Les points de pronunciation'),
                    _lessonCard('Ghunnah', Icons.auto_stereo, 'La nasalisation'),
                    _lessonCard('Qalqalah', Icons.flutter_dash, 'L\'saut du son'),
                    _lessonCard('Idgham', Icons.merge, 'La fusion des lettres'),
                    _lessonCard('Ikhfa', Icons.visibility_off, 'Le dissimulation'),
                    _lessonCard('Izhar', Icons.visibility, 'La clarté'),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Mémorisation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _lessonCard('Répétition', Icons.repeat, 'Répétez chaque verset'),
                    _lessonCard('Suivi', Icons.track_changes, 'Votre progression'),
                    _lessonCard('Quiz', Icons.quiz, 'Testez votre connaissance'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lessonCard(String title, IconData icon, String desc) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kKidsPrimary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: kKidsPrimary, size: 32),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kKidsPrimary)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _exercicesContent(BuildContext context, AppState appState, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Exercices de Tajweed',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Exercise cards
                _exerciseCard(
                  'Exercice 1',
                  'Makhraj des lettres',
                  'Apprenez les points de sortie des lettres arabes',
                  Icons.record_voice_over,
                  Icons.play_circle_outline,
                ),
                const SizedBox(height: 12),
                _exerciseCard(
                  'Exercice 2',
                  'Ghunnah & Qalqalah',
                  'Pratiquez la nasalisation et les sauts de sons',
                  Icons.auto_stereo,
                  Icons.play_circle_outline,
                ),
                const SizedBox(height: 12),
                _exerciseCard(
                  'Exercice 3',
                  'Règles de Noon Saakin',
                  'Idgham, Ikhfa, Izhar, Qalqalah',
                  Icons.article,
                  Icons.play_circle_outline,
                ),
                const SizedBox(height: 12),
                _exerciseCard(
                  'Exercice 4',
                  'Règles de Meem Saakin',
                  'Ikhfa Shafawi et Izhar Shafawi',
                  Icons.font_download,
                  Icons.play_circle_outline,
                ),
                const SizedBox(height: 24),
                // Progress section
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Votre Progression',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _progressCard('Exercice 1', 3, 5, Colors.green),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _progressCard('Exercice 2', 2, 5, Colors.amber),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _progressCard('Exercice 3', 0, 5, Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _progressCard('Exercice 4', 1, 5, Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _progressCard('Total', 6, 20, kKidsPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(String title, String subtitle, String desc, IconData icon, IconData actionIcon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kKidsPrimary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kKidsPrimary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kKidsPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kKidsPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(actionIcon, color: kKidsPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _progressCard(String title, int completed, int total, Color color) {
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF5F5F7),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$completed / $total',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _autreContent(BuildContext context, AppState appState, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Paramètres & Prières',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Settings section
                const Text(
                  'Configuration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _settingRow('Mode Sombre', Icons.dark_mode, () {}),
                _settingRow('Langue', Icons.language, () {}),
                _settingRow('Notifications', Icons.notifications, () {}),
                const Divider(),
                const SizedBox(height: 16),
                // Prayers section
                const Text(
                  'Prières & Adhkar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _prayerCard('Fajr', 'Aube', Icons.wb_sunny, Colors.orange),
                const SizedBox(height: 8),
                _prayerCard('Dhuhr', 'Midi', Icons.wb_sunny_outlined, Colors.yellow),
                const SizedBox(height: 8),
                _prayerCard('Asr', 'Après-midi', Icons.wb_sunny, Colors.blue),
                const SizedBox(height: 8),
                _prayerCard('Maghrib', 'Soir', Icons.nightlife, Colors.red),
                const SizedBox(height: 8),
                _prayerCard('Isha', 'Nuit', Icons.nights_stay, Colors.purple),
                const SizedBox(height: 16),
                // Adhkar
                const Text(
                  'Adhkar du Matin & Soir',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _adhkarChip('Matin', Icons.bedtime_outlined),
                    _adhkarChip('Soir', Icons.nights_outlined),
                    _adhkarChip('Après Prière', Icons.mosque),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF10B981)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
      onTap: onTap,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _prayerCard(String name, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
            ],
          ),
          Text(
            time,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _adhkarChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
        ],
      ),
    );
  }

  void _showExitGate(BuildContext context, AppState appState, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Quitter le Mode Enfant ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Pour quitter, entrez la séquence d\'adulte : 2, 4, 6, 8, 10',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showParentalGateForExit(context, appState, isDark);
            },
            child: const Text('Débloquer'),
          ),
        ],
      ),
    );
  }

  void _showParentalGateForExit(BuildContext context, AppState appState, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Gate Parental', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Entrez la séquence : 2 → 4 → 6 → 8 → 10',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final isFilled = index < appState.kidsGateStep;
                      return Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isFilled ? kKidsPrimary : kKidsPrimary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            isFilled ? '✓' : '${index + 1}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isFilled ? Colors.white : kKidsPrimary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (int i = 1; i <= 9; i++)
                        _numberButtonForExit(i, appState, setState, isDark),
                      const SizedBox(height: 8),
                      _numberButtonForExit(0, appState, setState, isDark),
                      Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle), child: const Center()),
                      IconButton(
                        icon: const Icon(Icons.backspace, color: Color(0xFF6B7280)),
                        onPressed: () {
                          if (appState.kidsGateStep > 0) {
                            appState.startKidsGate(useMath: false);
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _numberButtonForExit(int digit, AppState appState, StateSetter setState, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ElevatedButton(
        onPressed: () {
          if (appState.kidsGateStep < 5) {
            final success = appState.validateKidsGateSequence(digit);
            setState(() {});
            if (success) {
              Navigator.of(context).pop();
              appState.exitKidsMode();
              setState(() {
                _currentTab = 0; // Reset to first mode
              });
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size(60, 60),
        ),
        child: Text(
          digit.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ============================================================
// Protected route wrapper for all screens
// ============================================================

class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final String modeType;

  const ProtectedRoute({super.key, required this.child, required this.modeType});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    // Check if we're in kids mode and the route matches
    if (appState.isKidsMode && appState.kidsModeType != modeType) {
      // User is trying to access a route not matching current kids mode
      return KidsModeScreen();
    }

    return child;
  }
}
'''

# Find the last 2 lines (closing brace of the file)
lines = content.split('\n')

# Remove the last empty line if present
if lines and lines[-1].strip() == '':
    lines = lines[:-1]

# Remove the last line (closing brace)
# The file ends with } - we need to insert before it
# So we keep everything up to the last line, add our content, then add the closing brace back

# Find where to insert - after the last class definition
# The file ends with a class definition, so we insert after it

newContent = '\n'.join(lines[:-1]) + '\n' + kidsColors + adultScreen + '\n}\n'

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(newContent)
