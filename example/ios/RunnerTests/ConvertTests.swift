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
import GoogleNavigation
import GoogleRidesharingDriver
import UIKit
import XCTest

@testable import google_driver_flutter

class ConvertTests: XCTestCase {
  func testConvertLatLngFromDto() {
    let latLngPoint = LatLngDto(latitude: 44.0, longitude: 55.0)
    let coordinate = Convert.convertLatLngFromDto(point: latLngPoint)

    XCTAssertEqual(latLngPoint.latitude, coordinate.latitude)
    XCTAssertEqual(latLngPoint.longitude, coordinate.longitude)
  }

  func tstConvertLatLngToDto() {
    let latLngPoint = CLLocationCoordinate2D(latitude: 44.0, longitude: 55.0)
    let coordinate = Convert.convertLatLngToDto(point: latLngPoint)

    XCTAssertEqual(latLngPoint.latitude, coordinate.latitude)
    XCTAssertEqual(latLngPoint.longitude, coordinate.longitude)
  }

  func testConvertWaypointToDto() {
    var testWaypoint = GMSNavigationWaypoint(placeID: "id", title: "title")!
    var waypoint = Convert.convertNavigationWayPointToDto(testWaypoint)!
    XCTAssertEqual(waypoint.title, testWaypoint.title)
    XCTAssertEqual(waypoint.placeID, testWaypoint.placeID)
    XCTAssertEqual(waypoint.preferredSegmentHeading, -1)
    XCTAssertEqual(testWaypoint.preferredHeading, -1)

    testWaypoint = GMSNavigationWaypoint(
      location: CLLocationCoordinate2D(latitude: 64.555, longitude: 65.555),
      title: "title"
    )!
    waypoint = Convert.convertNavigationWayPointToDto(testWaypoint)!
    XCTAssertEqual(waypoint.title, testWaypoint.title)
    XCTAssertEqual(waypoint.target?.latitude, testWaypoint.coordinate.latitude)
    XCTAssertEqual(waypoint.target?.longitude, testWaypoint.coordinate.longitude)
    XCTAssertNil(waypoint.placeID)
    XCTAssertNil(testWaypoint.placeID)
    XCTAssertEqual(waypoint.preferredSegmentHeading, -1)
    XCTAssertEqual(testWaypoint.preferredHeading, -1)

    testWaypoint = GMSNavigationWaypoint(
      location: CLLocationCoordinate2D(latitude: 64.555, longitude: 65.555),
      title: "title",
      preferredSegmentHeading: 40
    )!
    waypoint = Convert.convertNavigationWayPointToDto(testWaypoint)!
    XCTAssertEqual(waypoint.title, testWaypoint.title)
    XCTAssertEqual(waypoint.target?.latitude, testWaypoint.coordinate.latitude)
    XCTAssertEqual(waypoint.target?.longitude, testWaypoint.coordinate.longitude)
    XCTAssertNil(waypoint.placeID)
    XCTAssertNil(testWaypoint.placeID)
    XCTAssertEqual(waypoint.preferredSegmentHeading, 40)
    XCTAssertEqual(testWaypoint.preferredHeading, 40)

    testWaypoint = GMSNavigationWaypoint(
      location: CLLocationCoordinate2D(latitude: 64.555, longitude: 65.555),
      title: "title",
      preferSameSideOfRoad: true
    )!
    waypoint = Convert.convertNavigationWayPointToDto(testWaypoint)!
    XCTAssertEqual(waypoint.title, testWaypoint.title)
    XCTAssertEqual(waypoint.target?.latitude, testWaypoint.coordinate.latitude)
    XCTAssertEqual(waypoint.target?.longitude, testWaypoint.coordinate.longitude)
    XCTAssertNil(waypoint.placeID)
    XCTAssertNil(testWaypoint.placeID)
    XCTAssertEqual(waypoint.preferredSegmentHeading, -1)
    XCTAssertEqual(testWaypoint.preferredHeading, -1)
    XCTAssertTrue(waypoint.preferSameSideOfRoad!)
    XCTAssertTrue(testWaypoint.preferSameSideOfRoad)
  }

