/*
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.maps.flutter.driver

import android.location.Location
import android.os.Build
import com.google.android.gms.maps.model.LatLng
import com.google.android.libraries.mapsplatform.transportation.driver.api.base.data.DriverContext
import com.google.android.libraries.mapsplatform.transportation.driver.api.base.data.TaskInfo
import com.google.android.libraries.mapsplatform.transportation.driver.api.base.data.VehicleStop
import com.google.android.libraries.mapsplatform.transportation.driver.api.delivery.data.DeliveryVehicle
import com.google.android.libraries.mapsplatform.transportation.driver.api.ridesharing.vehiclereporter.RidesharingVehicleReporter
import com.google.android.libraries.navigation.Waypoint
import com.google.common.collect.Lists

/** Converters from and to Pigeon generated values. */
object Convert {
  /**
   * Converts Pigeon [LatLngDto] to Google Maps [LatLng].
   *
   * This function has been duplicated from google_navigation_flutter package. Keep in sync.
   *
   * @param point Pigeon [LatLngDto].
   * @return Google Maps [LatLng].
   */
  fun convertLatLngFromDto(point: LatLngDto): LatLng {
    return LatLng(point.latitude, point.longitude)
  }

  /**
   * Converts Google Maps [LatLng] to Pigeon [LatLngDto].
   *
   * This function has been duplicated from google_navigation_flutter package. Keep in sync.
   *
   * @param point Google Maps [LatLng].
   * @return Pigeon [LatLngDto].
   */
  fun convertLatLngToDto(point: LatLng): LatLngDto {
    return LatLngDto(point.latitude, point.longitude)
  }

  /**
   * Converts pigeon [NavigationWaypointDto] to Google Navigation [Waypoint].
   *
   * This function has been duplicated from google_navigation_flutter package. Keep in sync.
   *
   * @param waypoint pigeon [NavigationWaypointDto].
   * @return Google Navigation [Waypoint].
   */
  fun convertWaypointFromDto(waypoint: NavigationWaypointDto): Waypoint {
    val builder = Waypoint.builder()
    if (waypoint.target != null) {
      builder.setLatLng(waypoint.target.latitude, waypoint.target.longitude)
    }
    if (waypoint.preferSameSideOfRoad == true) {
      builder.setPreferSameSideOfRoad(true)
    }
    if (waypoint.preferredSegmentHeading != null) {
      builder.setPreferredHeading(waypoint.preferredSegmentHeading.toInt())
    }
    if (waypoint.placeID != null) {
      builder.setPlaceIdString(waypoint.placeID)
    }
    builder.setTitle(waypoint.title)
    return builder.build()
  }

  /**
   * Converts Google Navigation [Waypoint] to pigeon [NavigationWaypointDto].
   *
   * This function has been duplicated from google_navigation_flutter package. Keep in sync.
   *
   * @param waypoint Google Navigation [Waypoint].
   * @return pigeon [NavigationWaypointDto].
   */
  private fun convertWaypointToDto(waypoint: Waypoint): NavigationWaypointDto {
    return NavigationWaypointDto(
      waypoint.title,
      convertLatLngToDto(waypoint.position),
      waypoint.placeId,
      waypoint.preferSameSideOfRoad,
      waypoint.preferredHeading.takeIf { it != -1 }?.toLong(),
    )
  }

  /**
   * Converts Pigeon [TaskInfoDto] to Google Driver [TaskInfo].
   *
   * @param task Pigeon [TaskInfoDto].
   * @return Google Driver [TaskInfo].
   */
  fun convertTaskInfoFromDto(task: TaskInfoDto): TaskInfo {
    return TaskInfo.builder()
      .setTaskId(task.taskId)
      .setTaskDurationSeconds(task.durationSeconds)
      .build()
  }

  /**
   * Converts Google Driver [TaskInfo] to Pigeon [TaskInfoDto].
   *
   * @param task Google Driver [TaskInfo].
   * @return Pigeon [TaskInfoDto].
   */
  fun convertTaskInfoToDto(task: TaskInfo): TaskInfoDto {
    return TaskInfoDto(task.taskId, task.taskDurationSeconds)
  }

  /**
   * Converts pigeon [VehicleStopStateDto] to Google Drive [Int].
   *
   * @param vehicleStopState pigeon [VehicleStopStateDto].
   * @return VehicleStop.VehicleStopState [Int].
   */
  fun convertVehicleStopStateFromDto(vehicleStopState: VehicleStopStateDto): Int {
    return when (vehicleStopState) {
      VehicleStopStateDto.STATE_UNSPECIFIED -> VehicleStop.VehicleStopState.UNSPECIFIED
      VehicleStopStateDto.NEW_STOP -> VehicleStop.VehicleStopState.NEW
      VehicleStopStateDto.ENROUTE -> VehicleStop.VehicleStopState.ENROUTE
      VehicleStopStateDto.ARRIVED -> VehicleStop.VehicleStopState.ARRIVED
    }
  }

