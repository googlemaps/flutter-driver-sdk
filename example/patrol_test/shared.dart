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
import 'package:meta/meta.dart';

// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://docs.flutter.dev/cookbook/testing/integration/introduction

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_driver_flutter/google_driver_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:patrol/patrol.dart';
import 'package:permission_handler/permission_handler.dart';

/// Timeout for tests in seconds.
const int testTimeoutSeconds = 480; // 8 minutes

/// Timeout for controller completer in seconds. This timeout is set to be
/// long as on CI emulator the controller creation can take a while.
const int controllerCompleterTimeoutSeconds = 30;

final PlatformAutomatorConfig _platformAutomatorConfig =
    PlatformAutomatorConfig.fromOptions(
      findTimeout: Duration(seconds: 120),
      connectionTimeout: Duration(seconds: 240),
    );

/// Pumps a [navigationView] widget in tester [$] and then waits until it settles.
Future<void> pumpNavigationView(
  PatrolIntegrationTester $,
  GoogleMapsNavigationView navigationView,
) async {
  await $.pumpWidget(wrapNavigationView(navigationView));
  await $.pumpAndSettle();
}

/// Wraps a [navigationView] in widgets.
Widget wrapNavigationView(GoogleMapsNavigationView navigationView) {
  return MaterialApp(
    home: Scaffold(body: Center(child: navigationView)),
  );
}

Future<void> _acceptTermsAndConditionsDialog(PatrolIntegrationTester $) async {
  if (Platform.isAndroid) {
    await $.platformAutomator.tap(Selector(text: 'Got It'));
  } else if (Platform.isIOS) {
    await $.platformAutomator.tap(Selector(text: 'OK'));
  } else {
    fail('Unsupported platform: ${Platform.operatingSystem}');
  }
}

Future<void> checkTermsAndConditionsAcceptance(
  PatrolIntegrationTester $,
) async {
  if (!await GoogleMapsNavigator.areTermsAccepted()) {
    // Reset terms to ensure the dialog is always shown.
    await GoogleMapsNavigator.resetTermsAccepted();

    /// Request native TOS dialog.
    final Future<bool> tosAccepted =
        GoogleMapsNavigator.showTermsAndConditionsDialog(
          'test_title',
          'test_company_name',
        );
    await $.pumpAndSettle();

    // On Android wait a bit after showing the TOS dialog, as it can take a
    // moment to appear and be ready for interaction.
    if (Platform.isAndroid) {
      await $.tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    }

    await _acceptTermsAndConditionsDialog($);

    // Verify the TOS was accepted
    await tosAccepted.then((bool accept) {
      expect(accept, true);
    });
  }
}

/// Grant location permissions if not granted.
Future<void> checkLocationDialogAcceptance(PatrolIntegrationTester $) async {
  if (!await Permission.locationWhenInUse.isGranted) {
    /// Request native location permission dialog.
    final Future<PermissionStatus> locationGranted = Permission
        .locationWhenInUse
        .request();

    if (await $.platformAutomator.mobile.isPermissionDialogVisible(
      timeout: const Duration(seconds: 5),
    )) {
      // Grant location permission.
      await $.platformAutomator.mobile.grantPermissionWhenInUse();
    }

    // Check that the location permission is granted.
    await locationGranted.then((PermissionStatus status) async {
      expect(status, PermissionStatus.granted);
    });
  }
}

Future<GoogleNavigationViewController> initializeNavigation(
  PatrolIntegrationTester $,
) async {
  await checkLocationDialogAcceptance($);
  await checkTermsAndConditionsAcceptance($);
  await GoogleMapsNavigator.initializeNavigationSession();
  expect(await GoogleMapsNavigator.isInitialized(), true);

  final Completer<GoogleNavigationViewController> controllerCompleter =
      Completer<GoogleNavigationViewController>();

  final Key key = GlobalKey();
  await pumpNavigationView(
    $,
    GoogleMapsNavigationView(
      key: key,
      onViewCreated: (GoogleNavigationViewController viewController) {
        controllerCompleter.complete(viewController);
      },
    ),
  );

  final GoogleNavigationViewController controller =
      await controllerCompleter.future;

  return controller;
}

Future<void> cleanup() async {
  try {
    await GoogleMapsNavigator.cleanup();
  } catch (_) {
    // ignore
  }
  try {
    await DeliveryDriver.dispose();
  } catch (_) {
    // ignore
  }
  try {
    await RidesharingDriver.dispose();
  } catch (_) {
    // ignore
  }
}

/// Create a wrapper [patrol] for [patrolTest] with custom options.
@isTest
void patrol(
  String description,
  Future<void> Function(PatrolIntegrationTester) callback, {
  bool skip = false,
  int timeoutSeconds = testTimeoutSeconds,
  PlatformAutomatorConfig? platformAutomatorConfig,
}) {
  patrolTest(
    description,
    (PatrolIntegrationTester $) async {
      $.log('Starting test: $description');
      await callback($);
      $.log('Test completed: $description');
    },
    skip: skip,
    timeout: Timeout(Duration(seconds: timeoutSeconds)),
    platformAutomatorConfig:
        platformAutomatorConfig ?? _platformAutomatorConfig,
  );
}