  func testConvertWaypointFromDto() {
    var testWaypoint = NavigationWaypointDto(title: "title", placeID: "id")
    var waypoint = Convert.convertNavigationWayPointFromDto(testWaypoint)!
    XCTAssertEqual(waypoint.title, testWaypoint.title)
    XCTAssertEqual(waypoint.placeID, testWaypoint.placeID)
    XCTAssertEqual(waypoint.preferredHeading, -1)
    XCTAssertEqual(testWaypoint.preferredSegmentHeading, nil)

    testWaypoint = NavigationWaypointDto(
      title: "title", target: LatLngDto(latitude: 64.555, longitude: 65.555)
    )
    waypoint = Convert.convertNavigationWayPointFromDto(testWaypoint)!
    XCTAssertEqual(waypoint.title, testWaypoint.title)
    XCTAssertEqual(waypoint.coordinate.latitude, testWaypoint.target!.latitude)
    XCTAssertEqual(waypoint.coordinate.longitude, testWaypoint.target!.longitude)
    XCTAssertNil(waypoint.placeID)
    XCTAssertNil(testWaypoint.placeID)
    XCTAssertEqual(waypoint.preferredHeading, -1)
    XCTAssertEqual(testWaypoint.preferredSegmentHeading, nil)

    testWaypoint = NavigationWaypointDto(
      title: "title", target: LatLngDto(latitude: 64.555, longitude: 65.555),
      preferredSegmentHeading: 40
    )
    waypoint = Convert.convertNavigationWayPointFromDto(testWaypoint)!
    XCTAssertEqual(waypoint.title, testWaypoint.title)
    XCTAssertEqual(waypoint.coordinate.latitude, testWaypoint.target!.latitude)
    XCTAssertEqual(waypoint.coordinate.longitude, testWaypoint.target!.longitude)
    XCTAssertNil(waypoint.placeID)
    XCTAssertNil(testWaypoint.placeID)
    XCTAssertEqual(waypoint.preferredHeading, 40)
    XCTAssertEqual(testWaypoint.preferredSegmentHeading, 40)

    testWaypoint = NavigationWaypointDto(
      title: "title", target: LatLngDto(latitude: 64.555, longitude: 65.555),
      preferSameSideOfRoad: true
    )
    waypoint = Convert.convertNavigationWayPointFromDto(testWaypoint)!
    XCTAssertEqual(waypoint.title, testWaypoint.title)
    XCTAssertEqual(waypoint.coordinate.latitude, testWaypoint.target!.latitude)
    XCTAssertEqual(waypoint.coordinate.longitude, testWaypoint.target!.longitude)
    XCTAssertNil(waypoint.placeID)
    XCTAssertNil(testWaypoint.placeID)
    XCTAssertEqual(waypoint.preferredHeading, -1)
    XCTAssertEqual(testWaypoint.preferredSegmentHeading, nil)
    XCTAssertTrue(waypoint.preferSameSideOfRoad)
    XCTAssertTrue(testWaypoint.preferSameSideOfRoad!)
  }

  func testConvertWaypoints() {
    var testWaypoints: [NavigationWaypointDto] = []
    XCTAssertTrue(Convert.convertWaypoints(testWaypoints).isEmpty)

    testWaypoints = [
      .init(
        title: "test",
        target: .init(
          latitude: 55.0,
          longitude: 44.0
        )
      ),
    ]

    XCTAssertEqual(Convert.convertWaypoints(testWaypoints).count, 1)
    XCTAssertEqual(Convert.convertWaypoints(testWaypoints)[0].title, "test")
    XCTAssertEqual(Convert.convertWaypoints(testWaypoints)[0].coordinate.latitude, 55.0)
    XCTAssertEqual(Convert.convertWaypoints(testWaypoints)[0].coordinate.longitude, 44.0)

    testWaypoints = [
      .init(
        title: "test",
        placeID: "id"
      ),
    ]

    XCTAssertEqual(Convert.convertWaypoints(testWaypoints).count, 1)
    XCTAssertEqual(Convert.convertWaypoints(testWaypoints)[0].title, "test")
    XCTAssertEqual(Convert.convertWaypoints(testWaypoints)[0].placeID, "id")
    XCTAssertEqual(Convert.convertWaypoints(testWaypoints)[0].coordinate.latitude, -180)
    XCTAssertEqual(Convert.convertWaypoints(testWaypoints)[0].coordinate.longitude, -180)
  }

  func testConvretTaskInfoFromDto() {
    let testTaskInfo = TaskInfoDto(taskId: "taskId", durationSeconds: 100)
    let taskInfo = Convert.convertTaskInfoFromDto(task: testTaskInfo)

    XCTAssertEqual(taskInfo.taskID, testTaskInfo.taskId)
    XCTAssertEqual(Int64(taskInfo.taskDuration), testTaskInfo.durationSeconds)
  }

  func testConvertTaskInfoToDto() {
    let testTaskInfo = GMTSTaskInfo(taskID: "taskId", taskDuration: 100)
    let taskInfo = Convert.convertTaskInfoToDto(task: testTaskInfo)

    XCTAssertEqual(taskInfo.taskId, testTaskInfo.taskID)
    XCTAssertEqual(taskInfo.durationSeconds, Int64(testTaskInfo.taskDuration))
  }

