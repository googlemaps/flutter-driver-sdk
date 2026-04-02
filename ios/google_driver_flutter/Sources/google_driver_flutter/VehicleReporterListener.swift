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
import GoogleRidesharingDriver

class VehicleReporterListener: NSObject, GMTDVehicleReporterListener {
  private var _listenerApi: VehicleReporterListenerApi?
  private var _ridesharing: Bool = false

  func setup(messenger: FlutterBinaryMessenger, ridesharing: Bool) {
    _listenerApi = VehicleReporterListenerApi(binaryMessenger: messenger)
    _ridesharing = ridesharing
  }

  func vehicleReporter(
    _ vehicleReporter: GMTDVehicleReporter,
    didSucceed vehicleUpdate: GMTDVehicleUpdate
  ) {
    if _listenerApi != nil {
      _listenerApi?
        .onDidSucceed(
          vehicleUpdate:
            Convert
            .convertVehicleUpdateToDto(
              vehicleUpdate: vehicleUpdate,
              ridesharing: _ridesharing
            )
        ) { error in }
    }
  }

  func vehicleReporter(
    _ vehicleReporter: GMTDVehicleReporter,
    didFail vehicleUpdate: GMTDVehicleUpdate,
    withError error: Error
  ) {
    if _listenerApi != nil {
      // Top-level error always has error code 1 and message "Vehicle update failed.",
      // pass child error that describes the actual issue instead if available.
      let fullError = error as NSError
      var errorCode: Int = fullError.code
      var errorMessage: String = fullError.localizedDescription
      if let innerError = fullError.userInfo[NSUnderlyingErrorKey] as? NSError {
        let innerFullError = innerError as NSError
        errorCode = innerFullError.code
        errorMessage = innerFullError.localizedDescription
      }

      _listenerApi?.onDidFail(
        vehicleUpdate: Convert.convertVehicleUpdateToDto(
          vehicleUpdate: vehicleUpdate,
          ridesharing: _ridesharing
        ),
        errorCode: Convert.convertGRPCErrorCodes(errorCode: errorCode),
        errorMessage: errorMessage
      ) { error in }
    }
  }

  override init() {}
}
