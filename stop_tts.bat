@echo off
:: Stop TTS server
taskkill /F /IM python.exe /FI "WINDOWTITLE eq TTS*" 2>nul
taskkill /F /IM python.exe /FI "COMMANDLINE eq *tts_server.py*" 2>nul
echo TTS server stopped
