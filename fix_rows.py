import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

fixed = 0
for i, line in enumerate(lines):
    # Chercher les lignes qui finissent par ']),' qui devraient finir par ']),'
    # dans le contexte d'une fermeture de Row
    stripped = line.rstrip()
    if stripped.endswith(']),') and 'Row' not in line:
        # Vérifier le contexte : la ligne précédente doit contenir 'Row(' ou 'child: Row'
        # et la ligne ne doit pas être dans une liste de widgets
        if i > 0:
            prev = lines[i-1].rstrip()
            # Si la ligne précédente est une ouverture de Row ou child: Row
            if 'Row(' in prev or 'child: Row' in prev or '    Row(' in prev:
                # Remplacer ']),' par ']),' — c'est correct
                pass
            # Si la ligne précédente est une fermeture de liste ']' et avant un ')', 
            # alors c'est probablement un bug
            elif prev.endswith(']') and i+1 < len(lines) and lines[i+1].strip() == ')':
                # C'est ']),' suivi de ')' → c'est correct pour une closure
                pass
    
    # Pattern spécifique : ligne suvante par ']),' puis ')' sur la ligne suivante
    # quand il devrait être '}),' (fermeture de Row)
    if i < len(lines) - 1:
        next_line = lines[i+1].rstrip()
        if stripped.endswith(']),') and next_line == ')' and 'Row(' in ''.join(lines[max(0,i-3):i]):
            # Remplacer ']),' par '}),'
            old = line
            new = line.replace(']),', '}),')
            if old != new:
                lines[i] = new
                fixed += 1

print(f'Patterns "])," → "})," corrigés: {fixed}')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print('Fichier corrigé')
