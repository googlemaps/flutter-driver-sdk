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

// This file describes the models used to interact with the sample LMFS backend,
// used by the example app. These models are not something that is part of the
// Google Maps Flutter SDK, and are not ment to be used in production.
// Documentation to for these models can be found under following links:
// https://github.com/googlemaps/last-mile-fleet-solution-samples/tree/main/backend#delivery-configuration-file

import 'package:google_driver_flutter/google_driver_flutter.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

import 'shared_types.dart';

/// Enum representing types of LMFS tokens.
enum LMFSTokenType {
  /// Delivery driver token
  deliveryDriver,

  /// Delivery consumer token
  deliveryConsumer,

  /// Fleet reader token
  fleetReader,
}

/// Helper class to convert LMFSTokenType to/from JSON.
extension LMFSTokenTypeJsonConversion on LMFSTokenType {
  /// Converts a LMFSTokenType instance to string for JSON serialization.
  String toJsonString() {
    switch (this) {
      case LMFSTokenType.deliveryDriver:
        return 'delivery_driver';
      case LMFSTokenType.deliveryConsumer:
        return 'delivery_consumer';
      case LMFSTokenType.fleetReader:
        return 'fleet_reader';
    }
  }
}

/// Delivery configuration model for the example backend initialization.
class LMFSDeliveryConfig {
  /// Constructs a [LMFSDeliveryConfig] instance.
  LMFSDeliveryConfig({this.description, required this.manifests});

  /// Creates a [LMFSDeliveryConfig] instance from a JSON object.
  factory LMFSDeliveryConfig.fromJson(Map<String, dynamic> json) {
    return LMFSDeliveryConfig(
      description: json['description'] as String,
      manifests:
          (json['manifests'] as List<Map<String, dynamic>>)
              .map((Map<String, dynamic> e) => LMFSManifest.fromJson(e))
              .toList(),
    );
  }

  /// An optional description of the config.
  final String? description;

  /// A list of manifests.
  final List<LMFSManifest> manifests;

  /// Converts a [LMFSDeliveryConfig] instance to a JSON object.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'description': description ?? '',
      'manifests': manifests.map((LMFSManifest e) => e.toJson()).toList(),
    };
  }
}

/// Converts VehicleStopState enum to String for API request.
extension VehicleStopStateJsonConversion on VehicleStopState {
  /// Converts VehicleStopState enum to String for JSON serialization.
  String toJsonString() {
    switch (this) {
      case VehicleStopState.stateUnspecified:
        return 'STATE_UNSPECIFIED';
      case VehicleStopState.newStop:
        return 'NEW';
      case VehicleStopState.enroute:
        return 'ENROUTE';
      case VehicleStopState.arrived:
        return 'ARRIVED';
    }
  }

  /// Constructs a VehicleStopState instance from a String.
  static VehicleStopState fromJsonString(String type) {
    switch (type) {
      case 'STATE_UNSPECIFIED':
        return VehicleStopState.stateUnspecified;
      case 'NEW':
        return VehicleStopState.newStop;
      case 'ENROUTE':
        return VehicleStopState.enroute;
      case 'ARRIVED':
        return VehicleStopState.arrived;
      default:
        return VehicleStopState.stateUnspecified;
    }
  }
}

/// The set of stops and tasks assigned to a single delivery vehicle.
class LMFSManifest {
  /// Constructs a [LMFSManifest] instance.
  LMFSManifest({
    required this.vehicle,
    this.clientId,
    this.currentStopState,
    this.remainingStopIdList,
    required this.tasks,
    required this.stops,
  });

  /// Vehicle definition.
  final LMFSVehicle vehicle;

  /// The client ID to which the manifest and the vehicle are currently
  /// assigned if it has been assigned to a client.
  final String? clientId;

  /// The current state of the vehicle as it travels to the next stop.
  ///
  /// Setting this field to 'ENROUTE' or 'ARRIVED' specifies that the vehicle is en-route or has
  /// arrived at the first stop in remaining_stop_ids, respectively.
  ///
  /// This field on an initial [LMFSDeliveryConfig] will be ignored.
  VehicleStopState? currentStopState;

