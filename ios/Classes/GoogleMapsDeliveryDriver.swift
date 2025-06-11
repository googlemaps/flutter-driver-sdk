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
import google_navigation_flutter

// Keep in sync with GoogleMapsNavigationSessionManager.kt
enum GoogleMapsDeliveryDriverError: Error {
  case driverNotInitialized
  case driverInitializationFailed
  case driverException
  case noRoadSnappedLocationProvider
}

func convertError(_ error: Error) -> FlutterError {
  let fullError = error as NSError

  let errorCode = Convert.convertGRPCErrorCodes(errorCode: fullError.code)
  return FlutterError(
    code: "driverException",
    message: fullError.localizedDescription,
    details: errorCode
  )
}

class GoogleMapsDeliveryDriver: GoogleMapsBaseDriver, DeliveryDriverApi {
  private var _deliveryDriverAPI: GMTDDeliveryDriverAPI? = nil
  private var _vehicleReporterListener: VehicleReporterListener? = nil

  override init(messenger: FlutterBinaryMessenger) {
    super.init(messenger: messenger)
    DeliveryDriverApiSetup.setUp(binaryMessenger: messenger, api: self)

    _vehicleReporterListener = VehicleReporterListener()
    _vehicleReporterListener?.setup(messenger: messenger, ridesharing: false)
  }

  override func getCommonVehicleReporter() throws -> GMTDVehicleReporter {
    if _deliveryDriverAPI != nil {
      return _deliveryDriverAPI!.vehicleReporter
    } else {
      throw GoogleMapsRidesharingDriverError.driverNotInitialized
    }
  }

  override func initialize(
    providerId: String, vehicleId: String,
    abnormalTerminationReportingEnabled: Bool
  ) throws {
    let navigator = try ExposedGoogleMapsNavigator.getNavigator()
    GMSNavigationServices.createNavigationSession()

    _driverContext = GMTDDriverContext(
      accessTokenProvider: _accessTokenProvider,
      providerID: providerId,
      vehicleID: vehicleId,
      navigator: navigator
    )

    if _driverContext != nil {
      _deliveryDriverAPI = GMTDDeliveryDriverAPI(driverContext: _driverContext!)

      // Should not fail since the ExposedGoogleMapsNavigator.getNavigator() few
      // lines above should have thrown sessionNotInitialized already.
      if let _roadSnappedLocationProvider =
        try ExposedGoogleMapsNavigator
        .getRoadSnappedLocationProvider()
      {
        if let vehicleReporter = _deliveryDriverAPI?.vehicleReporter {
          _roadSnappedLocationProvider.add(vehicleReporter)
        } else {
          // Should not happen.
          throw GoogleMapsDeliveryDriverError.driverInitializationFailed
        }
      } else {
        // Should not happen.
        throw GoogleMapsDeliveryDriverError.noRoadSnappedLocationProvider
      }

      _deliveryDriverAPI?.vehicleReporter.add(_vehicleReporterListener!)

      GMTDDeliveryDriverAPI
        .setAbnormalTerminationReportingEnabled(abnormalTerminationReportingEnabled)
    }
  }

  override func isInitialized() throws -> Bool {
    _deliveryDriverAPI != nil
  }

  override func dispose() throws {
    _deliveryDriverAPI = nil
    _driverContext = nil
    if let vehicleReporter = _deliveryDriverAPI?.vehicleReporter {
      _roadSnappedLocationProvider?.remove(vehicleReporter)
    }
    _roadSnappedLocationProvider = nil
  }

  func enrouteToNextStop(completion: @escaping (Result<[VehicleStopDto], Error>) -> Void) {
    if _deliveryDriverAPI != nil {
      _deliveryDriverAPI?.vehicleReporter.reportEnrouteToNextStop(completion: { stops, error in
        if error == nil {
          completion(
            .success(
              (stops ?? []).map { stop -> VehicleStopDto in
                Convert.convertVehicleStopToDto(stop: stop)
              }
            ))
        } else {
          completion(.failure(convertError(error!)))
        }
      })
    } else {
      completion(.failure(GoogleMapsDeliveryDriverError.driverNotInitialized))
    }
  }

  func arrivedAtStop(completion: @escaping (Result<[VehicleStopDto], Error>) -> Void) {
    if _deliveryDriverAPI != nil {
      _deliveryDriverAPI?.vehicleReporter.reportArrivedAtStop(completion: { stops, error in
        if error == nil {
          completion(
            .success(
              (stops ?? []).map { stop -> VehicleStopDto in
                Convert.convertVehicleStopToDto(stop: stop)
              }
            ))
        } else {
          completion(.failure(convertError(error!)))
        }
      })
    } else {
      completion(.failure(GoogleMapsDeliveryDriverError.driverNotInitialized))
    }
  }

  func completedStop(completion: @escaping (Result<[VehicleStopDto], Error>) -> Void) {
    if _deliveryDriverAPI != nil {
      _deliveryDriverAPI?.vehicleReporter.reportCompletedStop(completion: { stops, error in
        if error == nil {
          completion(
            .success(
              (stops ?? []).map { stop -> VehicleStopDto in
                Convert.convertVehicleStopToDto(stop: stop)
              }
            ))
        } else {
          completion(.failure(convertError(error!)))
        }
      })
    } else {
      completion(.failure(GoogleMapsDeliveryDriverError.driverNotInitialized))
    }
  }

  func getRemainingVehicleStops(completion: @escaping (Result<[VehicleStopDto], Error>) -> Void) {
    if _deliveryDriverAPI != nil {
      _deliveryDriverAPI?.vehicleReporter.getRemainingVehicleStops(completion: { stops, error in
        if error == nil {
          completion(
            .success(
              (stops ?? []).map { stop -> VehicleStopDto in
                Convert.convertVehicleStopToDto(stop: stop)
              }
            ))
        } else {
          completion(.failure(convertError(error!)))
        }
      })
    } else {
      completion(.failure(GoogleMapsDeliveryDriverError.driverNotInitialized))
    }
  }

  func setVehicleStops(
    stops: [VehicleStopDto],
    completion: @escaping (Result<[VehicleStopDto], Error>) -> Void
  ) {
    if _deliveryDriverAPI != nil {
      let vehicleStops: [GMTDVehicleStop] = stops.map { stop -> GMTDVehicleStop in
        Convert.convertVehicleStopFromDto(stop: stop)
      }

      _deliveryDriverAPI?.vehicleReporter.setVehicleStops(
        vehicleStops,
        completion: { stops, error in
          if error == nil {
            completion(
              .success(
                (stops ?? [])
                  .map { stop -> VehicleStopDto in
                    Convert
                      .convertVehicleStopToDto(
                        stop: stop
                      )
                  }
              ))
          } else {
            completion(
              .failure(convertError(error!))
            )
          }
        })

    } else {
      completion(.failure(GoogleMapsDeliveryDriverError.driverNotInitialized))
    }
  }

  func getDeliveryVehicle(completion: @escaping (Result<DeliveryVehicleDto, Error>) -> Void) {
    if _deliveryDriverAPI != nil {
      _deliveryDriverAPI!.deliveryVehicleManager!
        .getVehicleWithCompletion { deliveryVehicle, error in
          if error == nil {
            completion(
              .success(
                Convert
                  .convertDeliveryVehicleToDto(deliveryVehicle: deliveryVehicle!)))
          } else {
            completion(.failure(convertError(error!)))
          }
        }
    } else {
      completion(.failure(GoogleMapsDeliveryDriverError.driverNotInitialized))
    }
  }
}
