import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remplacer les patterns ']),' suivis de ')' sur la ligne suivante
# quand ils sont dans le contexte d'une fermeture de Row
def fix_row_closures(content):
    lines = content.split('\n')
    new_lines = []
    i = 0
    fixed = 0
    
    while i < len(lines):
        line = lines[i]
        stripped = line.rstrip()
        
        # Chercher ']),' suivi de ')' sur la ligne suivante
        if i < len(lines) - 1:
            next_line = lines[i+1].rstrip()
            if stripped.endswith(']),') and next_line == ')':
                # Vérifier que c'est dans le contexte d'une Row (chercher dans les 3 lignes précédentes)
                context_before = '\n'.join(lines[max(0,i-3):i])
                if 'Row(' in context_before:
                    # Remplacer par '}),'
                    new_lines.append(line.replace(']),', '}),'))
                    fixed += 1
                    i += 1
                    continue
        
        new_lines.append(line)
        i += 1
    
    return '\n'.join(new_lines), fixed

content, fixed = fix_row_closures(content)
print(f'Row closures corrigés: {fixed}')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Done')
