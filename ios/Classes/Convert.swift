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

import Foundation
import GoogleMaps
import GoogleNavigation
import GoogleRidesharingDriver

enum Convert {
  // This conversion functions has been duplicated from
  // google_navigation_flutter. Keep in sync.
  static func convertLatLngFromDto(point: LatLngDto) -> CLLocationCoordinate2D {
    CLLocationCoordinate2D(
      latitude: point.latitude,
      longitude: point.longitude
    )
  }

  // This conversion functions has been duplicated from
  // google_navigation_flutter. Keep in sync.
  static func convertLatLngToDto(point: CLLocationCoordinate2D) -> LatLngDto {
    LatLngDto(latitude: point.latitude, longitude: point.longitude)
  }

  // This conversion functions has been duplicated from
  // google_navigation_flutter. Keep in sync.
  static func convertNavigationWayPointToDto(_ gmsNavigationWaypoint: GMSNavigationWaypoint?)
    -> NavigationWaypointDto? {
    guard let gmsNavigationWaypoint else { return nil }
    return NavigationWaypointDto(
      title: gmsNavigationWaypoint.title,
      target: .init(
        latitude: gmsNavigationWaypoint.coordinate.latitude,
        longitude: gmsNavigationWaypoint.coordinate.longitude
      ),
      placeID: gmsNavigationWaypoint.placeID,
      preferSameSideOfRoad: gmsNavigationWaypoint.preferSameSideOfRoad,
      preferredSegmentHeading: Int64(gmsNavigationWaypoint.preferredHeading)
    )
  }

  // This conversion functions has been duplicated from
  // google_navigation_flutter. Keep in sync.
  static func convertNavigationWayPointFromDto(_ waypoint: NavigationWaypointDto?)
    -> GMSNavigationWaypoint? {
    guard let waypoint else { return nil }
    if let latitude = waypoint.target?.latitude, let longitude = waypoint.target?.longitude {
      if let preferSameSideOfRoad = waypoint.preferSameSideOfRoad {
        return GMSNavigationWaypoint(
          location: .init(latitude: latitude, longitude: longitude),
          title: waypoint.title,
          preferSameSideOfRoad: preferSameSideOfRoad
        )
      } else if let preferredSegmentHeading = waypoint.preferredSegmentHeading {
        return GMSNavigationWaypoint(
          location: .init(latitude: latitude, longitude: longitude),
          title: waypoint.title,
          // TODO: Handle the 32bit x 64bit conversion correctly.
          preferredSegmentHeading: Int32(preferredSegmentHeading)
        )
      }
      return GMSNavigationWaypoint(
        location: CLLocationCoordinate2D(
          latitude: latitude,
          longitude: longitude
        ),
        title: waypoint.title
      )
    }
    if let placeID = waypoint.placeID {
      return GMSNavigationWaypoint(
        placeID: placeID,
        title: waypoint.title
      )
    }
    return nil
  }

  // This conversion functions has been duplicated from
  // google_navigation_flutter. Keep in sync.
  static func convertWaypoints(_ waypoints: [NavigationWaypointDto?])
    -> [GMSNavigationWaypoint] {
    waypoints
      .map { waypoint -> GMSNavigationWaypoint? in
        guard let waypoint else { return nil }
        return convertNavigationWayPointFromDto(waypoint)
      }
      .compactMap { $0 }
  }

  // Converts Pigeon [TaskInfoDto] to Google Driver [GMTSTaskInfo].
  static func convertTaskInfoFromDto(task: TaskInfoDto) -> GMTSTaskInfo {
    GMTSTaskInfo(taskID: task.taskId, taskDuration: TimeInterval(task.durationSeconds))
  }

  // Converts Google Driver [GMTSTaskInfo] to Pigeon [TaskInfoDto].
  static func convertTaskInfoToDto(task: GMTSTaskInfo) -> TaskInfoDto {
    TaskInfoDto(taskId: task.taskID, durationSeconds: Int64(task.taskDuration))
  }

  // Converts pigeon [VehicleStopStateDto] to Google Drive [Int].
  static func convertVehicleStopStateFromDto(vehicleStopState: VehicleStopStateDto)
    -> GMTDVehicleStopState {
    switch vehicleStopState {
    case VehicleStopStateDto.stateUnspecified:
      return .unspecified
    case VehicleStopStateDto.newStop:
      return .new
    case VehicleStopStateDto.enroute:
      return .enroute
    case VehicleStopStateDto.arrived:
      return .arrived
    }
  }

