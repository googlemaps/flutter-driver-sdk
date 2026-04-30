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
import GoogleMaps
import UIKit

public class GoogleMapsDriverPlugin: NSObject, FlutterPlugin {
  private static var _deliveryDriverApi: GoogleMapsDeliveryDriver?
  private static var _ridesharingDriverApi: GoogleMapsRidesharingDriver?
  private static var _commomApiHandler: GoogleMapsCommonApiHandler?

  public static func register(with registrar: FlutterPluginRegistrar) {
    GMSServices.addInternalUsageAttributionID(SdkVersion.attributionId)

    _deliveryDriverApi = GoogleMapsDeliveryDriver(messenger: registrar.messenger())
    _ridesharingDriverApi = GoogleMapsRidesharingDriver(messenger: registrar.messenger())
    _commomApiHandler = GoogleMapsCommonApiHandler(
      messenger: registrar.messenger(),
      deliveryDriverApi: _deliveryDriverApi!,
      ridesharingDriverApi: _ridesharingDriverApi!
    )
  }
}
