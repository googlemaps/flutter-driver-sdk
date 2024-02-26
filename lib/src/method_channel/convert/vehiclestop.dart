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

import '../../types/types.dart';
import '../method_channel.dart';

/// [VehicleStopState] convert extension.
/// @nodoc
extension ConvertVehicleStopState on VehicleStopState {
  /// Converts [VehicleStopState] to [VehicleStopStateDto]
  VehicleStopStateDto toDto() {
    switch (this) {
      case VehicleStopState.stateUnspecified:
        return VehicleStopStateDto.stateUnspecified;
      case VehicleStopState.newStop:
        return VehicleStopStateDto.newStop;
      case VehicleStopState.enroute:
        return VehicleStopStateDto.enroute;
      case VehicleStopState.arrived:
        return VehicleStopStateDto.arrived;
    }
  }
}

/// [VehicleStopStateDto] convert extension.
/// @nodoc
extension ConvertVehicleStopDtoState on VehicleStopStateDto {
  /// Converts [VehicleStopStateDto] to [VehicleStopState]
  VehicleStopState toVehicleStopState() {
    switch (this) {
      case VehicleStopStateDto.stateUnspecified:
        return VehicleStopState.stateUnspecified;
      case VehicleStopStateDto.newStop:
        return VehicleStopState.newStop;
      case VehicleStopStateDto.enroute:
        return VehicleStopState.enroute;
      case VehicleStopStateDto.arrived:
        return VehicleStopState.arrived;
    }
  }
}

/// [TaskInfo] convert extension.
/// @nodoc
extension ConvertTaskInfo on TaskInfo {
  /// Converts Google Driver [TaskInfo] to Pigeon [TaskInfoDto].
  TaskInfoDto toDto() {
    return TaskInfoDto(taskId: taskId, durationSeconds: durationSeconds);
  }
}

/// [TaskInfoDto] convert extension.
/// @nodoc
extension ConvertTaskInfoDto on TaskInfoDto {
  /// Converts Pigeon [TaskInfoDto] to Google Driver [TaskInfo].
  TaskInfo toTaskInfo() {
    return TaskInfo(taskId: taskId, durationSeconds: durationSeconds);
  }
}

/// [VehicleStop] convert extension.
/// @nodoc
extension ConvertVehicleStop on VehicleStop {
  /// Converts Google Driver [VehicleStop] to Pigeon [VehicleStopDto].
  VehicleStopDto toDto() {
    return VehicleStopDto(
        vehicleStopState: vehicleStopState.toDto(),
        waypoint: waypoint?.toDto(),
        taskInfoList:
            taskInfoList.map((TaskInfo task) => task.toDto()).toList());
  }
}

/// [VehicleStopDto] convert extension.
/// @nodoc
extension ConvertVehicleStopDto on VehicleStopDto {
  /// Converts Pigeon [VehicleStopDto] to Google Driver [VehicleStop].
  VehicleStop toVehicleStop() {
    return VehicleStop(
        vehicleStopState: vehicleStopState.toVehicleStopState(),
        waypoint: waypoint?.toNavigationWaypoint(),
        taskInfoList: taskInfoList.nonNulls
            .map((TaskInfoDto task) => task.toTaskInfo())
            .toList());
  }
}
