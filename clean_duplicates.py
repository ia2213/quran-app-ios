import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern: crossAxisAlignment: CrossAxisAlignment.X,\n\s+crossAxisAlignment: CrossAxisAlignment.X,
# Remplacer par un seul crossAxisAlignment
pattern = r'(crossAxisAlignment:\s*CrossAxisAlignment\.\w+,\s*\n\s+)(crossAxisAlignment:\s*CrossAxisAlignment\.\w+,)'
count = 0
while re.search(pattern, content):
    content = re.sub(pattern, r'\1', content)
    count += 1

print(f'crossAxisAlignment dupliqués corrigés: {count}')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Fichier corrigé')
