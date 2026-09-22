import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Corriger la structure cassée ligne 4250-4251
# Pattern: \n                                \nchildren: [
old1 = '\n                                \nchildren: ['
new1 = '\n                                children: ['

content = content.replace(old1, new1)

# Corriger la ligne 4256-4257
# Pattern: 'Sourate ${item['surahName']} — Verset ${item['verse']}',
#            style: TextStyle(...)
old2 = """                                       'Sourate ${item['surahName']} — Verset ${item['verse']}',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
                                      ),"""

new2 = """                                      Text(
                                        'Sourate ${item['surahName']} — Verset ${item['verse']}',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
                                      ),"""

content = content.replace(old2, new2)

# Corriger la ligne 4272-4273
# Pattern: ],\n                            );\n                          },
old3 = """                                ]
                              ),
                            );
                          },"""

new3 = """                                ],
                              ),
                            ),
                          },
                        ),"""

content = content.replace(old3, new3)

# Corriger la ligne 4278 
# Pattern:            ),
old4 = '''            ),
          ],'''

new4 = '''            ],
          ],'''

content = content.replace(old4, new4)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Corruptions corrigées')
