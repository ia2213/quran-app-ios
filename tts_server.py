#!/usr/bin/env python3
"""Local TTS server for Quran app - uses edge-tts for high-quality voices."""
import sys
import os
import json
import tempfile
import asyncio
import threading
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

try:
    import edge_tts
except ImportError:
    print("ERROR: edge-tts not installed. Run: pip install edge-tts", file=sys.stderr)
    sys.exit(1)

# Cache for generated TTS
_tts_cache = {}
_cache_lock = threading.Lock()

# Available voices by language
VOICES = {
    'ar': {'male': 'ar-SA-HamedNeural', 'female': 'ar-SA-ZariyahNeural'},
    'fr': {'male': 'fr-FR-HenriNeural', 'female': 'fr-FR-DeniseNeural'},
    'en': {'male': 'en-US-AndrewNeural', 'female': 'en-US-AriaNeural'},
}

# Default voice gender per language
_default_gender = {'ar': 'male', 'fr': 'female', 'en': 'female'}


async def generate_tts_async(text, voice_name, output_path):
    """Async wrapper for edge-tts generation."""
    communicate = edge_tts.Communicate(text, voice_name)
    await communicate.save(output_path)


def get_tts_audio(text, lang, gender='default'):
    """Generate TTS audio and return path to MP3 file."""
    if not text or not text.strip():
        return None

    # Create cache key
    key = f"{text}|{lang}|{gender}"

    with _cache_lock:
        if key in _tts_cache:
            entry = _tts_cache[key]
            if os.path.exists(entry['path']):
                return entry['path']
            del _tts_cache[key]

    # Generate TTS
    voice_key = lang[:2]  # 'ar', 'fr', 'en'
    if gender == 'default':
        gender = _default_gender.get(voice_key, 'female')
    voice_name = VOICES.get(voice_key, {}).get(gender, VOICES.get(voice_key, {}).get('female', 'fr-FR-DeniseNeural'))

    # Create temp file
    tmp_dir = tempfile.gettempdir()
    filename = f"quran_tts_{int(time.time())}_{hash(key) % 10000}.mp3"
    filepath = os.path.join(tmp_dir, filename)

    try:
        # Run async generation in a thread
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            loop.run_until_complete(generate_tts_async(text, voice_name, filepath))
        finally:
            loop.close()

        with _cache_lock:
            # Clean old cache entries (keep max 50)
            if len(_tts_cache) > 50:
                oldest = min(_tts_cache.keys(), key=lambda k: _tts_cache[k]['time'])
                old_path = _tts_cache.pop(oldest)['path']
                if os.path.exists(old_path):
                    try:
                        os.remove(old_path)
                    except:
                        pass
            _tts_cache[key] = {'path': filepath, 'time': time.time()}

        return filepath
    except Exception as e:
        print(f"TTS generation error: {e}", file=sys.stderr)
        return None


class TTSServer(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path != '/tts':
            self.send_error(404)
            return

        params = parse_qs(parsed.query)
        text = params.get('text', [''])[0]
        lang = params.get('lang', ['fr'])[0]
        gender = params.get('gender', ['default'])[0]

        if not text:
            self.send_error(400, "Missing 'text' parameter")
            return

        # Generate TTS
        mp3_path = get_tts_audio(text, lang, gender)
        if not mp3_path or not os.path.exists(mp3_path):
            self.send_error(404, "TTS generation failed")
            return

        # Serve MP3
        try:
            with open(mp3_path, 'rb') as f:
                data = f.read()
            self.send_response(200)
            self.send_header('Content-Type', 'audio/mpeg')
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            self.send_error(500, str(e))

    def log_message(self, format, *args):
        pass


def run_server(port=8766):
    server = HTTPServer(('127.0.0.1', port), TTSServer)
    print(f"TTS server running on http://127.0.0.1:{port}/tts")
    server.serve_forever()


if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8766
    run_server(port)
