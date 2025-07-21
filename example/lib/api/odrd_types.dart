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

// This file describes the models used to interact with the sample ODRD backend,
// used by the example app. These models are not something that is part of the
// Google Maps Flutter SDK, and are not ment to be used in production.
// Documentation to for these models can be found under following links:
// https://github.com/googlemaps/java-on-demand-rides-deliveries-stub-provider?tab=readme-ov-file#endpoints

import 'package:google_navigation_flutter/google_navigation_flutter.dart';

import 'shared_types.dart';

/// Enum representing types of ODRD tokens.
enum ODRDTokenType {
  /// Driver token
  driver,

  /// Consumer token
  consumer,
}

/// Helper class to convert ODRDTokenType to/from JSON.
extension ODRDTokenTypeJsonConversion on ODRDTokenType {
  /// Converts a ODRDTokenType instance to string for JSON serialization.
  String toJsonString() {
    switch (this) {
      case ODRDTokenType.driver:
        return 'driver';
      case ODRDTokenType.consumer:
        return 'consumer';
    }
  }
}

/// Represents a vehicle state for the the On-demand Rides and Deliveries Solution.
enum ODRDVehicleState {
  /// Vehicle offline.
  offline,

  /// Vehicle online.
  online,
}

/// Helper class to convert [ODRDVehicleState] to/from JSON.
extension ODRDVehicleStateJsonConversion on ODRDVehicleState {
  /// Converts a [ODRDVehicleState] instance to string for JSON serialization.
  String toJsonString() {
    switch (this) {
      case ODRDVehicleState.offline:
        return 'OFFLINE';
      case ODRDVehicleState.online:
        return 'ONLINE';
    }
  }

  /// Constructs a [ODRDVehicleState] instance from a String.
  static ODRDVehicleState fromJsonString(String type) {
    switch (type) {
      case 'OFFLINE':
        return ODRDVehicleState.offline;
      case 'ONLINE':
        return ODRDVehicleState.online;
      default:
        throw ArgumentError('Unsupported ODRDVehicleState: $type');
    }
  }
}

/// Represents a vehicle object for the On-demand Rides and Deliveries Solution.
class ODRDVehicle extends Vehicle {
  /// Constructs a [ODRDVehicle] instance.
  ODRDVehicle({
    required this.vehicleId,
    this.vehicleState,
    this.name,
    this.currentTripsIds,
    this.waypoints,
    this.supportedTripTypes,
    this.backToBackEnabled,
    this.maximumCapacity,
    this.lastLocation,
  });

