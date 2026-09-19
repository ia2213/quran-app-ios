import os
import subprocess
import json
import re
import zipfile
import requests

with open('C:/Users/Marc Hopf/.git-credentials') as f:
    text = f.read()
token = re.search(r':(ghp_[^@]+)@', text).group(1)

out_dir = 'C:/Users/Marc Hopf/quran-app-ios/build_artifacts'
os.makedirs(out_dir, exist_ok=True)
zip_path = os.path.join(out_dir, 'artifact.zip')

res_info = subprocess.run(['curl.exe', '-s', '-H', f'Authorization: token {token}', 'https://api.github.com/repos/ia2213/quran-app-ios/actions/runs/35376626608/artifacts'], capture_output=True, text=True)
art_id = json.loads(res_info.stdout)['artifacts'][0]['id']

subprocess.run(['curl.exe', '-sL', '-H', f'Authorization: token {token}', '-H', 'Accept: application/vnd.github+json', f'https://api.github.com/repos/ia2213/quran-app-ios/actions/artifacts/{art_id}/zip', '-o', zip_path])

with zipfile.ZipFile(zip_path, 'r') as z:
    z.extractall(out_dir)

ipa_path = os.path.join(out_dir, 'quran-app.ipa')
print('IPA extracted size:', os.path.getsize(ipa_path))

env_path = os.path.expanduser('~/AppData/Local/hermes/.env')
bot_token = None
with open(env_path) as f:
    for line in f:
        if line.startswith('TELEGRAM_BOT_TOKEN='):
            bot_token = line.strip().split('=', 1)[1]

if bot_token and os.path.exists(ipa_path):
    caption_text = (
        "📱 *Quran iOS — Version v3.6 (Nouveau Build IPA)*\n\n"
        "🔊 *Mises à jour :*\n"
        "• Prononciation nette du nom de la sourate (\"Sourate Al-Baqara\", sans phonème parasite)\n"
        "• Aucune annonce lors du saut de versets dans la même sourate (annonce uniquement lors du changement de sourate)"
    )

    with open(ipa_path, 'rb') as doc:
        res = requests.post(
            f'https://api.telegram.org/bot{bot_token}/sendDocument',
            data={'chat_id': '856614939', 'caption': caption_text, 'parse_mode': 'Markdown'},
            files={'document': ('quran-app.ipa', doc, 'application/octet-stream')}
        )
        print('Telegram status:', res.status_code, res.json().get('ok'))
