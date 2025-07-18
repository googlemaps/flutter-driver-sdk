// Copyright 2024 Google LLC
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

/// The severity of the driver status message.
///
/// Android-only.
///
/// {@category Delivery Driver}
/// {@category Ridesharing Driver}
enum DriverStatusLevel {
  /// Debug messages.
  debug,

  /// Info messages.
  info,

  /// Warning messages.
  warning,

  /// Error messages.
  error,
}

/// The driver status code of the driver update.
///
/// This code is used to indicate the status of the driver.
/// Android-only.
///
/// {@category Delivery Driver}
/// {@category Ridesharing Driver}
enum DriverStatusCode {
  /// Default debug and warning messages, no error occurred.
  defaultStatus,

  /// The status code hasn't been defined.
  unknownError,

  /// Service error.
  serviceError,

  /// File access error.
  fileAccessError,

  /// The vehicle was not found.
  vehicleNotFound,

  /// Failed to connect to the backend.
  backendConnectivityError,

  /// No permission to access the backend.
  permissionDenied,

  /// Traveled route error.
  traveledRouteError,
}
