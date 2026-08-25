@echo off
:: Start TTS server in background
set PYTHON=C:\Users\Marc Hopf\AppData\Local\Python\bin\python.exe
start /B %PYTHON% "C:\Users\Marc Hopf\quran-app-ios\tts_server.py" 8766
timeout /t 2 >nul
echo TTS server started on port 8766
