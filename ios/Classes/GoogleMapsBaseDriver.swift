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

import Flutter
import google_maps_navigation
import GoogleRidesharingDriver

class GoogleMapsBaseDriver {
  var _accessTokenProvider: AccessTokenProvider
  var _roadSnappedLocationProvider: GMSRoadSnappedLocationProvider?
  var _driverContext: GMTDDriverContext?

  init(messenger: FlutterBinaryMessenger) {
    _accessTokenProvider = AccessTokenProvider(messenger: messenger)
  }

  func getCommonVehicleReporter() throws -> GMTDVehicleReporter {
    fatalError("Method must be overridden")
  }

  func initialize(providerId: String, vehicleId: String,
                  abnormalTerminationReportingEnabled: Bool) throws {
    fatalError("Method must be overridden")
  }

  func isInitialized() throws -> Bool {
    fatalError("Method must be overridden")
  }

  func dispose() throws {
    fatalError("Method must be overridden")
  }

  func getProviderId() throws -> String {
    _driverContext?.providerID ?? ""
  }

  func getVehicleId() throws -> String {
    _driverContext?.vehicleID ?? ""
  }

  func isLocationTrackingEnabled() throws -> Bool {
    try getCommonVehicleReporter().locationTrackingEnabled
  }

  func setLocationTrackingEnabled(enabled: Bool) throws {
    if enabled {
      // TODO(jpetrell): Co-ordinate location enablement with Navigation SDK side
      ExposedGoogleMapsNavigator.enableRoadSnappedLocationUpdates()
    }

    let locationManager = CLLocationManager()
    locationManager.startUpdatingLocation()
    _roadSnappedLocationProvider?.startUpdatingLocation()

    try getCommonVehicleReporter().locationTrackingEnabled = enabled
  }

  func getLocationReportingIntervalMillis() throws -> Int64 {
    try Int64(1000.0 * (getCommonVehicleReporter().locationReportingInterval))
  }

  func setLocationReportingIntervalMillis(milliseconds: Int64) throws {
    try getCommonVehicleReporter().locationReportingInterval = Double(milliseconds) / 1000.0
  }

  func getDriverSdkVersion() throws -> String {
    GMTDDriverAPI.sdkVersion()
  }
}
