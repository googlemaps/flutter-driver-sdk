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

import 'package:google_navigation_flutter/google_navigation_flutter.dart';

/// Describes a task that the delivery driver will perform.
///
/// {@category Delivery Driver}
class TaskInfo {
  /// Constructs a [TaskInfo] instance.
  TaskInfo({
    required this.taskId,
    required this.durationSeconds,
  });

  /// Returns the unique identifier of the task.
  final String taskId;

  /// Returns the time required to perform the task.
  final int durationSeconds;
}

/// Enum representing the current state of the delivery vehicle as it travels to
/// the next stop.
///
/// {@category Delivery Driver}
enum VehicleStopState {
  /// The current state of the vehicle is unspecified.
  stateUnspecified,

  /// The vehicle is at a new stop.
  newStop,

  /// The vehicle is en-route to the next stop.
  enroute,

  /// The vehicle has arrived at the next stop.
  arrived,
}

/// Describes a stop that the delivery vehicle will be visiting.
///
/// {@category Delivery Driver}
class VehicleStop {
  /// Constructs a [VehicleStop] instance.
  VehicleStop({
    required this.vehicleStopState,
    required this.waypoint,
    required this.taskInfoList,
  });

  /// Returns the state of the VehicleStop.
  final VehicleStopState vehicleStopState;

  /// Returns the waypoint of the vehicle stop.
  final NavigationWaypoint? waypoint;

  /// Returns the list of TaskInfo objects associated with the vehicle stop.
  final List<TaskInfo> taskInfoList;
}
