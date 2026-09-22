#!/bin/bash
# Build APK avec environnement Android complet
export ANDROID_HOME="/c/Users/Marc Hopf/Android/Sdk"
export ANDROID_SDK_ROOT="/c/Users/Marc Hopf/Android/Sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/build-tools/35.0.0:$PATH"

cd "/c/Users/Marc Hopf/quran-app-ios"
echo "ANDROID_HOME=$ANDROID_HOME"
echo "PATH contient platform-tools: $(echo $PATH | grep -o '/platform-tools' | head -1)"

"/c/Users/Marc Hopf/flutter/bin/flutter" build apk --release 2>&1
