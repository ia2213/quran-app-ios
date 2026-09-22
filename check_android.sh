#!/bin/bash
# Chargement de l'environnement Android
export ANDROID_HOME="/c/Users/Marc Hopf/Android/Sdk"
export ANDROID_SDK_ROOT="/c/Users/Marc Hopf/Android/Sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
echo "ANDROID_HOME=$ANDROID_HOME"
echo "ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT"
ls "$ANDROID_HOME/platforms/" 2>/dev/null || echo "PAS DE PLATFORMS"
ls "$ANDROID_HOME/build-tools/" 2>/dev/null || echo "PAS DE BUILD-TOOLS"