  /// Constructs a [ODRDVehicle] instance from a Map`<String, dynamic>`.
  factory ODRDVehicle.fromJson(Map<String, dynamic> json) {
    final String vehicleId = (json['name'] as String).split('/').last;
    return ODRDVehicle(
      vehicleId: vehicleId,
      vehicleState: ODRDVehicleStateJsonConversion.fromJsonString(
        json['vehicleState'] as String,
      ),
      name: json['name'] as String?,
      currentTripsIds:
          (json['currentTripsIds'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList(),
      waypoints:
          (json['waypoints'] as List<dynamic>?)
              ?.map(
                (dynamic e) => ODRDWaypoint.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      supportedTripTypes:
          (json['supportedTripTypes'] as List<dynamic>?)
              ?.map(
                (dynamic e) =>
                    ODRDTripTypesJsonConversion.fromJsonString(e as String),
              )
              .toList(),
      backToBackEnabled: json['backToBackEnabled'] as bool?,
      maximumCapacity: json['maximumCapacity'] as int?,
      lastLocation:
          json['lastLocation'] == null
              ? null
              : LatLngJsonConversion.fromJson(
                (json['lastLocation'] as Map<String, dynamic>)['point']
                    as Map<String, dynamic>,
              ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{'vehicleId': vehicleId};
    if (vehicleState != null) {
      json['vehicleState'] = vehicleState!.toJsonString();
    }
    if (supportedTripTypes != null) {
      json['supportedTripTypes'] =
          supportedTripTypes!
              .map((ODRDTripType e) => e.toJsonString())
              .toList();
    }
    if (backToBackEnabled != null) {
      json['backToBackEnabled'] = backToBackEnabled;
    }
    if (maximumCapacity != null) {
      json['maximumCapacity'] = maximumCapacity;
    }
    return json;
  }

  /// Vehicle id.
  @override
  final String vehicleId;

  /// Vehicle state.
  final ODRDVehicleState? vehicleState;

  /// Vehicle name.
  final String? name;

  /// Vehicles currentTripsIds.
  final List<String>? currentTripsIds;

  /// Vehicles waypoints.
  final List<ODRDWaypoint>? waypoints;

  /// Vehicles supported trip types.
  final List<ODRDTripType>? supportedTripTypes;

  /// Back-to-back enabled.
  final bool? backToBackEnabled;

  /// Vehicles maximum capacity.
  final int? maximumCapacity;

  /// The last known location of the vehicle.
  final LatLng? lastLocation;
}

/// Helper class to convert LatLng to/from JSON.
extension LatLngJsonConversion on LatLng {
  /// Converts a LatLng instance to a Map`<String, dynamic>` for JSON serialization.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'latitude': latitude, 'longitude': longitude};
  }

  /// Constructs a [LatLng] instance from a Map`<String, dynamic>`.
  static LatLng fromJson(Map<String, dynamic> json) {
    return LatLng(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
    );
  }
}

/// Type of the ODRD waypoint.
enum ODRDWaypointType {
  /// Pickup waypoint type.
  pickup,

  /// Drop off waypoint type.
  dropOff,

  /// Intermediate destination waypoint type.
  intermediateDestination,
}

/// Helper class to convert WaypointType to/from JSON.
extension ODRDWaypointTypeJsonConversion on ODRDWaypointType {
  /// Converts a WaypointType instance to string for JSON serialization.
  String toJsonString() {
    switch (this) {
      case ODRDWaypointType.pickup:
        return 'PICKUP_WAYPOINT_TYPE';
      case ODRDWaypointType.dropOff:
        return 'DROP_OFF_WAYPOINT_TYPE';
      case ODRDWaypointType.intermediateDestination:
        return 'INTERMEDIATE_DESTINATION_WAYPOINT_TYPE';
    }
  }

  /// Constructs a [ODRDWaypointType] instance from a String.
  static ODRDWaypointType fromJsonString(String type) {
    switch (type) {
      case 'PICKUP_WAYPOINT_TYPE':
        return ODRDWaypointType.pickup;
      case 'DROP_OFF_WAYPOINT_TYPE':
        return ODRDWaypointType.dropOff;
      case 'INTERMEDIATE_DESTINATION_WAYPOINT_TYPE':
        return ODRDWaypointType.intermediateDestination;
      default:
        throw ArgumentError('Unsupported WaypointType: $type');
    }
  }
}

/// Represents a trip type for the On-demand Rides and Deliveries Solution.
enum ODRDTripType {
  /// Exclusive
  exclusive,

  /// Shared
  shared,
}

/// Helper class to convert [ODRDTripType] to/from JSON.
extension ODRDTripTypesJsonConversion on ODRDTripType {
  /// Converts a [ODRDTripType] instance to string for JSON serialization.
  String toJsonString() {
    switch (this) {
      case ODRDTripType.exclusive:
        return 'EXCLUSIVE';
      case ODRDTripType.shared:
        return 'SHARED';
    }
  }

  /// Constructs a [ODRDTripType] instance from a String.
  static ODRDTripType fromJsonString(String type) {
    switch (type) {
      case 'EXCLUSIVE':
        return ODRDTripType.exclusive;
      case 'SHARED':
        return ODRDTripType.shared;
      default:
        throw ArgumentError('Unsupported ODRDTripTypes: $type');
    }
  }
}

/// Represents a trip status for the On-demand Rides and Deliveries Solution.
enum ODRDTripStatus {
  /// Unknown trip status.
  unknownTripStatus,

  /// New trip status.
  newTrip,

  /// Enroute to pickup trip status.
  enrouteToPickup,

  /// Arrived at pickup trip status.
  arrivedAtPickup,

  /// Arrived at intermediate destination trip status.
  arrivedAtIntermediateDestination,

  /// Enroute to intermediate destination trip status.
  enrouteToIntermediateDestination,

  /// Enroute to dropoff trip status.
  enrouteToDropoff,

  /// Complete trip status.
  complete,

  /// Canceled trip status.
  canceled,
}

/// Helper class to convert ODRDTripStatus to/from JSON.
extension ODRDTripStatusJsonConversion on ODRDTripStatus {
  /// Converts a ODRDTripStatus instance to string for JSON serialization.
  String toJsonString() {
    switch (this) {
      case ODRDTripStatus.unknownTripStatus:
        return 'UNKNOWN_TRIP_STATUS';
      case ODRDTripStatus.newTrip:
        return 'NEW';
      case ODRDTripStatus.enrouteToPickup:
        return 'ENROUTE_TO_PICKUP';
      case ODRDTripStatus.arrivedAtPickup:
        return 'ARRIVED_AT_PICKUP';
      case ODRDTripStatus.arrivedAtIntermediateDestination:
        return 'ARRIVED_AT_INTERMEDIATE_DESTINATION';
      case ODRDTripStatus.enrouteToIntermediateDestination:
        return 'ENROUTE_TO_INTERMEDIATE_DESTINATION';
      case ODRDTripStatus.enrouteToDropoff:
        return 'ENROUTE_TO_DROPOFF';
      case ODRDTripStatus.complete:
        return 'COMPLETE';
      case ODRDTripStatus.canceled:
        return 'CANCELED';
    }
  }

  /// Constructs a [ODRDTripStatus] instance from a String.
  static ODRDTripStatus fromJsonString(String type) {
    switch (type) {
      case 'UNKNOWN_TRIP_STATUS':
        return ODRDTripStatus.unknownTripStatus;
      case 'NEW':
        return ODRDTripStatus.newTrip;
      case 'ENROUTE_TO_PICKUP':
        return ODRDTripStatus.enrouteToPickup;
      case 'ARRIVED_AT_PICKUP':
        return ODRDTripStatus.arrivedAtPickup;
      case 'ARRIVED_AT_INTERMEDIATE_DESTINATION':
        return ODRDTripStatus.arrivedAtIntermediateDestination;
      case 'ENROUTE_TO_INTERMEDIATE_DESTINATION':
        return ODRDTripStatus.enrouteToIntermediateDestination;
      case 'ENROUTE_TO_DROPOFF':
        return ODRDTripStatus.enrouteToDropoff;
      case 'COMPLETE':
        return ODRDTripStatus.complete;
      case 'CANCELED':
        return ODRDTripStatus.canceled;
      default:
        throw ArgumentError('Unsupported ODRDTripStatus: $type');
    }
  }
}

/// Represents a waypoint for the On-demand Rides and Deliveries Solution.
class ODRDWaypoint {
  /// Constructs a [ODRDWaypoint] instance.
  ODRDWaypoint({
    required this.location,
    required this.waypointType,
    this.heading = 0,
    this.tripId,
  });

  /// Constructs a [ODRDWaypoint] instance from a Map`<String, dynamic>`.
  factory ODRDWaypoint.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> location =
        json['location'] as Map<String, dynamic>;
    return ODRDWaypoint(
      location: LatLngJsonConversion.fromJson(
        location['point'] as Map<String, dynamic>,
      ),
      heading: location['heading'] as int? ?? 0,
      waypointType: ODRDWaypointTypeJsonConversion.fromJsonString(
        json['waypointType'] as String,
      ),
      tripId: json['tripId'] as String?,
    );
  }

  /// Converts a ODRDWaypoint instance to a Map`<String, dynamic>` for
  /// JSON serialization.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'location': <String, dynamic>{
        'point': location.toJson(),
        'heading': heading,
      },
      'waypointType': waypointType.toJsonString(),
      'tripId': tripId,
    };
  }

