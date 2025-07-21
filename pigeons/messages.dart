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

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    input: 's/messages.dart',
    swiftOut: 'ios/Classes/messages.g.swift',
    kotlinOut:
        'android/src/main/kotlin/com/google/maps/flutter/driver/messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.google.maps.flutter.driver'),
    dartOut: 'lib/src/method_channel/messages.g.dart',
    dartTestOut: 'test/messages_test.g.dart',
    copyrightHeader: 'pigeons/copyright.txt',
  ),
)
/// Indicates the API type for a driver.
enum DriverApiTypeDto {
  /// Indicates the API is for a delivery driver.
  delivery,

  /// Indicates the API is for a ridesharing driver.
  ridesharing,
}

class TaskInfoDto {
  TaskInfoDto({required this.taskId, required this.durationSeconds});

  final String taskId;
  final int durationSeconds;
}

enum VehicleStopStateDto { stateUnspecified, newStop, enroute, arrived }

class VehicleStopDto {
  VehicleStopDto({
    required this.vehicleStopState,
    this.waypoint,
    required this.taskInfoList,
  });

  final VehicleStopStateDto vehicleStopState;
  final NavigationWaypointDto? waypoint;
  final List<TaskInfoDto?> taskInfoList;
}

class LatLngDto {
  const LatLngDto({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class NavigationWaypointDto {
  NavigationWaypointDto({
    required this.title,
    this.target,
    this.placeID,
    this.preferSameSideOfRoad,
    this.preferredSegmentHeading,
  });

  final String title;
  final LatLngDto? target;
  final String? placeID;
  final bool? preferSameSideOfRoad;
  final int? preferredSegmentHeading;
}

enum VehicleStateDto {
  /// Indicates the vehicle is not accepting new trips.
  offline,

  /// Indicates the vehicle is accepting new trips.
  online,
}

class LocationDto {
  LocationDto({
    this.accuracy,
    this.altitude,
    this.elapsedRealtimeNanos,
    this.bearing,
    this.isMock,
    this.latitude,
    this.longitude,
    this.provider,
    this.speed,
    this.time,
  });
  final double? accuracy;
  final double? altitude;
  final int? elapsedRealtimeNanos;
  final double? bearing;
  final bool? isMock;
  final double? latitude;
  final double? longitude;
  final String? provider;
  final double? speed;
  final int? time;
}

class DeliveryVehicleDto {
  DeliveryVehicleDto({
    required this.providerId,
    required this.id,
    required this.name,
    required this.stops,
  });
  final String providerId;
  final String id;
  final String name;
  final List<VehicleStopDto?> stops;
}

@HostApi(dartHostTestHandler: 'TestCommonDriverApi')
abstract class CommonDriverApi {
  void initialize(
    DriverApiTypeDto type,
    String providerId,
    String vehicleId,
    bool abnormalTerminationReportingEnabled,
  );
  bool isInitialized(DriverApiTypeDto type);
  String getProviderId(DriverApiTypeDto type);
  String getVehicleId(DriverApiTypeDto type);
  bool isLocationTrackingEnabled(DriverApiTypeDto type);
  void setLocationTrackingEnabled(DriverApiTypeDto type, bool enabled);
  int getLocationReportingIntervalMillis(DriverApiTypeDto type);
  void setLocationReportingIntervalMillis(
    DriverApiTypeDto type,
    int milliseconds,
  );
  void dispose(DriverApiTypeDto type);
  String getDriverSdkVersion(DriverApiTypeDto type);
  void setSupplementalLocation(DriverApiTypeDto type, LocationDto location);
}

@HostApi(dartHostTestHandler: 'TestDeliveryDriverApi')
abstract class DeliveryDriverApi {
  @async
  List<VehicleStopDto> arrivedAtStop();
  @async
  List<VehicleStopDto> completedStop();
  @async
  List<VehicleStopDto> enrouteToNextStop();
  @async
  List<VehicleStopDto> getRemainingVehicleStops();
  @async
  List<VehicleStopDto> setVehicleStops(List<VehicleStopDto> stops);
  @async
  DeliveryVehicleDto getDeliveryVehicle();
}

@HostApi(dartHostTestHandler: 'TestRidesharingDriverApi')
abstract class RidesharingDriverApi {
  void setVehicleState(VehicleStateDto state);
}

@FlutterApi()
abstract class AuthTokenEventApi {
  @async
  String getToken(String? taskId, String? vehicleId);
}

class VehicleUpdateDto {
  VehicleUpdateDto({
    required this.vehicleState,
    this.location,
    this.destinationWaypoint,
    this.route,
    this.remainingTimeInSeconds,
    this.remainingDistanceInMeters,
  });

  final VehicleStateDto? vehicleState;
  final LatLngDto? location;
  final NavigationWaypointDto? destinationWaypoint;
  final List<LatLngDto?>? route;
  final double? remainingTimeInSeconds;
  final double? remainingDistanceInMeters;
}

@FlutterApi()
abstract class VehicleReporterListenerApi {
  void onDidSucceed(VehicleUpdateDto vehicleUpdate);
  void onDidFail(
    VehicleUpdateDto vehicleUpdate,
    String errorCode,
    String errorMessage,
  );
}

enum DriverStatusLevelDto { debug, info, warning, error }

enum DriverStatusCodeDto {
  defaultStatus,
  unknownError,
  vehicleNotFound,
  backendConnectivityError,
  permissionDenied,
  serviceError,
  fileAccessError,
  traveledRouteError,
}

@FlutterApi()
abstract class DriverStatusListenerApi {
  void onStatusUpdate(
    DriverStatusLevelDto level,
    DriverStatusCodeDto code,
    String message,
    String? errorCode,
    String? errorMessage,
  );
}
