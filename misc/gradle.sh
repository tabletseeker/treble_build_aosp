#!/bin/bash

set -e

JAVA_DIR=$(ls /usr/lib/jvm | grep -Em1 java-[0-9]{2}-openjdk)

export PATH=/usr/lib/jvm/$JAVA_DIR/bin:$PATH
export JAVA_HOME=/usr/lib/jvm/$JAVA_DIR
export ANDROID_HOME=$PWD/sdk
export ANDROID_SDK_ROOT=$PWD/sdk

gradleTarget=assembleDebug
target=debug
file=app-debug
if [ "$1" == "release" ];then
    gradleTarget=assembleRelease
    target=release
    file=app-release-unsigned
fi
./gradlew $gradleTarget
LD_LIBRARY_PATH=./signapk/ java -jar signapk/signapk.jar keys/platform.x509.pem keys/platform.pk8 ./app/build/outputs/apk/$target/${file}.apk TrebleApp.apk