  /// The list of IDs of stops that the vehicle has not yet, but will travel
  /// through, in order.
  ///
  /// Each entry in [remainingStopIdList] must be found in a [stops] list.
  /// When a vehicle finishes serving one stop, update this field to remove the
  /// finished stop to begin serving the next stop.
  /// To rearrange the order of the remaining stops, rearrange this list of IDs.
  /// Setting this field on an initial load (as part of the JSON file) will be
  /// ignored. The initial sequence of stops is the sequence order given in the
  /// stops field.
  List<String>? remainingStopIdList;

  /// A list of tasks for the vehicle to complete, not necessarily in this order.
  final List<LMFSTask> tasks;

  /// A list of stops for the vehicle to travel through.
  final List<LMFSStop> stops;

  /// Converts a Manifest instance to a Map`<String, dynamic>` for JSON serialization.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'vehicle': vehicle.toJson(),
      'tasks': tasks.map((LMFSTask t) => t.toJson()).toList(),
      'stops': stops.map((LMFSStop s) => s.toJson()).toList(),
    };

    if (clientId != null) {
      json['client_id'] = clientId;
    }
    if (currentStopState != null) {
      json['current_stop_state'] = currentStopState!.toJsonString();
    }
    if (remainingStopIdList != null) {
      json['remaining_stop_id_list'] = remainingStopIdList;
    }

    return json;
  }

  /// Constructs a Manifest instance from a Map`<String, dynamic>`.
  static LMFSManifest fromJson(Map<String, dynamic> json) {
    return LMFSManifest(
      vehicle: LMFSVehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
      clientId: json['client_id'] as String?,
      currentStopState:
          json['current_stop_state'] != null
              ? VehicleStopStateJsonConversion.fromJsonString(
                json['current_stop_state'] as String,
              )
              : null,
      remainingStopIdList: List<String>.from(
        json['remaining_stop_id_list'] as List<dynamic>,
      ),
      tasks: List<LMFSTask>.from(
        (json['tasks'] as List<dynamic>).map(
          (dynamic t) => LMFSTask.fromJson(t as Map<String, dynamic>),
        ),
      ),
      stops: List<LMFSStop>.from(
        (json['stops'] as List<dynamic>).map(
          (dynamic s) => LMFSStop.fromJson(s as Map<String, dynamic>),
        ),
      ),
    );
  }
}

/// Object used to update the manifest for a given vehicle ID.
class LMFSManifestUpdate {
  /// Constructs a [LMFSManifestUpdate] instance.
  LMFSManifestUpdate({this.currentStopState, this.remainingStopIdList});

  /// The current state of the vehicle as it travels to the next stop.
  ///
  /// Setting this field to 'ENROUTE' or 'ARRIVED' specifies that the vehicle is en-route or has
  /// arrived at the first stop in remaining_stop_ids, respectively.
  ///
  /// This field on an initial [LMFSDeliveryConfig] will be ignored.
  VehicleStopState? currentStopState;

  /// The list of IDs of stops that the vehicle has not yet, but will travel
  /// through, in order.
  ///
  /// Each entry in [remainingStopIdList] must be found in a [stops] list.
  /// When a vehicle finishes serving one stop, update this field to remove the
  /// finished stop to begin serving the next stop.
  /// To rearrange the order of the remaining stops, rearrange this list of IDs.
  /// Setting this field on an initial load (as part of the JSON file) will be
  /// ignored. The initial sequence of stops is the sequence order given in the
  /// stops field.
  List<String>? remainingStopIdList;

  /// Converts a Manifest instance to a Map`<String, dynamic>` for JSON serialization.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    if (currentStopState != null) {
      json['current_stop_state'] = currentStopState!.toJsonString();
    }
    if (remainingStopIdList != null) {
      json['remaining_stop_id_list'] = remainingStopIdList;
    }

    return json;
  }
}

/// LMFSVehicle definition.
class LMFSVehicle extends Vehicle {
  /// Constructs a [LMFSVehicle] instance.
  LMFSVehicle({
    required this.vehicleId,
    required this.providerId,
    this.startLocation,
  });

  /// The ID of the vehicle.
  @override
  final String vehicleId;

  /// The provider ID of the customer, which is the GCP project ID.
  final String providerId;

