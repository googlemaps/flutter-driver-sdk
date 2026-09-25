# Changelog

## [0.7.0](https://github.com/googlemaps/flutter-driver-sdk/compare/0.6.1...0.7.0) (2026-09-25)


### ⚠ BREAKING CHANGES

* CocoaPods is no longer supported for iOS.
* All consumers must use Flutter 3.44+.
* iOS consumers must enable Swift Package Manager.
* google_navigation_flutter is now pinned to 0.10.0.
* Android consumers must use Android Gradle Plugin 8.13.2+ and enable core library desugaring with com.android.tools:desugar_jdk_libs_nio:2.1.5 or newer.

### Features

* upgrade Driver SDKs and migrate iOS to Swift Package Manager ([#295](https://github.com/googlemaps/flutter-driver-sdk/issues/295)) ([7ffa0d2](https://github.com/googlemaps/flutter-driver-sdk/commit/7ffa0d22d6e7f6b33707ab1d2b5dcc68fc5600d2))

## [0.6.1](https://github.com/googlemaps/flutter-driver-sdk/compare/0.6.0...0.6.1) (2026-06-05)


### Features

* modernize Android build toolchain ([#271](https://github.com/googlemaps/flutter-driver-sdk/issues/271)) ([38ca898](https://github.com/googlemaps/flutter-driver-sdk/commit/38ca898df1ae6ed5b06842c89a910dc37450ce7f))

## [0.6.0](https://github.com/googlemaps/flutter-driver-sdk/compare/0.5.0...0.6.0) (2026-05-06)


### ⚠ BREAKING CHANGES

* Updated google_navigation_flutter dependency from 0.8.x to 0.9.x. See google_navigation_flutter releases for additional breaking changes. ([#254](https://github.com/googlemaps/flutter-driver-sdk/issues/254))

### Features

* internal usage attribution ID ([#236](https://github.com/googlemaps/flutter-driver-sdk/issues/236)) ([b785afe](https://github.com/googlemaps/flutter-driver-sdk/commit/b785afefffd77d4c22776a41deec6af298ecc481))
* upgrade to the latest google_navigation_flutter version 0.9.x ([#254](https://github.com/googlemaps/flutter-driver-sdk/issues/254)) ([f900ea5](https://github.com/googlemaps/flutter-driver-sdk/commit/f900ea5285b728365fdad7248d6e7d8d2a00ec1b))

## [0.5.0](https://github.com/googlemaps/flutter-driver-sdk/compare/0.4.0...0.5.0) (2026-04-02)


### ⚠ BREAKING CHANGES

* Minimum Android API level raised from 24 to 26. Updated google_navigation_flutter dependency from 0.6.x to 0.8.x. See google_navigation_flutter releases for additional breaking changes.

### Features

* upgrade google navigation flutter package version to 0.8.4 ([#228](https://github.com/googlemaps/flutter-driver-sdk/issues/228)) ([e5e9881](https://github.com/googlemaps/flutter-driver-sdk/commit/e5e9881ba48bfcdd128731c0e8260f9502321a00))

## [0.4.0](https://github.com/googlemaps/flutter-driver-sdk/compare/0.3.0...0.4.0) (2025-08-04)


### ⚠ BREAKING CHANGES

* upgrade to latest sdks ([#142](https://github.com/googlemaps/flutter-driver-sdk/issues/142))

### Features

* upgrade to latest sdks ([#142](https://github.com/googlemaps/flutter-driver-sdk/issues/142)) ([d95d3a3](https://github.com/googlemaps/flutter-driver-sdk/commit/d95d3a3669b0abd59c24d36ed8dad651e59ab457))

## 0.3.0-beta

This is the beta release of the Google Maps Driver package for Flutter. It is an early look at the package and is intended for testing and feedback collection. The functionalities and APIs in this version are subject to change.

** BREAKING CHANGES: **
- Package name has been changed to `google_driver_flutter` from `google_maps_driver`.

## 0.2.0-beta

This is the beta release of the Google Maps Driver package for Flutter. It is an early look at the package and is intended for testing and feedback collection. The functionalities and APIs in this version are subject to change.

** BREAKING CHANGES: **
- Starts using publicly available and renamed `google_navigation_flutter` package.

## 0.1.2-beta

This is the beta release of the Google Maps Driver package for Flutter. It is an early look at the package and is intended for testing and feedback collection. The functionalities and APIs in this version are subject to change.

- Updates minimum supported SDK version to Flutter 3.22.1/Dart 3.4.
- Update patrol version to 3.7.2

## 0.1.1-beta

This is the beta release of the Google Maps Driver package for Flutter. It is an early look at the package and is intended for testing and feedback collection. The functionalities and APIs in this version are subject to change.

**Bug fixes:**
- Pin Driver SDK for iOS to version 3.2.x to fix build issues on iOS.

## 0.1.0-beta

This is the beta release of the Google Maps Driver package for Flutter. It is an early look at the package and is intended for testing and feedback collection. The functionalities and APIs in this version are subject to change.

**Key Features:**
- Integration of Google Maps Driver SDK with Flutter
- Support for both Delivery Driver API and Ridesharing Driver API

**Notes:**
- This version demonstrates the core capabilities of the package and serves as a basis for community feedback and further development.
- Users are encouraged to report bugs and suggest improvements to enhance the package's stability and functionality.
