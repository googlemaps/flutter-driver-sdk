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

//
//  GoogleMapsCommonApiHandler.swift
//  google_maps_driver
//
//  Created by Joonas Kerttula on 18.1.2024.
//

import Flutter
import Foundation

// Keep in sync with GoogleMapsNavigationSessionManager.kt
enum GoogleMapsDriverError: Error {
  case apiAlreadyInitialized
  case notSupported
}

class GoogleMapsCommonApiHandler: CommonDriverApi {
  private let _deliveryDriverApi: GoogleMapsDeliveryDriver
  private let _ridesharingDriverApi: GoogleMapsRidesharingDriver

  init(messenger: FlutterBinaryMessenger, deliveryDriverApi: GoogleMapsDeliveryDriver,
       ridesharingDriverApi: GoogleMapsRidesharingDriver) {
    _deliveryDriverApi = deliveryDriverApi
    _ridesharingDriverApi = ridesharingDriverApi
    CommonDriverApiSetup.setUp(binaryMessenger: messenger, api: self)
  }

  private func getApi(type: DriverApiTypeDto) throws -> GoogleMapsBaseDriver {
    switch type {
    case .delivery:
      return _deliveryDriverApi
    case .ridesharing:
      return _ridesharingDriverApi
    }
  }

  func initialize(type: DriverApiTypeDto, providerId: String, vehicleId: String,
                  abnormalTerminationReportingEnabled: Bool) throws {
    if try _deliveryDriverApi.isInitialized() {
      throw GoogleMapsDriverError.apiAlreadyInitialized
    }
    if try _ridesharingDriverApi.isInitialized() {
      throw GoogleMapsDriverError.apiAlreadyInitialized
    }
    try getApi(type: type).initialize(
      providerId: providerId,
      vehicleId: vehicleId,
      abnormalTerminationReportingEnabled: abnormalTerminationReportingEnabled
    )
  }

  func isInitialized(type: DriverApiTypeDto) throws -> Bool {
    try getApi(type: type).isInitialized()
  }

  func getProviderId(type: DriverApiTypeDto) throws -> String {
    try getApi(type: type).getProviderId()
  }

  func getVehicleId(type: DriverApiTypeDto) throws -> String {
    try getApi(type: type).getVehicleId()
  }

  func isLocationTrackingEnabled(type: DriverApiTypeDto) throws -> Bool {
    try getApi(type: type).isLocationTrackingEnabled()
  }

  func setLocationTrackingEnabled(type: DriverApiTypeDto, enabled: Bool) throws {
    try getApi(type: type).setLocationTrackingEnabled(enabled: enabled)
  }

  func getLocationReportingIntervalMillis(type: DriverApiTypeDto) throws -> Int64 {
    try getApi(type: type).getLocationReportingIntervalMillis()
  }

  func setLocationReportingIntervalMillis(type: DriverApiTypeDto, milliseconds: Int64) throws {
    try getApi(type: type).setLocationReportingIntervalMillis(
      milliseconds: milliseconds
    )
  }

  func dispose(type: DriverApiTypeDto) throws {
    try getApi(type: type).dispose()
  }

  func getDriverSdkVersion(type: DriverApiTypeDto) throws -> String {
    try getApi(type: type).getDriverSdkVersion()
  }

  func setSupplementalLocation(type: DriverApiTypeDto, location: LocationDto) throws {
    throw GoogleMapsDriverError.notSupported
  }
}
