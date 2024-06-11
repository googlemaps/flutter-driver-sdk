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

import 'package:google_driver_flutter/google_driver_flutter.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

/// Cleans up the driver and navigation SDKs.
///
/// This is called when the app is sent to the background or when the app is
/// disposed, to be sure that the driver and navigation SDKs are properly
/// disposed for example app.
///
/// Production apps should restore the state of the driver and navigation SDKs
/// when the app is resumed. There is multiple ways to store the app state
/// between sessions, such as using shared preferences, or a database, and
/// developers should use the method that best fits their app's needs.
Future<void> cleanupAll() async {
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
