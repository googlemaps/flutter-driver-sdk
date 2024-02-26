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

import Flutter
import Foundation
import google_maps_navigation
import GoogleRidesharingDriver

// Keep in sync with GoogleMapsNavigationSessionManager.kt
enum GoogleMapsRidesharingDriverError: Error {
  case driverNotInitialized
  case driverInitializationFailed
  case noRoadSnappedLocationProvider
}

class GoogleMapsRidesharingDriver: GoogleMapsBaseDriver, RidesharingDriverApi {
  private var _ridesharingDriverAPI: GMTDRidesharingDriverAPI? = nil
  private var _vehicleReporterListener: VehicleReporterListener? = nil

  override init(messenger: FlutterBinaryMessenger) {
    super.init(messenger: messenger)
    RidesharingDriverApiSetup.setUp(binaryMessenger: messenger, api: self)
    _vehicleReporterListener = VehicleReporterListener()
    _vehicleReporterListener?.setup(messenger: messenger, ridesharing: false)
  }

  override func getCommonVehicleReporter() throws -> GMTDVehicleReporter {
    if _ridesharingDriverAPI != nil {
      return _ridesharingDriverAPI!.vehicleReporter
    } else {
      throw GoogleMapsRidesharingDriverError.driverNotInitialized
    }
  }

  override func initialize(providerId: String, vehicleId: String,
                           abnormalTerminationReportingEnabled: Bool) throws {
    let navigator = try ExposedGoogleMapsNavigator.getNavigator()
    GMSNavigationServices.createNavigationSession()

    _driverContext = GMTDDriverContext(
      accessTokenProvider: _accessTokenProvider,
      providerID: providerId,
      vehicleID: vehicleId,
      navigator: navigator
    )
    if _driverContext != nil {
      _ridesharingDriverAPI = GMTDRidesharingDriverAPI(driverContext: _driverContext!)

      // Should not fail since the ExposedGoogleMapsNavigator.getNavigator() few
      // lines above should have thrown sessionNotInitialized already.
      if let _roadSnappedLocationProvider = try ExposedGoogleMapsNavigator
        .getRoadSnappedLocationProvider() {
        if let vehicleReporter = _ridesharingDriverAPI?.vehicleReporter {
          _roadSnappedLocationProvider.add(vehicleReporter)
        } else {
          // Should not happen.
          throw GoogleMapsRidesharingDriverError.driverInitializationFailed
        }
      } else {
        // Should not happen.
        throw GoogleMapsRidesharingDriverError.noRoadSnappedLocationProvider
      }

      _ridesharingDriverAPI?.vehicleReporter.add(_vehicleReporterListener!)

      GMTDRidesharingDriverAPI
        .setAbnormalTerminationReportingEnabled(abnormalTerminationReportingEnabled)
    }
  }

  override func isInitialized() throws -> Bool {
    _ridesharingDriverAPI != nil
  }

  override func dispose() throws {
    _ridesharingDriverAPI = nil
    _driverContext = nil
    if let vehicleReporter = _ridesharingDriverAPI?.vehicleReporter {
      _roadSnappedLocationProvider?.remove(vehicleReporter)
    }
    _roadSnappedLocationProvider = nil
  }

  func setVehicleState(state: VehicleStateDto) throws {
    if _ridesharingDriverAPI != nil {
      _ridesharingDriverAPI?.vehicleReporter
        .update(Convert.convertVehicleStateFromDto(state: state))
    } else {
      throw GoogleMapsRidesharingDriverError.driverNotInitialized
    }
  }
}