  /// Waypoint location.
  final LatLng location;

  /// Waypoint type.
  final ODRDWaypointType waypointType;

  /// Trip id.
  final String? tripId;

  /// Waypoint heading.
  final int heading;
}

/// Represents a trip object used for trip update for the
/// On-demand Rides and Deliveries Solution (ODRD).
class ODRDTripUpdate {
  /// Constructs an [ODRDTripUpdate] instance with the given details.
  ODRDTripUpdate({required this.tripStatus, this.intermediateDestinationIndex})
    : assert(
        intermediateDestinationIndex == null ||
            tripStatus == ODRDTripStatus.enrouteToIntermediateDestination,
        'intermediateDestinationIndex can be used only with enrouteToIntermediateDestination status.',
      );

  /// The next status of the trip.
  final ODRDTripStatus tripStatus;

  /// The next intermediateDestinationIndex.
  ///
  /// Can be used only with [tripStatus]
  /// [ODRDTripStatus.enrouteToIntermediateDestination]
  final int? intermediateDestinationIndex;

  /// Converts the [ODRDTripUpdate] instance into a JSON map suitable for
  /// JSON serialization.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'status': tripStatus.toJsonString(),
    };

    if (intermediateDestinationIndex != null) {
      json['intermediateDestinationIndex'] = intermediateDestinationIndex;
    }

    return json;
  }
}