  /**
   * Converts Google Drive [Int] to pigeon [VehicleStopStateDto].
   *
   * @param googleVehicleStopState [Int].
   * @return pigeon [VehicleStopStateDto].
   */
  fun convertVehicleStopStateToDto(googleVehicleStopState: Int): VehicleStopStateDto {
    return when (googleVehicleStopState) {
      VehicleStop.VehicleStopState.UNSPECIFIED -> VehicleStopStateDto.STATE_UNSPECIFIED
      VehicleStop.VehicleStopState.NEW -> VehicleStopStateDto.NEW_STOP
      VehicleStop.VehicleStopState.ENROUTE -> VehicleStopStateDto.ENROUTE
      VehicleStop.VehicleStopState.ARRIVED -> VehicleStopStateDto.ARRIVED
      else -> {
        VehicleStopStateDto.STATE_UNSPECIFIED
      }
    }
  }

  /**
   * Converts Google Driver [VehicleStop] to Pigeon [VehicleStopDto].
   *
   * @param stop Google Driver [VehicleStop].
   * @return Pigeon [VehicleStopDto].
   */
  fun convertVehicleStopToDto(stop: VehicleStop): VehicleStopDto {
    return VehicleStopDto(
      convertVehicleStopStateToDto(stop.vehicleStopState),
      convertWaypointToDto(stop.waypoint),
      Lists.transform<TaskInfo, TaskInfoDto?>(stop.taskInfoList) { task: TaskInfo ->
        convertTaskInfoToDto(task)
      },
    )
  }

  /**
   * Converts Google Driver [VehicleStop] to Pigeon [VehicleStopDto].
   *
   * @param stop Google Driver [VehicleStop].
   * @return Pigeon [VehicleStopDto].
   */
  fun convertVehicleStopFromDto(stop: VehicleStopDto): VehicleStop {
    val builder: VehicleStop.Builder =
      VehicleStop.builder()
        .setVehicleStopState(convertVehicleStopStateFromDto(stop.vehicleStopState))
    if (stop.waypoint != null) {
      builder.setWaypoint(convertWaypointFromDto(stop.waypoint))
    }

    builder.setTaskInfoList(
      Lists.transform<TaskInfoDto, TaskInfo>(stop.taskInfoList.filterNotNull()) { task: TaskInfoDto
        ->
        convertTaskInfoFromDto(task)
      }
    )
    return builder.build()
  }

  /**
   * Converts pigeon [VehicleStateDto] to Google Drive [RidesharingVehicleReporter.VehicleState].
   *
   * @param state pigeon [VehicleStateDto].
   * @return [RidesharingVehicleReporter.VehicleState].
   */
  fun convertVehicleStateFromDto(state: VehicleStateDto): RidesharingVehicleReporter.VehicleState {
    return when (state) {
      VehicleStateDto.OFFLINE -> RidesharingVehicleReporter.VehicleState.OFFLINE
      VehicleStateDto.ONLINE -> RidesharingVehicleReporter.VehicleState.ONLINE
    }
  }

  fun extractErrorCode(t: Throwable): String? {
    val messages = t.message?.split(":", limit = 2)
    return messages?.getOrNull(0)?.trimStart()
  }

  fun extractErrorMessage(t: Throwable): String? {
    val messages = t.message?.split(":", limit = 2)
    return messages?.getOrNull(1)?.trimStart()
  }

  fun convertToDriverException(t: Throwable): FlutterError {
    when (t) {
      is java.util.concurrent.ExecutionException -> {
        return FlutterError(
          "driverException",
          t.message?.replace("java.lang.RuntimeException: Exception: ", "")
            ?: "Token retrieval from the backend failed.",
          "UNAUTHENTICATED",
        )
      }
      else -> {
        return FlutterError(
          "driverException",
          extractErrorMessage(t) ?: "Driver API call failed.",
          extractErrorCode(t) ?: "UNKNOWN",
        )
      }
    }
  }

