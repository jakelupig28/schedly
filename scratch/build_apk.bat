@echo off
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "ANDROID_HOME=C:\Users\User\AppData\Local\Android\Sdk"
set "ANDROID_SDK_ROOT=C:\Users\User\AppData\Local\Android\Sdk"
set "PATH=C:\flutter\bin;%JAVA_HOME%\bin;%PATH%"

echo Checking Java version:
"%JAVA_HOME%\bin\java.exe" -version

echo Checking Flutter version:
call flutter --version

echo Building APK:
cd /d "C:\Users\User\schedly\frontend"
call flutter build apk --release -v