/// Represents a trip object used for trip creation for the
/// On-demand Rides and Deliveries Solution (ODRD).
class ODRDCreateTrip {
  /// Constructs an [ODRDCreateTrip] instance with the given details.
  ODRDCreateTrip({
    required this.triptype,
    required this.pickup,
    required this.dropoff,
    this.intermediateDestinations,
  });

  /// Trip type.
  final ODRDTripType triptype;

  /// Pickup location.
  final LatLng pickup;

  /// Dropoff location.
  final LatLng dropoff;

  /// Intermediate destinations.
  final List<LatLng>? intermediateDestinations;

  /// Converts the [ODRDCreateTrip] instance into a JSON map suitable for
  /// JSON serialization.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'tripType': triptype.toJsonString(),
      'pickup': pickup.toJson(),
      'dropoff': dropoff.toJson(),
    };

    if (intermediateDestinations != null) {
      json['intermediateDestinations'] =
          intermediateDestinations!.map((LatLng l) => l.toJson()).toList();
    }

    return json;
  }
}

/// Represents a trip for the On-demand Rides and Deliveries Solution (ODRD).
class ODRDTrip {
  /// Constructs an [ODRDTrip] instance with the given details.
  ODRDTrip({
    required this.tripId,
    required this.name,
    required this.vehicleId,
    required this.tripStatus,
    required this.waypoints,
  });

  /// Creates an instance of [ODRDTrip] from a JSON map.
  ///
  /// [json]: The JSON map representing the trip's data.
  factory ODRDTrip.fromJson(Map<String, dynamic> json) {
    return ODRDTrip(
      tripId: (json['name'] as String).split('/').last,
      name: json['name'] as String,
      vehicleId: json['vehicleId'] as String,
      tripStatus: ODRDTripStatusJsonConversion.fromJsonString(
        json['tripStatus'] as String,
      ),
      waypoints:
          (json['waypoints'] as List<dynamic>)
              .map(
                (dynamic e) => ODRDWaypoint.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  /// Converts the [ODRDTrip] instance into a JSON map suitable for
  /// JSON serialization.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'vehicleId': vehicleId,
      'tripStatus': tripStatus.toJsonString(),
      'waypoints': waypoints.map((ODRDWaypoint w) => w.toJson()).toList(),
    };
  }

  /// The unique identifier of the trip, typically in a format like
  final String tripId;

  /// The unique identifier of the trip, typically in a format like
  /// "providers/providerId/trips/tripId".
  final String name;

  /// The vehicle ID associated with this trip.
  final String vehicleId;

  /// The current status of the trip.
  final ODRDTripStatus tripStatus;

  /// A list of waypoints associated with this trip.
  final List<ODRDWaypoint> waypoints;
}