  /**
   * Converts pigeon [LocationDto] to Android [Location].
   *
   * @param location pigeon [LocationDto].
   * @return [Location].
   */
  fun convertLocationFromDto(location: LocationDto): Location {
    return Location(location.provider).apply {
      if (location.accuracy != null) {
        accuracy = location.accuracy.toFloat()
      }
      if (location.altitude != null) {
        altitude = location.altitude
      }
      if (location.elapsedRealtimeNanos != null) {
        elapsedRealtimeNanos = location.elapsedRealtimeNanos
      }
      if (location.bearing != null) {
        bearing = location.bearing.toFloat()
      }
      if (location.isMock != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        isMock = location.isMock
      }
      if (location.latitude != null) {
        latitude = location.latitude
      }
      if (location.longitude != null) {
        longitude = location.longitude
      }
      if (location.speed != null) {
        speed = location.speed.toFloat()
      }
      if (location.time != null) {
        time = location.time
      }
    }
  }

  /**
   * Converts Android [Location] to pigeon [LocationDto].
   *
   * @param location Android [Location].
   * @return [LocationDto].
   */
  fun convertLocationToDto(location: Location): LocationDto {
    val isMock =
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        location.isMock
      } else {
        null
      }
    return LocationDto(
      provider = location.provider,
      accuracy = location.accuracy.toDouble(),
      altitude = location.altitude,
      elapsedRealtimeNanos = location.elapsedRealtimeNanos,
      bearing = location.bearing.toDouble(),
      latitude = location.latitude,
      longitude = location.longitude,
      isMock = isMock,
      speed = location.speed.toDouble(),
      time = location.time,
    )
  }

  /**
   * Converts Google Driver [DeliveryVehicle] to pigeon [DeliveryVehicleDto].
   *
   * @param deliveryVehicle Google Driver [DeliveryVehicleDto].
   * @return pigeon [DeliveryVehicleDto].
   */
  fun convertDeliveryVehicleToDto(deliveryVehicle: DeliveryVehicle): DeliveryVehicleDto {
    return DeliveryVehicleDto(
      providerId = deliveryVehicle.providerId,
      id = deliveryVehicle.vehicleId,
      name = deliveryVehicle.vehicleName,
      stops = deliveryVehicle.vehicleStops.map { convertVehicleStopToDto(it) },
    )
  }

  /**
   * Converts Google Drive [DriverContext.DriverStatusListener.StatusLevel] to pigeon
   * [DriverStatusLevelDto].
   *
   * @param statusLevel [DriverContext.DriverStatusListener.StatusLevel].
   * @return pigeon [DriverStatusLevelDto].
   */
  fun convertStatusLevelToDto(
    statusLevel: DriverContext.DriverStatusListener.StatusLevel
  ): DriverStatusLevelDto {
    return when (statusLevel) {
      DriverContext.DriverStatusListener.StatusLevel.DEBUG -> DriverStatusLevelDto.DEBUG
      DriverContext.DriverStatusListener.StatusLevel.INFO -> DriverStatusLevelDto.INFO
      DriverContext.DriverStatusListener.StatusLevel.WARNING -> DriverStatusLevelDto.WARNING
      DriverContext.DriverStatusListener.StatusLevel.ERROR -> DriverStatusLevelDto.ERROR
    }
  }

  /**
   * Converts Google Drive [DriverContext.DriverStatusListener.StatusCode] to pigeon
   * [DriverStatusCodeDto].
   *
   * @param statusCode [DriverContext.DriverStatusListener.StatusCode].
   * @return pigeon [DriverStatusCodeDto].
   */
  fun convertStatusCodeToDto(
    statusCode: DriverContext.DriverStatusListener.StatusCode
  ): DriverStatusCodeDto {
    return when (statusCode) {
      DriverContext.DriverStatusListener.StatusCode.DEFAULT -> DriverStatusCodeDto.DEFAULT_STATUS
      DriverContext.DriverStatusListener.StatusCode.UNKNOWN_ERROR ->
        DriverStatusCodeDto.UNKNOWN_ERROR
      DriverContext.DriverStatusListener.StatusCode.VEHICLE_NOT_FOUND ->
        DriverStatusCodeDto.VEHICLE_NOT_FOUND
      DriverContext.DriverStatusListener.StatusCode.BACKEND_CONNECTIVITY_ERROR ->
        DriverStatusCodeDto.BACKEND_CONNECTIVITY_ERROR
      DriverContext.DriverStatusListener.StatusCode.PERMISSION_DENIED ->
        DriverStatusCodeDto.PERMISSION_DENIED
      DriverContext.DriverStatusListener.StatusCode.SERVICE_ERROR ->
        DriverStatusCodeDto.SERVICE_ERROR
      DriverContext.DriverStatusListener.StatusCode.FILE_ACCESS_ERROR ->
        DriverStatusCodeDto.FILE_ACCESS_ERROR
      DriverContext.DriverStatusListener.StatusCode.TRAVELED_ROUTE_ERROR ->
        DriverStatusCodeDto.TRAVELED_ROUTE_ERROR
    }
  }
}
