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
//  AccessTokenProvider.swift
//  google_driver_flutter
//
//  Created by Joonas Kerttula on 15.1.2024.
//

import Flutter
import Foundation
import GoogleRidesharingDriver

class AccessTokenProvider: NSObject, GMTDAuthorization, ObservableObject {
  private var _authTokenEventApi: AuthTokenEventApi

  init(messenger: FlutterBinaryMessenger) {
    _authTokenEventApi = AuthTokenEventApi(binaryMessenger: messenger)
  }

  func fetchToken(
    with authorizationContext: GMTDAuthorizationContext?,
    completion: @escaping GMTDAuthTokenFetchCompletionHandler
  ) {
    _authTokenEventApi.getToken(
      taskId: authorizationContext?.taskID ?? nil,
      vehicleId: authorizationContext?.vehicleID ?? nil
    ) { result in
      switch result {
      case .success(let data):
        completion(data, nil)
      case .failure(let error):
        let nsError = NSError(
          domain: "com.google.mapsplatform.transportation.driver.vehiclereporter.ErrorDomain",
          code: 0,
          userInfo: [
            NSLocalizedDescriptionKey: error
              .message ?? "Token retrieval from the backend failed."
          ]
        )
        completion(nil, nsError)
      }
    }
  }
}
