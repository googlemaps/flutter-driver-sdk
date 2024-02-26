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

import 'package:flutter/foundation.dart';

/// Token response model.
@immutable
class TokenResponse {
  /// Constructs a [TokenResponse] instance.
  ///
  /// [creationTimestampMs] - The Unix timestamp at which the token was created (in milliseconds).
  /// [expirationTimestampMs] - The Unix timestamp at which time the token will expire (in milliseconds).
  /// [token] - The token in base-64 encoded format.
  const TokenResponse(
      {required this.creationTimestampMs,
      required this.expirationTimestampMs,
      required this.token});

  /// Factory constructor for LMFS API JSON response
  factory TokenResponse.fromLMFSJson(Map<String, dynamic> json) {
    return TokenResponse(
      creationTimestampMs: json['creation_timestamp_ms'] as int,
      expirationTimestampMs: json['expiration_timestamp_ms'] as int,
      token: json['token'] as String,
    );
  }

  /// Factory constructor for ODRD API JSON response
  factory TokenResponse.fromODRDJson(Map<String, dynamic> json) {
    // Assuming ODRD API JSON structure, modify as per actual structure
    return TokenResponse(
      creationTimestampMs: json['creationTimestamp'] as int,
      expirationTimestampMs: json['expirationTimestamp'] as int,
      token: json['jwt'] as String,
    );
  }

  /// The Unix timestamp at which the token was created (in milliseconds).
  final int creationTimestampMs;

  /// The Unix timestamp at which time the token will expire (in milliseconds).
  final int expirationTimestampMs;

  /// The token in base-64 encoded format.
  final String token;
}

/// Base class for vehicle definitions between APIs.
abstract class Vehicle {
  /// The ID of the vehicle.
  String get vehicleId;

  /// Converts a Vehicle instance to a Map<String, dynamic> for JSON serialization.
  Map<String, dynamic> toJson();
}
