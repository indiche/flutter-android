FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

# Environment variables
ENV FLUTTER_VERSION=3.32.5
ENV FLUTTER_HOME=/opt/flutter
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=$ANDROID_SDK_ROOT
ENV JAVA_HOME=/usr/lib/jvm/temurin-21-jdk-amd64
ENV PATH=$HOME/.pub-cache/bin:$JAVA_HOME/bin:$PATH:$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools
ENV BUNDLE_SILENCE_ROOT_WARNING=1

# Install system dependencies and Java JDK
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        curl \
        git \
        unzip \
        xz-utils \
        zip \
        libglu1-mesa \
        gnupg \
        ca-certificates \
        ruby \
        ruby-dev \
        build-essential \
        libffi-dev \
    && curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add - \
    && echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends temurin-21-jdk

# Install Ruby gems (Fastlane)
RUN gem install bundler fastlane --no-document

# Download and install Flutter & Android SDK in parallel
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools \
    && ( \
        curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz \
        -o flutter.tar.xz & \
        curl -L https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip \
        -o cmdline-tools.zip & \
        curl -L https://dl.google.com/android/repository/platform-tools-latest-linux.zip \
        -o platform-tools.zip & \
        wait \
    ) \
    && tar xf flutter.tar.xz -C /opt \
    && unzip cmdline-tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools \
    && mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest \
    && unzip platform-tools.zip -d "$ANDROID_HOME" \
    && rm flutter.tar.xz cmdline-tools.zip platform-tools.zip

# Install Android SDK components
RUN yes | sdkmanager --licenses \
    && sdkmanager "platform-tools" \
    && sdkmanager "platforms;android-35" \
    && sdkmanager "build-tools;34.0.0" \
    && sdkmanager "ndk;26.3.11579264" \
    && sdkmanager "cmake;3.22.1"

# Clean up package cache
RUN apt-get remove -y curl gnupg \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create flutter user and set permissions
RUN groupadd -r flutter && useradd -r -g flutter flutter \
    && mkdir -p /home/flutter \
    && chown -R flutter:flutter /home/flutter \
    && chown -R flutter:flutter /opt/flutter \
    && chown -R flutter:flutter /opt/android-sdk

USER flutter

# Set user-local gem environment
ENV GEM_HOME=/home/flutter/.gem
ENV PATH=$PATH:/home/flutter/.gem/bin

# Configure Flutter and pre-cache Android dependencies
RUN flutter --disable-analytics \
    && flutter config --android-sdk $ANDROID_SDK_ROOT \
    && flutter config --enable-android \
    && flutter precache --android --no-web --no-linux --no-windows --no-macos --no-fuchsia \
    && flutter doctor \
    && flutter pub cache repair

RUN flutter pub global activate melos 7.0.0-dev.9

WORKDIR /workspace

