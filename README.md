# Google Maps Driver (Preview)

## Description

This repository contains a Flutter plugin that allows users to use the [Google Maps Driver SDK](https://developers.google.com/maps/documentation/transportation-logistics/mobility) for Android and iOS. The plugin has a dependency on the [`google-maps-navigation`](https://github.com/googlemaps/flutter-navigation-sdk) plugin.



## Requirements

|             | Android | iOS       |
| ----------- | ------- | --------- |
| **Support** | SDK 23+ | iOS 14.0+ |

* A Flutter project
* A Google Cloud project with the [Navigation SDK enabled](https://developers.google.com/maps/documentation/navigation/android-sdk/set-up-project), the [Maps SDK for iOS enabled](https://developers.google.com/maps/documentation/navigation/ios-sdk/config) and the [Local Rides and Deliveries API enabled](https://console.developers.google.com/apis/library/fleetengine.googleapis.com)
* A Google Maps API key from the project above
* Project ID for the project above
* If targeting Android, [Google Play Services](https://developers.google.com/android/guides/overview) installed and enabled
* [Attributions and licensing text](https://developers.google.com/maps/documentation/navigation/android-sdk/set-up-project#include_the_required_attributions_in_your_app) added to your app

  
> [!IMPORTANT]
> Project ID need to be allowlisted before using this plugin. Please contact your Google representative to get your Project ID allowlisted.

## Installation

1. This repository is currently private. You will need to add the package dependency using [Git with SSH](https://docs.flutter.dev/packages-and-plugins/using-packages#dependencies-on-unpublished-packages) in the app's `pubspec.yaml` file. See [Connecting to GitHub with SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) for instructions on how to provide SSH keys.

```
  dependencies:
    google_driver_flutter:
      git:
        url: git@github.com:googlemaps/flutter-driver-sdk.git
```

2. Follow the instructions at the `google_navigation_flutter` plugin Readme to add your API key to the appropriate files in your Flutter project.
   
   [Google Maps Navigation Installation](https://github.com/googlemaps/flutter-navigation-sdk/blob/main/README.md#installation)

## Usage

Before initializing the delivery or the ridesharing driver, you must initialize the navigation session.

### Delivery Driver (LMFS)

```dart
import 'package:flutter/material.dart';
import 'package:google_driver_flutter/google_driver_flutter.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class DeliveryDriverSample extends StatefulWidget {
  const DeliveryDriverSample({super.key});

  @override
  State<DeliveryDriverSample> createState() => _DeliveryDriverSampleState();
}

class _DeliveryDriverSampleState extends State<DeliveryDriverSample> {
  String _providerId = "Your Google Maps Platform Provider ID";
  String _vehicleId = "Delivery Vehicle ID"; // Get vehicle ID from your backend

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!await GoogleMapsNavigator.areTermsAccepted()) {
      await GoogleMapsNavigationManager.showTermsAndConditionsDialog(
        'Example title',
        'Example company',
      );
    }
    // Note: make sure user has also granted location permissions before starting navigation session.
    await GoogleMapsNavigator.initializeNavigationSession();

    // Initialize delivery driver.
    await DeliveryDriver.initialize(
        providerId: _providerId,
        vehicleId: _vehicleId,
        onGetToken: (AuthTokenContext context) async {
            final String token = "token" // Get token from your backend
            return token;
        });

    // Enable location tracking.
    await DeliveryDriver.vehicleReporter
            .setLocationTrackingEnabled(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Maps Delivery Driver Sample')),
      body: GoogleMapsNavigationView(
              onViewCreated: _onViewCreated,
            ),
    );
  }

  ...

  @override
  void dispose() {
    ...
    DeliveryDriver.dispose();
    GoogleMapsNavigator.cleanup();
    ...
    super.dispose();
  }
}
```

See the [example](./example) directory for a complete delivery driver sample app.


### Ridesharing Driver (ODRD)

```dart
import 'package:flutter/material.dart';
import 'package:google_driver_flutter/google_driver_flutter.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class RidesharingDriverSample extends StatefulWidget {
  const RidesharingDriverSample({super.key});

  @override
  State<RidesharingDriverSample> createState() => _RidesharingDriverSampleState();
}

class _RidesharingDriverSampleState extends State<RidesharingDriverSample> {
  String _providerId = "Your Google Maps Platform Provider ID";
  String _vehicleId = "Ridesharing Vehicle ID"; // Get vehicle ID from your backend

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!await GoogleMapsNavigator.areTermsAccepted()) {
      await GoogleMapsNavigationManager.showTermsAndConditionsDialog(
        'Example title',
        'Example company',
      );
    }
    // Note: make sure user has also granted location permissions before starting navigation session.
    await GoogleMapsNavigator.initializeNavigationSession();

    // Initialize ridesharing driver.
    await RidesharingDriver.initialize(
        providerId: _providerId,
        vehicleId: _vehicleId,
        onGetToken: (AuthTokenContext context) async {
            final String token = "token" // Get token from your backend
            return token;
        });

    // Enable location tracking.
    await RidesharingDriver.vehicleReporter
            .setLocationTrackingEnabled(true);

    // After location tracking is enabled, the vehicle state can be set to online.
    await RidesharingDriver.vehicleReporter
            .setVehicleState(RidesharingVehicleState.online);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Maps Ridesharing Driver Sample')),
      body: GoogleMapsNavigationView(
              onViewCreated: _onViewCreated,
            ),
    );
  }

  ...

  @override
  void dispose() {
    ...
    RidesharingDriver.dispose();
    GoogleMapsNavigator.cleanup();
    ...
    super.dispose();
  }
}
```

See the [example](./example) directory for a complete ridesharing driver sample app.

## Contributing

See the [Contributing guide](https://github.com/googlemaps/flutter-driver-sdk/blob/main/CONTRIBUTING.md).

## Terms of Service

This package uses Google Maps Platform services, and any use of Google Maps Platform is subject to the [Terms of Service](https://cloud.google.com/maps-platform/terms).

For clarity, this package, and each underlying component, is not a Google Maps Platform Core Service.

## Support

This package is offered via an open source license. It is not governed by the Google Maps Platform Support [Technical Support Services Guidelines](https://cloud.google.com/maps-platform/terms/tssg), the [SLA](https://cloud.google.com/maps-platform/terms/sla), or the [Deprecation Policy](https://cloud.google.com/maps-platform/terms) (however, any Google Maps Platform services used by the library remain subject to the Google Maps Platform Terms of Service).

This package adheres to [semantic versioning](https://semver.org/) to indicate when backwards-incompatible changes are introduced. Accordingly, while the library is in version 0.x, backwards-incompatible changes may be introduced at any time. 

If you find a bug, or have a feature request, please [file an issue](https://github.com/googlemaps/flutter-driver-sdk/issues) on GitHub. If you would like to get answers to technical questions from other Google Maps Platform developers, ask through one of our [developer community channels](https://developers.google.com/maps/developer-community). If you'd like to contribute, please check the [Contributing guide](https://github.com/googlemaps/flutter-driver-sdk/blob/main/CONTRIBUTING.md).
