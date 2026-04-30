// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_driver_flutter/google_driver_flutter.dart';
import 'package:google_driver_flutter_example/api/lmfs.dart';
import 'package:google_driver_flutter_example/api/odrd.dart';
// ignore: depend_on_referenced_packages
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:patrol/patrol.dart';

import 'shared.dart';

enum TokenBehavior { throwsException, emptyToken, invalidToken, validToken }

void main() {
  late LMFSManifest manifest;
  TokenResponse? tokenResponse;
  TokenBehavior tokenBehavior = TokenBehavior.validToken;
  late String providerId;
  late String vehicleId;

  int successCount = 0;
  int failureCount = 0;
  DriverException? reportedException;
  bool failTokenRequest = false;

  // iOS-only
  VehicleUpdate? reportedVehicleUpdate;

  // Android-only
  bool listeningStatus = false;
  DriverStatusLevel reportedLevel = DriverStatusLevel.info;
  DriverStatusCode reportedCode = DriverStatusCode.unknownError;
  String reportedMessage = '';

  setUp(() async {
    await cleanup();
    final bool backendRunning = await getLMFSApi().backendIsRunning();
    expect(backendRunning, true, reason: 'The LMFS backend is not running.');
    expect(hasProjectId(), true, reason: 'Project ID missing.');
    manifest = await initLMFSBackendForVehicle(
      vehicleId: 'vehicle_1',
      startLocation: NavigationWaypoint.withLatLngTarget(
        title: 'GWC3, 1505 Salado, Mountain View, CA 94043',
        target: const LatLng(latitude: 37.4231623, longitude: -122.0925322),
      ),
      deliveryWaypoints: <NavigationWaypoint>[
        NavigationWaypoint.withLatLngTarget(
          title: 'LMK6-A, 1947 Landings Drive, Mountain View, CA 94043',
          target: const LatLng(latitude: 37.41937, longitude: -122.08882),
        ),
        NavigationWaypoint.withLatLngTarget(
          title: 'Google Building 1900',
          target: const LatLng(latitude: 37.422917, longitude: -122.087528),
        ),
      ],
      stopWaypoints: <NavigationWaypoint>[
        NavigationWaypoint.withLatLngTarget(
          title: 'Google Landmark Bldgs',
          target: const LatLng(latitude: 37.41914, longitude: -122.08845),
        ),
        NavigationWaypoint.withLatLngTarget(
          title: 'CWF7+748, 1700 Amphitheatre Pkwy, Mountain View, CA 94043',
          target: const LatLng(latitude: 37.4231613, longitude: -122.087159),
        ),
      ],
    );

    providerId = manifest.vehicle.providerId;
    vehicleId = manifest.vehicle.vehicleId;
    expect(providerId, isNotEmpty);
    expect(vehicleId, isNotEmpty);
  });

  patrol('Test delivery driver initialization', (
    PatrolIntegrationTester $,
  ) async {
    // Check you can fetch the driver version without initializing the driver.
    expect(await DeliveryDriver.getDriverSdkVersion(), isNotEmpty);

    // Initially the driver is uninitialized.
    expect(await DeliveryDriver.isInitialized(), false);

    // Trying to initialize driver before navigation should throw an error.
    try {
      await DeliveryDriver.initialize(
        providerId: providerId,
        vehicleId: vehicleId,
        onGetToken: (AuthTokenContext context) {
          return Future<String>.value('');
        },
        abnormalTerminationReportingEnabled: true,
      );
      fail('Expected DriverInitializationException');
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverInitializationException>());
      expect(
        (e as DriverInitializationException).code,
        DriverInitializationError.navigationNotInitialized,
      );
    }

    // Trying to control vehicle reporter should throw
    // an error if DeliveryDriver has not yet been initialized.
    final DeliveryVehicleReporter reporter = DeliveryDriver.vehicleReporter;
    try {
      await reporter.setLocationTrackingEnabled(true);
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverNotInitializedException>());
    }
    try {
      await reporter.getLocationReportingInterval();
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverNotInitializedException>());
    }
    try {
      await reporter.setLocationReportingInterval(
        const Duration(milliseconds: 6001),
      );
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverNotInitializedException>());
    }
    try {
      await reporter.enrouteToNextStop();
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverNotInitializedException>());
    }
    try {
      await reporter.arrivedAtStop();
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverNotInitializedException>());
    }
    try {
      await reporter.completedStop();
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverNotInitializedException>());
    }
    try {
      await reporter.setVehicleStops(<VehicleStop>[]);
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverNotInitializedException>());
    }
    try {
      await reporter.getRemainingVehicleStops();
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverNotInitializedException>());
    }

    // Initialize navigation and start the simulation.
    await initializeNavigation($);
    await GoogleMapsNavigator.simulator.setUserLocation(
      manifest.vehicle.startLocation!.target,
    );

    // Initialize the driver.
    final Completer<void> tokenCompleter = Completer<void>();
    await DeliveryDriver.initialize(
      providerId: providerId,
      vehicleId: vehicleId,
      onGetToken: (AuthTokenContext context) async {
        if (tokenResponse == null ||
            DateTime.now().millisecondsSinceEpoch >
                tokenResponse!.expirationTimestampMs) {
          tokenResponse = await getLMFSApi().getToken(
            LMFSTokenType.deliveryDriver,
            manifest.vehicle.vehicleId,
          );
          tokenCompleter.complete();
        }

        switch (tokenBehavior) {
          case TokenBehavior.throwsException:
            throw Exception('Token retrieval from the backend failed.');
          case TokenBehavior.emptyToken:
            return '';
          case TokenBehavior.invalidToken:
            return 'invalid_token';
          case TokenBehavior.validToken:
            return tokenResponse!.token;
        }
      },
      abnormalTerminationReportingEnabled: true,
    );
    await $.pumpAndSettle();

    // Now the driver should be initialized.
    expect(await DeliveryDriver.isInitialized(), true);

    // Query the initial parameters from the created driver context.
    expect(await DeliveryDriver.getProviderId(), providerId);
    expect(await DeliveryDriver.getVehicleId(), vehicleId);

    // Set the location tracking enabled.
    // This is important as tokenResponse is not queried until the first
    // location update is to be sent.
    await reporter.setLocationTrackingEnabled(true);
    expect(await reporter.isLocationTrackingEnabled(), true);

    // Force token update.
    await GoogleMapsNavigator.simulator.setUserLocation(
      manifest.vehicle.startLocation!.target,
    );

    // Check that the token was requested at least once.
    await tokenCompleter.future;
    expect(tokenResponse, isNotNull);

    tokenBehavior = TokenBehavior.throwsException;
    try {
      await reporter.getRemainingVehicleStops();
      fail('Expected DriverException');
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverException>());
      expect((e as DriverException).message, isNotEmpty);
      if (Platform.isIOS) {
        expect(e.code, 'PERMISSION_DENIED');
      } else {
        expect(e.code, 'UNAUTHENTICATED');
      }
    }

    tokenBehavior = TokenBehavior.emptyToken;
    try {
      await reporter.getRemainingVehicleStops();
      fail('Expected DriverException');
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverException>());
      expect((e as DriverException).message, isNotEmpty);
      expect(e.code, 'PERMISSION_DENIED');
    }

    tokenBehavior = TokenBehavior.invalidToken;
    try {
      await reporter.getRemainingVehicleStops();
      fail('Expected DriverException');
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverException>());
      expect((e as DriverException).message, isNotEmpty);
      expect(e.code, 'UNAUTHENTICATED');
    }

    tokenBehavior = TokenBehavior.validToken;
    try {
      await reporter.getRemainingVehicleStops();
    } on Exception {
      fail('Expected the method call to succeed with a valid token.');
    }

    // Trying to initialize driver when driver already initialized should throw
    // an error.
    try {
      await DeliveryDriver.initialize(
        providerId: providerId,
        vehicleId: vehicleId,
        onGetToken: (AuthTokenContext context) {
          return Future<String>.value('');
        },
        abnormalTerminationReportingEnabled: true,
      );
      fail('Expected DriverInitializationException');
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverInitializationException>());
      expect(
        (e as DriverInitializationException).code,
        DriverInitializationError.apiAlreadyInitialized,
      );
    }

    await DeliveryDriver.dispose();
    await GoogleMapsNavigator.cleanup();
  });

  patrol('Test delivery driver tracking', (PatrolIntegrationTester $) async {
    /// Initialize navigation and start the simulation.
    await initializeNavigation($);
    await GoogleMapsNavigator.simulator.setUserLocation(
      manifest.vehicle.startLocation!.target,
    );

    final Completer<void> successCompleter = Completer<void>();
    final Completer<void> failureCompleter = Completer<void>();

    await DeliveryDriver.initialize(
      providerId: providerId,
      vehicleId: vehicleId,
      onGetToken: (AuthTokenContext context) async {
        if (tokenResponse == null ||
            DateTime.now().millisecondsSinceEpoch >
                tokenResponse!.expirationTimestampMs) {
          tokenResponse = await getLMFSApi().getToken(
            LMFSTokenType.deliveryDriver,
            manifest.vehicle.vehicleId,
          );
        }
        if (failTokenRequest) {
          return 'invalid_token';
        } else {
          return tokenResponse!.token;
        }
      },
      onStatusUpdate: Platform.isAndroid
          ? (
              DriverStatusLevel level,
              DriverStatusCode code,
              String message,
              DriverException? exception,
            ) {
              if (listeningStatus) {
                reportedLevel = level;
                reportedCode = code;
                reportedMessage = message;
                reportedException = exception;

                if (code == DriverStatusCode.defaultStatus) {
                  if (level == DriverStatusLevel.debug &&
                      message == 'Successful update.') {
                    successCount = successCount + 1;
                    successCompleter.complete();
                  }
                } else {
                  failureCount = failureCount + 1;
                  failureCompleter.complete();
                }
              }
            }
          : null,
      abnormalTerminationReportingEnabled: true,
    );
    await $.pumpAndSettle();

    // Now the driver should be initialized.
    expect(await DeliveryDriver.isInitialized(), true);

    final DeliveryVehicleReporter reporter = DeliveryDriver.vehicleReporter;

    // Try enabling and disabling location tracking.
    expect(await reporter.isLocationTrackingEnabled(), false);
    await reporter.setLocationTrackingEnabled(true);
    expect(await reporter.isLocationTrackingEnabled(), true);
    await reporter.setLocationTrackingEnabled(false);
    expect(await reporter.isLocationTrackingEnabled(), false);

    // Test default reporting interval returns sane values and that it can be overridden
    expect(
      (await reporter.getLocationReportingInterval()).inMilliseconds,
      greaterThan(100),
    );
    await reporter.setLocationReportingInterval(
      const Duration(milliseconds: 6001),
    );
    expect(
      (await reporter.getLocationReportingInterval()).inMilliseconds,
      6001,
    );

    // Trying to set less than 5 second or more than 60 second location reporting
    // interval throws an assertion.
    expect(() async {
      await reporter.setLocationReportingInterval(const Duration(seconds: 2));
    }, throwsAssertionError);
    expect(() async {
      await reporter.setLocationReportingInterval(const Duration(seconds: 61));
    }, throwsAssertionError);

    // Set the reporting interval to the smallest possible value to speed up the tests.
    await reporter.setLocationReportingInterval(const Duration(seconds: 5));

    // Tests that the location tracking works.
    // Uses the onStatusUpdate callback, which is Android-only.
    if (Platform.isAndroid) {
      expect(successCount, 0);
      expect(failureCount, 0);

      // Start listening to the location status updates.
      listeningStatus = true;
      await reporter.setLocationTrackingEnabled(true);
      expect(await reporter.isLocationTrackingEnabled(), true);

      // Check that the vehicle location tracking works.
      await successCompleter.future;
      expect(successCount, 1);
      expect(failureCount, 0);
      expect(reportedLevel, DriverStatusLevel.debug);
      expect(reportedCode, DriverStatusCode.defaultStatus);
      expect(reportedMessage, isNotNull);

      failTokenRequest = true;

      // Check that the failed location update is reported correctly.
      await failureCompleter.future;
      expect(successCount, 1);
      expect(failureCount, 1);

      expect(reportedLevel, DriverStatusLevel.error);
      expect(reportedCode, DriverStatusCode.backendConnectivityError);
      expect(reportedMessage, isNotNull);
      expect(reportedException!.code, 'UNAUTHENTICATED');
      expect(reportedException!.message, isNotEmpty);

      failTokenRequest = false;
    }

    // Tests that the location tracking works.
    // Utilizes VehicleReporterListener, which is iOS-only.
    if (Platform.isIOS) {
      // Start listening to the location status updates.
      reporter.setListener(
        VehicleReporterListener(
          onDidSucceed: (VehicleUpdate vehicleUpdate) {
            successCount = successCount + 1;
            successCompleter.complete();
            reportedVehicleUpdate = vehicleUpdate;
          },
          onDidFail: (VehicleUpdate vehicleUpdate, DriverException exception) {
            failureCount = failureCount + 1;
            reportedException = exception;
            reportedVehicleUpdate = vehicleUpdate;
            failureCompleter.complete();
          },
        ),
      );
      await reporter.setLocationTrackingEnabled(true);
      expect(await reporter.isLocationTrackingEnabled(), true);

      expect(successCount, 0);
      expect(failureCount, 0);

      // Check that the vehicle location tracking works
      await successCompleter.future;
      expect(successCount, 1);
      expect(failureCount, 0);
      expect(reportedVehicleUpdate, isNotNull);
      expect(reportedVehicleUpdate!.vehicleState, isNull);
      expect(
        reportedVehicleUpdate!.location?.latitude,
        closeTo(manifest.vehicle.startLocation!.target.latitude, 0.1),
      );
      expect(
        reportedVehicleUpdate!.location?.longitude,
        closeTo(manifest.vehicle.startLocation!.target.longitude, 0.1),
      );
      reportedVehicleUpdate = null;

      failTokenRequest = true;

      // Check that the failed location update is reported correctly.
      await failureCompleter.future;
      expect(successCount, 1);
      expect(failureCount, 1);
      expect(reportedVehicleUpdate, isNotNull);
      expect(reportedException, isNotNull);
      expect(reportedException!.code, 'UNAUTHENTICATED');
      expect(reportedException!.message, isNotEmpty);

      failTokenRequest = false;
    }

    await DeliveryDriver.dispose();
    await GoogleMapsNavigator.cleanup();
  });

  patrol('Test vehicle stop handling', (PatrolIntegrationTester $) async {
    /// Initialize navigation and start the simulation.
    await initializeNavigation($);
    await GoogleMapsNavigator.simulator.setUserLocation(
      manifest.vehicle.startLocation!.target,
    );

    final Completer<void> tokenCompleter = Completer<void>();
    await DeliveryDriver.initialize(
      providerId: providerId,
      vehicleId: vehicleId,
      onGetToken: (AuthTokenContext context) async {
        if (tokenResponse == null ||
            DateTime.now().millisecondsSinceEpoch >
                tokenResponse!.expirationTimestampMs) {
          tokenResponse = await getLMFSApi().getToken(
            LMFSTokenType.deliveryDriver,
            manifest.vehicle.vehicleId,
          );
          tokenCompleter.complete();
        }
        return tokenResponse!.token;
      },
      abnormalTerminationReportingEnabled: true,
    );
    await $.pumpAndSettle();

    // Now the driver should be initialized.
    expect(await DeliveryDriver.isInitialized(), true);

    final DeliveryVehicleReporter reporter = DeliveryDriver.vehicleReporter;

    // Set the location tracking enabled.
    // This is important as tokenResponse is not queried until the first
    // location update is to be sent.
    await reporter.setLocationTrackingEnabled(true);

    // Force token update.
    await GoogleMapsNavigator.simulator.setUserLocation(
      manifest.vehicle.startLocation!.target,
    );

    // Check that the token was requested at least once.
    await tokenCompleter.future;
    expect(tokenResponse, isNotNull);

    // Fetch the vehicle stops.
    // Note that this call throws an exception if the token is not fetched before.
    List<VehicleStop> vehicleStops = await reporter.getRemainingVehicleStops();

    // Check that the vehicle stops match the manifest.
    expect(vehicleStops.length, manifest.stops.length);
    for (int i = 0; i < vehicleStops.length; i++) {
      final VehicleStop stop = vehicleStops[i];
      expect(stop.vehicleStopState, VehicleStopState.newStop);

      expect(stop.taskInfoList.length, 1);
      expect(stop.taskInfoList[0].taskId, manifest.stops[i].taskIds[0]);
      expect(stop.waypoint?.target, manifest.stops[i].plannedWaypoint.target);
    }

    // Calculate route to the first stop.
    final Destinations destinations = Destinations(
      waypoints: <NavigationWaypoint>[vehicleStops.first.waypoint!],
      displayOptions: NavigationDisplayOptions(showDestinationMarkers: false),
    );
    final NavigationRouteStatus status =
        await GoogleMapsNavigator.setDestinations(destinations);
    expect(status, NavigationRouteStatus.statusOk);
    await $.pumpAndSettle();

    /// Start guidance.
    await GoogleMapsNavigator.startGuidance();
    await $.pumpAndSettle();

    // Report that the vehicle is enroute to the first stop.
    vehicleStops = await reporter.enrouteToNextStop();

    // Check the first stop is now enroute.
    // TODO(jpetrell): Skip the test, the vehicle stop state changes currently fail and are not accepted by the Fleet Engine backend.
    // expect(vehicleStops.first.vehicleStopState, VehicleStopState.enroute);

    // Report that the vehicle has now arrived at the first stop.
    vehicleStops = await reporter.arrivedAtStop();

    // Check the first stop has now arrived.
    expect(vehicleStops.length, 2);
    // TODO(jpetrell): Skip the test, the vehicle stop state changes currently fail and are not accepted by the Fleet Engine backend.
    // expect(vehicleStops.first.vehicleStopState, VehicleStopState.enroute);
    // expect(vehicleStops.first.vehicleStopState, VehicleStopState.arrived);

    // Report that the vehicle has completed the first stop.
    vehicleStops = await reporter.completedStop();
    expect(vehicleStops.length, 1);
    expect(vehicleStops.first.vehicleStopState, VehicleStopState.newStop);

    // TODO(jpetrell): Test vehicle stop creation properly with new tasks.
    // await reporter.setVehicleStops(<VehicleStop>[ .. ]);

    // Clear the instance
    await DeliveryDriver.dispose();

    // The driver should return to an uninitialized state.
    expect(await DeliveryDriver.isInitialized(), false);
  });

  patrol('Test Ridesharing driver initialization', (
    PatrolIntegrationTester $,
  ) async {
    tokenResponse = null;
    // Check you can fetch the driver version without initializing the driver.
    expect(await RidesharingDriver.getDriverSdkVersion(), isNotEmpty);

    // Initially the driver is uninitialized.
    expect(await RidesharingDriver.isInitialized(), false);

    // Trying to initialize driver before navigation should throw an error.
    try {
      await RidesharingDriver.initialize(
        providerId: providerId,
        vehicleId: vehicleId,
        onGetToken: (AuthTokenContext context) {
          return Future<String>.value('');
        },
        abnormalTerminationReportingEnabled: true,
      );
      fail('Expected DriverInitializationException');
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverInitializationException>());
      expect(
        (e as DriverInitializationException).code,
        DriverInitializationError.navigationNotInitialized,
      );
    }

    // Trying to control vehicle reporter should throw
    // an error if RidesharingDriver has not yet been initialized.
    final RidesharingVehicleReporter reporter =
        RidesharingDriver.vehicleReporter;
    try {
      await reporter.setLocationTrackingEnabled(true);
      fail('Expected DriverNotInitializedException');
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverNotInitializedException>());
    }
    try {
      await reporter.getLocationReportingInterval();
      fail('Expected DriverNotInitializedException');
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverNotInitializedException>());
    }
    try {
      await reporter.setLocationReportingInterval(
        const Duration(milliseconds: 6001),
      );
      fail('Expected DriverNotInitializedException');
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverNotInitializedException>());
    }
    try {
      await reporter.setVehicleState(VehicleState.online);
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverNotInitializedException>());
    }

    /// Initialize navigation and start the simulation.
    await initializeNavigation($);
    await GoogleMapsNavigator.simulator.setUserLocation(
      manifest.vehicle.startLocation!.target,
    );

    // Initialize the driver.
    final Completer<void> tokenCompleter = Completer<void>();
    await RidesharingDriver.initialize(
      providerId: providerId,
      vehicleId: vehicleId,
      onGetToken: (AuthTokenContext context) async {
        if (tokenResponse == null ||
            DateTime.now().millisecondsSinceEpoch >
                tokenResponse!.expirationTimestampMs) {
          tokenResponse = await getODRDApi().getToken(
            ODRDTokenType.driver,
            manifest.vehicle.vehicleId,
          );
          tokenCompleter.complete();
        }
        return tokenResponse!.token;
      },
      abnormalTerminationReportingEnabled: true,
    );
    await $.pumpAndSettle();

    // Now the driver should be initialized.
    expect(await RidesharingDriver.isInitialized(), true);

    // Query the initial parameters from the created driver context.
    expect(await RidesharingDriver.getProviderId(), providerId);
    expect(await RidesharingDriver.getVehicleId(), vehicleId);

    // Set the location tracking enabled.
    // This is important as tokenResponse is not queried until the first
    // location update is to be sent.
    await reporter.setLocationTrackingEnabled(true);
    expect(await reporter.isLocationTrackingEnabled(), true);

    // Force token update.
    await GoogleMapsNavigator.simulator.setUserLocation(
      manifest.vehicle.startLocation!.target,
    );
    await $.pumpAndSettle();

    // Check that the token was requested at least once.
    await tokenCompleter.future;
    expect(tokenResponse, isNotNull);

    try {
      await reporter.setVehicleState(VehicleState.online);
    } on Exception {
      fail('Expected the method call to succeed with a valid token.');
    }

    // Trying to initialize driver when driver already initialized should throw
    // an error.
    try {
      await RidesharingDriver.initialize(
        providerId: providerId,
        vehicleId: vehicleId,
        onGetToken: (AuthTokenContext context) {
          return Future<String>.value('');
        },
        abnormalTerminationReportingEnabled: true,
      );
      fail('Expected DriverInitializationException');
    } on Exception catch (e) {
      expect(e, const TypeMatcher<DriverInitializationException>());
      expect(
        (e as DriverInitializationException).code,
        DriverInitializationError.apiAlreadyInitialized,
      );
    }

    await RidesharingDriver.dispose();
    await GoogleMapsNavigator.cleanup();
  });
}