  func testConvertVehicleStopStateFromDto() {
    XCTAssertEqual(
      Convert.convertVehicleStopStateFromDto(vehicleStopState: .stateUnspecified),
      .unspecified
    )
    XCTAssertEqual(Convert.convertVehicleStopStateFromDto(vehicleStopState: .newStop), .new)
    XCTAssertEqual(Convert.convertVehicleStopStateFromDto(vehicleStopState: .enroute), .enroute)
    XCTAssertEqual(Convert.convertVehicleStopStateFromDto(vehicleStopState: .arrived), .arrived)
  }

  func testConvertVehicleStopStateToDto() {
    XCTAssertEqual(
      Convert.convertVehicleStopStateToDto(googleVehicleStopState: .unspecified),
      .stateUnspecified
    )
    XCTAssertEqual(Convert.convertVehicleStopStateToDto(googleVehicleStopState: .new), .newStop)
    XCTAssertEqual(Convert.convertVehicleStopStateToDto(googleVehicleStopState: .enroute), .enroute)
    XCTAssertEqual(Convert.convertVehicleStopStateToDto(googleVehicleStopState: .arrived), .arrived)
  }

  func testConvertVehicleStopToDto() {
    let testTaskInfo = GMTSTaskInfo(taskID: "taskId", taskDuration: 100)
    let testWaypoint = GMSNavigationWaypoint(placeID: "id", title: "title")
    let testStop = GMTDVehicleStop(
      taskInfoArray: [testTaskInfo],
      plannedWaypoint: testWaypoint,
      state: .arrived
    )
    let vehicleStop = Convert.convertVehicleStopToDto(stop: testStop)

    XCTAssertEqual(vehicleStop.vehicleStopState, .arrived)
    XCTAssertEqual(vehicleStop.taskInfoList[0]!.durationSeconds, Int64(testTaskInfo.taskDuration))
    XCTAssertEqual(vehicleStop.taskInfoList[0]!.taskId, testTaskInfo.taskID)
    XCTAssertEqual(vehicleStop.waypoint?.title, testWaypoint?.title)
    XCTAssertEqual(vehicleStop.waypoint?.placeID, testWaypoint?.placeID)
  }

  func testConvertVehicleStopFromDto() {
    let testWaypoint = NavigationWaypointDto(title: "title", placeID: "placeId")
    let testTaskInfo = TaskInfoDto(taskId: "taskId", durationSeconds: 100)
    let testVehicleStop = VehicleStopDto(
      vehicleStopState: .enroute,
      waypoint: testWaypoint,
      taskInfoList: [testTaskInfo]
    )
    let vehicleStop = Convert.convertVehicleStopFromDto(stop: testVehicleStop)

    XCTAssertEqual(vehicleStop.state, .enroute)
    XCTAssertEqual(vehicleStop.plannedWaypoint?.title, testWaypoint.title)
    XCTAssertEqual(vehicleStop.plannedWaypoint?.placeID, testWaypoint.placeID)
    XCTAssertEqual(Int64(vehicleStop.taskInfoArray[0].taskDuration), testTaskInfo.durationSeconds)
    XCTAssertEqual(vehicleStop.taskInfoArray[0].taskID, testTaskInfo.taskId)
  }

  func testConvertVehicleStateFromDto() {
    XCTAssertEqual(Convert.convertVehicleStateFromDto(state: .offline), .offline)
    XCTAssertEqual(Convert.convertVehicleStateFromDto(state: .online), .online)
  }

  func testConvertVehicleStateToDto() {
    XCTAssertEqual(Convert.convertVehicleStateToDto(state: .online), .online)
    XCTAssertEqual(Convert.convertVehicleStateToDto(state: .offline), .offline)
  }

  func testConvertGRPCErrorCodes() {
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 0), "OK")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 1), "CANCELLED")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 2), "UNKNOWN")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 3), "INVALID_ARGUMENT")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 4), "DEADLINE_EXCEEDED")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 5), "NOT_FOUND")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 6), "ALREADY_EXISTS")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 7), "PERMISSION_DENIED")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 8), "RESOURCE_EXHAUSTED")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 9), "FAILED_PRECONDITION")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 10), "ABORTED")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 11), "OUT_OF_RANGE")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 12), "UNIMPLEMENTED")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 13), "UNKNOWN")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 14), "UNAVAILABLE")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 15), "DATA_LOSS")
    XCTAssertEqual(Convert.convertGRPCErrorCodes(errorCode: 16), "UNAUTHENTICATED")
  }
}
