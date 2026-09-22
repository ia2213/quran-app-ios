import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern: ], followed by a newline and then ],
# We want to remove the redundant one
pattern = re.compile(r'(\s*\]\s*,\s*)\n\s*\]\s*,', re.MULTILINE)
new_content = pattern.sub(r'\1', content)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)
