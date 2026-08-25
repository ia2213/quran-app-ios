@echo off
set ANDROID_HOME=C:\Users\Marc Hopf\Android\Sdk
set JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-25.0.4.7-hotspot
set PATH=C:\Users\Marc Hopf\flutter\bin;%PATH%
cd /d C:\Users\Marc Hopf\quran-app-ios
flutter build apk --debug
echo Exit code: %ERRORLEVEL%
