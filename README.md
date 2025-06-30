# Flutter Android Docker

A Docker image for Flutter Android development and CI/CD pipelines. This image includes Flutter SDK, Android SDK, Java JDK, and essential build tools in a secure, optimized container.

## Features

- **Flutter SDK**: Latest stable version (3.32.5)
- **Android SDK**: Complete Android development environment
  - Platform Tools (latest)
  - Android API 35
  - Build Tools 34.0.0
  - NDK 26.3.11579264
  - CMake 3.22.1
- **Java JDK**: Temurin OpenJDK 21
- **Ruby & Fastlane**: For automated deployment
- **Multi-Architecture**: Supports both AMD64 and ARM64
- **Security**: Runs as non-root user
- **Optimized**: Pre-cached dependencies and minimal image size

## Available Images

Images are automatically built and published to GitHub Container Registry:

```bash
# Latest stable
ghcr.io/indiche/flutter-android:latest
```

## Usage

### Basic Usage

```bash
# Pull the image
docker pull ghcr.io/indiche/flutter-android:latest

# Run interactively
docker run -it --rm \
  -v $(pwd):/workspace \
  ghcr.io/indiche/flutter-android:latest \
  bash
```

### Build Flutter App

```bash
# Build APK
docker run --rm \
  -v $(pwd):/workspace \
  ghcr.io/indiche/flutter-android:latest \
  flutter build apk --release

# Build App Bundle
docker run --rm \
  -v $(pwd):/workspace \
  ghcr.io/indiche/flutter-android:latest \
  flutter build appbundle --release
```

## Development

### Building Locally

```bash
# Build for current platform
docker build -t flutter-android .

# Build for multiple platforms
docker buildx build --platform linux/amd64,linux/arm64 -t flutter-android .
```

### Customization

You can extend this image for your specific needs:

```dockerfile
FROM ghcr.io/indiche/flutter-android:latest

# Install additional tools
USER root
RUN apt-get update && apt-get install -y your-package
USER flutter

# Set custom environment variables
ENV YOUR_VAR=value

# Copy your app
COPY . /workspace
WORKDIR /workspace

# Install dependencies
RUN flutter pub get
```

## GitHub Actions Workflow

This repository includes an automated build pipeline that:

1. **Triggers on**:
   - Push to `main`/`master` branches
   - Version tags (`v*`)
   - Pull requests

2. **Builds**:
   - Multi-architecture images (AMD64 + ARM64)
   - Optimized with build caching
   - Proper semantic versioning

3. **Publishes to**:
   - GitHub Container Registry (ghcr.io)
   - Automatic tagging based on git refs

### Workflow Tags

| Event | Tags Generated |
|-------|----------------|
| Push to main | `latest` |
| Push tag `v1.2.3` | `1.2.3`, `1.2`, `1` |
| Push to branch | `branch-name` |
| Pull request | `pr-123` |

## Development Workflow

```bash
# Clone repository
git clone https://github.com/indiche/flutter-android.git
cd flutter-android

# Build and test locally
docker build -t flutter-android:dev .

# Test with a Flutter project
docker run --rm -v /path/to/flutter/project:/workspace \
  flutter-android:dev flutter build apk
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