  /// Where the vehicle is located initially for simulation.
  final LMFSWaypoint? startLocation;

  /// Converts a Vehicle instance to a Map`<String, dynamic>` for JSON serialization.
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'vehicle_id': vehicleId,
      'provider_id': providerId,
    };
    if (startLocation != null) {
      json['start_location'] = startLocation?.toJson();
    }
    return json;
  }

  /// Constructs a Vehicle instance from a Map`<String, dynamic>`.
  static LMFSVehicle fromJson(Map<String, dynamic> json) {
    return LMFSVehicle(
      vehicleId: json['vehicle_id'] as String,
      providerId: json['provider_id'] as String,
      startLocation:
          json['start_location'] != null
              ? LMFSWaypoint.fromJson(
                json['start_location'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

/// Stop definition within a manifest.
class LMFSStop {
  /// Constructs a [LMFSStop] instance.
  LMFSStop({
    required this.stopId,
    required this.plannedWaypoint,
    required this.taskIds,
  });

  /// An ID used to uniquely identify the stop.
  final String stopId;

  /// One stop for the vehicle.
  final LMFSWaypoint plannedWaypoint;

  /// Multiple nearby tasks may be done at this stop.
  final List<String> taskIds;

  /// Converts a Stop instance to a Map`<String, dynamic>` for JSON serialization.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stop_id': stopId,
      'planned_waypoint': plannedWaypoint.toJson(),
      'tasks': taskIds,
    };
  }

  /// Constructs a Stop instance from a Map`<String, dynamic>`.
  static LMFSStop fromJson(Map<String, dynamic> json) {
    return LMFSStop(
      stopId: json['stop_id'] as String,
      plannedWaypoint: LMFSWaypoint.fromJson(
        json['planned_waypoint'] as Map<String, dynamic>,
      ),
      taskIds: List<String>.from(json['tasks'] as List<dynamic>),
    );
  }
}

/// Enum representing the type of the task.
enum LMFSTaskType {
  /// Picup task type.
  pickup,

  /// Delivery task type.
  delivery,

  /// Scheduled stop task type.
  scheduledStop,

  /// Unavailable task type.
  unavailableTask,
}

/// Converts LMFSTaskType enum to String for API request.
extension LMFSTaskTypeJsonConversion on LMFSTaskType {
  /// Converts LMFSTaskType enum to String for JSON serialization.
  String toJsonString() {
    switch (this) {
      case LMFSTaskType.pickup:
        return 'PICKUP';
      case LMFSTaskType.delivery:
        return 'DELIVERY';
      case LMFSTaskType.scheduledStop:
        return 'SCHEDULED_STOP';
      case LMFSTaskType.unavailableTask:
        return 'UNAVAILABLE_TASK';
    }
  }

  /// Constructs a LMFSTaskType instance from a String.
  static LMFSTaskType fromJsonString(String type) {
    switch (type) {
      case 'PICKUP':
        return LMFSTaskType.pickup;
      case 'DELIVERY':
        return LMFSTaskType.delivery;
      case 'SCHEDULED_STOP':
        return LMFSTaskType.scheduledStop;
      case 'UNAVAILABLE_TASK':
        return LMFSTaskType.unavailableTask;
      default:
        return LMFSTaskType.unavailableTask;
    }
  }
}

/// Task definition for a vehicle manifest.
class LMFSTask {
  /// Constructs a [LMFSTask] instance.
  LMFSTask({
    required this.taskId,
    required this.trackingId,
    required this.plannedWaypoint,
    this.contactName,
    this.plannedCompletionTime,
    this.plannedCompletionTimeRangeSeconds,
    required this.durationSeconds,
    required this.taskType,
    this.description,
  });

  /// The ID of the task. This ID must be unique across all tasks defined in the
  /// same file.
  final String taskId;

  /// The consumer-facing, public tracking ID of the task.
  ///
  /// The combination of this task's tracking ID and its [taskType] must be
  /// unique across all tasks defined in the same file.
  final String trackingId;

  /// The intended destination of the task.
  final LMFSWaypoint plannedWaypoint;

  /// The name of the contact person for this task (typically the addressee for
  /// a delivery, or the sender for a pickup).
  ///
  /// This may not be populated for all tasks.
  final String? contactName;

  /// The intended completion time of the task.
  ///
  /// If specified, it must be an ISO 8601 date,
  /// e.g. 2021-05-01T15:00:00.000-07:00. The sample backend may consider the
  /// task definition file to be invalid otherwise.
  final String? plannedCompletionTime;

  /// The time window when completion could occur, in seconds.
  ///
  /// Optional, and only used if [plannedCompletionTime] is specified above.
  /// For example, given the time in planned_completion_time above, a value of
  /// 7200 would mean that completion could take place between 15:00 and 17:00.
  final int? plannedCompletionTimeRangeSeconds;

  /// Estimated time for accomplishing the task.
  final int durationSeconds;

  /// The type of the task.
  ///
  /// Documantation: https://developers.google.com/maps/documentation/transportation-logistics/last-mile-fleet-solution/shipment-tracking/fleet-engine/deliveries_api#use_cases.
  final LMFSTaskType? taskType;

  /// A description of the task.
  final String? description;

  /// Converts a Task instance to a Map`<String, dynamic>` for JSON serialization.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'task_id': taskId,
      'tracking_id': trackingId,
      'planned_waypoint': plannedWaypoint.toJson(),
      'duration_seconds': durationSeconds,
    };

    // Add nullable fields to JSON only if they are not null
    if (contactName != null) {
      json['contact_name'] = contactName;
    }
    if (taskType != null) {
      json['task_type'] = taskType!.toJsonString();
    }
    if (plannedCompletionTime != null) {
      json['planned_completion_time'] = plannedCompletionTime;
    }
    if (plannedCompletionTimeRangeSeconds != null) {
      json['planned_completion_time_range_seconds'] =
          plannedCompletionTimeRangeSeconds;
    }
    if (description != null) {
      json['description'] = description;
    }

    return json;
  }

  /// Constructs a Task instance from a Map`<String, dynamic>`.
  static LMFSTask fromJson(Map<String, dynamic> json) {
    return LMFSTask(
      taskId: json['task_id'] as String,
      trackingId: json['tracking_id'] as String,
      plannedWaypoint: LMFSWaypoint.fromJson(
        json['planned_waypoint'] as Map<String, dynamic>,
      ),
      contactName: json['contact_name'] as String?,
      plannedCompletionTime: json['planned_completion_time'] as String?,
      plannedCompletionTimeRangeSeconds:
          json['planned_completion_time_range_seconds'] as int?,
      durationSeconds: json['duration_seconds'] as int,
      taskType:
          json['taskType'] != null
              ? LMFSTaskTypeJsonConversion.fromJsonString(
                json['taskType'] as String,
              )
              : null,
      description: json['description'] as String?,
    );
  }
}

