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

import '../../types/types.dart';
import '../method_channel.dart';

/// [DriverStatusLevel] convert extension.
/// @nodoc
extension ConvertDriverStatusLevelDto on DriverStatusLevelDto {
  /// Converts [DriverStatusLevelDto] to [DriverStatusLevel]
  DriverStatusLevel toStatusLevel() {
    switch (this) {
      case DriverStatusLevelDto.debug:
        return DriverStatusLevel.debug;
      case DriverStatusLevelDto.info:
        return DriverStatusLevel.info;
      case DriverStatusLevelDto.warning:
        return DriverStatusLevel.warning;
      case DriverStatusLevelDto.error:
        return DriverStatusLevel.error;
    }
  }
}

/// [DriverStatusCode] convert extension.
/// @nodoc
extension ConvertDriverStatusCodeDto on DriverStatusCodeDto {
  /// Converts [DriverStatusCodeDto] to [DriverStatusCode]
  DriverStatusCode toStatusCode() {
    switch (this) {
      case DriverStatusCodeDto.defaultStatus:
        return DriverStatusCode.defaultStatus;
      case DriverStatusCodeDto.unknownError:
        return DriverStatusCode.unknownError;
      case DriverStatusCodeDto.serviceError:
        return DriverStatusCode.serviceError;
      case DriverStatusCodeDto.fileAccessError:
        return DriverStatusCode.fileAccessError;
      case DriverStatusCodeDto.vehicleNotFound:
        return DriverStatusCode.vehicleNotFound;
      case DriverStatusCodeDto.backendConnectivityError:
        return DriverStatusCode.backendConnectivityError;
      case DriverStatusCodeDto.permissionDenied:
        return DriverStatusCode.permissionDenied;
      case DriverStatusCodeDto.traveledRouteError:
        return DriverStatusCode.traveledRouteError;
    }
  }
}
