@echo off
set ANDROID_HOME=C:\Users\Marc Hopf\Android\Sdk
set ANDROID_SDK_ROOT=C:\Users\Marc Hopf\Android\Sdk
set PATH=%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\cmdline-tools\latest\bin;%PATH%
echo.
echo =======================================================
echo  BUILD APPLICATION QURAN - ANDROID RELEASE
echo =======================================================
echo.
echo ANDROID_HOME=%ANDROID_HOME%
echo ANDROID_SDK_ROOT=%ANDROID_SDK_ROOT%
echo.
echo Lancement du build...
echo.

cd /d "C:\Users\Marc Hopf\quran-app-ios"

"C:\Users\Marc Hopf\flutter\bin\flutter.bat" build apk --release

echo.
echo =======================================================
echo  BUILD TERMINÉ
echo =======================================================
echo.