/// A point on the map
class LMFSWaypoint {
  /// Constructs a [LMFSWaypoint] instance.
  LMFSWaypoint({required this.description, required this.target});

  /// Greates a [LMFSWaypoint] instance from a [NavigationWaypoint].
  factory LMFSWaypoint.fromNavigationWaypoint(NavigationWaypoint waypoint) {
    assert(waypoint.target != null, 'NavigationWaypoint target is null.');
    return LMFSWaypoint(description: waypoint.title, target: waypoint.target!);
  }

  /// Constructs a Waypoint instance from a Map`<String, dynamic>`.
  factory LMFSWaypoint.fromJson(Map<String, dynamic> json) {
    return LMFSWaypoint(
      description: json['description'] as String?,
      target: LatLng(
        latitude: json['lat'] as double,
        longitude: json['lng'] as double,
      ),
    );
  }

  /// Converts [LMFSWaypoint] to [NavigationWaypoint].
  NavigationWaypoint toNavigationWaypoint() {
    return NavigationWaypoint.withLatLngTarget(
      title: description ?? '',
      target: target,
    );
  }

  /// A description of the waypoint.
  final String? description;

  /// The point on the map.
  final LatLng target;

  /// Converts a Waypoint instance to a Map`<String, dynamic>` for JSON serialization.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'description': description,
      'lat': target.latitude,
      'lng': target.longitude,
    };
  }
}