  // Converts Google Drive [Int] to pigeon [VehicleStopStateDto].
  static func convertVehicleStopStateToDto(googleVehicleStopState: GMTDVehicleStopState)
    -> VehicleStopStateDto {
    switch googleVehicleStopState {
    case .unspecified:
      return VehicleStopStateDto.stateUnspecified
    case .new:
      return VehicleStopStateDto.newStop
    case .enroute:
      return VehicleStopStateDto.enroute
    case .arrived:
      return VehicleStopStateDto.arrived
    @unknown default:
      return VehicleStopStateDto.stateUnspecified
    }
  }

  // Convert GMTDVehicleStop into VehicleStopDto
  static func convertVehicleStopToDto(stop: GMTDVehicleStop) -> VehicleStopDto {
    VehicleStopDto(
      vehicleStopState: convertVehicleStopStateToDto(googleVehicleStopState: stop.state),
      waypoint: convertNavigationWayPointToDto(stop.plannedWaypoint),
      taskInfoList: stop.taskInfoArray.map { taskInfo -> TaskInfoDto? in
        convertTaskInfoToDto(task: taskInfo)
      }
    )
  }

  // Converts Google Driver [GMTDVehicleStop] to Pigeon [VehicleStopDto].
  static func convertVehicleStopFromDto(stop: VehicleStopDto) -> GMTDVehicleStop {
    GMTDVehicleStop(taskInfoArray: stop.taskInfoList.map { taskInfo -> GMTSTaskInfo? in
      guard let taskInfo else { return nil }

      return convertTaskInfoFromDto(task: taskInfo)
    }.compactMap { $0 }, plannedWaypoint: convertNavigationWayPointFromDto(stop.waypoint),
    state: convertVehicleStopStateFromDto(
      vehicleStopState: stop.vehicleStopState
    ))
  }

  // Converts Pigeon [VehicleStateDto] to Google Driver [GMTDVehicleState].
  static func convertVehicleStateFromDto(state: VehicleStateDto)
    -> GMTDVehicleState {
    switch state {
    case .offline:
      return GMTDVehicleState.offline
    case .online:
      return GMTDVehicleState.online
    }
  }

  // Converts Google Driver [GMTDVehicleState] to Pigeon [VehicleStateDto].
  static func convertVehicleStateToDto(state: GMTDVehicleState)
    -> VehicleStateDto {
    switch state {
    case .offline:
      return VehicleStateDto.offline
    case .online:
      return VehicleStateDto.online
    @unknown default:
      // Should not happen.
      return VehicleStateDto.offline
    }
  }

  static func convertVehicleUpdateToDto(vehicleUpdate: GMTDVehicleUpdate,
                                        ridesharing: Bool) -> VehicleUpdateDto {
    VehicleUpdateDto(
      vehicleState: ridesharing ?
        convertVehicleStateToDto(state: vehicleUpdate.vehicleState)
        : nil,
      location: vehicleUpdate
        .location != nil ? convertLatLngToDto(point: vehicleUpdate.location!.coordinate) : nil,
      destinationWaypoint: convertNavigationWayPointToDto(vehicleUpdate.destinationWaypoint),
      route: (vehicleUpdate.route ?? []).map { convertLatLngToDto(point: $0.coordinate)
      },
      remainingTimeInSeconds: vehicleUpdate.remainingTimeInSeconds?.doubleValue,
      remainingDistanceInMeters: vehicleUpdate.remainingDistanceInMeters?.doubleValue
    )
  }

  static func convertGRPCErrorCodes(errorCode: Int) -> String {
    let errorCodes = [
      0: "OK",
      1: "CANCELLED",
      2: "UNKNOWN",
      3: "INVALID_ARGUMENT",
      4: "DEADLINE_EXCEEDED",
      5: "NOT_FOUND",
      6: "ALREADY_EXISTS",
      7: "PERMISSION_DENIED",
      8: "RESOURCE_EXHAUSTED",
      9: "FAILED_PRECONDITION",
      10: "ABORTED",
      11: "OUT_OF_RANGE",
      12: "UNIMPLEMENTED",
      14: "UNAVAILABLE",
      15: "DATA_LOSS",
      16: "UNAUTHENTICATED",
    ]
    return errorCodes[errorCode] ?? "UNKNOWN"
  }

  static func convertDeliveryVehicleToDto(deliveryVehicle: GMTDDeliveryVehicle)
    -> DeliveryVehicleDto {
    DeliveryVehicleDto(
      providerId: deliveryVehicle.providerID,
      id: deliveryVehicle.vehicleID,
      name: deliveryVehicle.vehicleName,
      stops: deliveryVehicle.vehicleStops?.map { stop in
        convertVehicleStopToDto(stop: stop)
      } ?? []
    )
  }
}
