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
import com.google.android.gms.maps.model.LatLng
import com.google.android.libraries.mapsplatform.transportation.driver.api.base.data.DriverContext
import com.google.android.libraries.mapsplatform.transportation.driver.api.base.data.TaskInfo
import com.google.android.libraries.mapsplatform.transportation.driver.api.base.data.VehicleStop
import com.google.android.libraries.mapsplatform.transportation.driver.api.ridesharing.vehiclereporter.RidesharingVehicleReporter
import java.util.concurrent.ExecutionException
import kotlin.test.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
internal class ConvertTest {
  @Test
  fun convertLatLngFromDto_returnsExpectedValue() {
    val testLatLng = LatLngDto(latitude = 10.0, longitude = 20.0)
    val latLng = Convert.convertLatLngFromDto(testLatLng)

    assertEquals(latLng.latitude, testLatLng.latitude)
    assertEquals(latLng.longitude, testLatLng.longitude)
  }

  @Test
  fun convertLatLngToDto_returnsExpectedValue() {
    val testLatLng = LatLng(10.0, 20.0)
    val latLng = Convert.convertLatLngToDto(testLatLng)

    assertEquals(latLng.latitude, testLatLng.latitude)
    assertEquals(latLng.longitude, testLatLng.longitude)
  }

  @Test
  fun convertTaskInfoFromDto_returnsExpectedValue() {
    val testTaskInfo = TaskInfoDto(taskId = "task_id", durationSeconds = 100)

    val taskInfo = Convert.convertTaskInfoFromDto(testTaskInfo)

    assertEquals(taskInfo.taskId, testTaskInfo.taskId)
    assertEquals(taskInfo.taskDurationSeconds, testTaskInfo.durationSeconds)
  }

  @Test
  fun convertTaskInfoToDto_returnsExpectedValue() {
    val testTaskInfo = TaskInfo.builder().setTaskId("task_id").setTaskDurationSeconds(100).build()

    val taskInfo = Convert.convertTaskInfoToDto(testTaskInfo)

    assertEquals(taskInfo.taskId, testTaskInfo.taskId)
    assertEquals(taskInfo.durationSeconds, testTaskInfo.taskDurationSeconds)
  }

  @Test
  fun convertVehicleStopStateFromDto_returnsExpectedValue() {
    assertEquals(
      VehicleStop.VehicleStopState.UNSPECIFIED,
      Convert.convertVehicleStopStateFromDto(VehicleStopStateDto.STATE_UNSPECIFIED),
    )
    assertEquals(
      VehicleStop.VehicleStopState.NEW,
      Convert.convertVehicleStopStateFromDto(VehicleStopStateDto.NEW_STOP),
    )
    assertEquals(
      VehicleStop.VehicleStopState.ENROUTE,
      Convert.convertVehicleStopStateFromDto(VehicleStopStateDto.ENROUTE),
    )
    assertEquals(
      VehicleStop.VehicleStopState.ARRIVED,
      Convert.convertVehicleStopStateFromDto(VehicleStopStateDto.ARRIVED),
    )
  }

  @Test
  fun convertVehicleStopStateToDto_returnsExpectedValue() {
    assertEquals(
      VehicleStopStateDto.STATE_UNSPECIFIED,
      Convert.convertVehicleStopStateToDto(VehicleStop.VehicleStopState.UNSPECIFIED),
    )
    assertEquals(
      VehicleStopStateDto.NEW_STOP,
      Convert.convertVehicleStopStateToDto(VehicleStop.VehicleStopState.NEW),
    )
    assertEquals(
      VehicleStopStateDto.ENROUTE,
      Convert.convertVehicleStopStateToDto(VehicleStop.VehicleStopState.ENROUTE),
    )
    assertEquals(
      VehicleStopStateDto.ARRIVED,
      Convert.convertVehicleStopStateToDto(VehicleStop.VehicleStopState.ARRIVED),
    )
  }

  @Test
  fun convertRidesharingVehicleStateFromDto_returnsExpectedValue() {
    assertEquals(
      RidesharingVehicleReporter.VehicleState.OFFLINE,
      Convert.convertVehicleStateFromDto(VehicleStateDto.OFFLINE),
    )
    assertEquals(
      RidesharingVehicleReporter.VehicleState.ONLINE,
      Convert.convertVehicleStateFromDto(VehicleStateDto.ONLINE),
    )
  }

  @Test
  fun extractErrorCode_returnsExpectedValue() {
    val throwable = Throwable("error_code: error_message")
    assertEquals("error_code", Convert.extractErrorCode(throwable))
  }

  @Test
  fun extractErrorMessage_returnsExpectedValue() {
    val throwable = Throwable("error_code: error_message")
    assertEquals("error_message", Convert.extractErrorMessage(throwable))
  }

  @Test
  fun convertToDriverException_returnsExpectedValue() {
    val executionException =
      ExecutionException("java.lang.RuntimeException: Exception: ", Throwable("error_code"))
    val otherException = Exception("message")
    var driverException = Convert.convertToDriverException(executionException)
    assertEquals("driverException", driverException.code)
    driverException = Convert.convertToDriverException(otherException)
    assertEquals("driverException", driverException.code)
  }

  @Test
  fun convertLocationFromDto_returnsExpectedValue() {
    val testLocation =
      LocationDto(
        accuracy = 30.0,
        altitude = 60.0,
        elapsedRealtimeNanos = 90L,
        bearing = 50.0,
        isMock = true,
        latitude = 10.0,
        longitude = 20.0,
        speed = 40.0,
        time = 80L,
        provider = "provider",
      )

    val location = Convert.convertLocationFromDto(testLocation)

    assertEquals(location.accuracy, testLocation.accuracy!!.toFloat())
    assertEquals(location.altitude, testLocation.altitude)
    assertEquals(location.elapsedRealtimeNanos, testLocation.elapsedRealtimeNanos)
    assertEquals(location.bearing, testLocation.bearing!!.toFloat())
    assertEquals(location.latitude, testLocation.latitude)
    assertEquals(location.longitude, testLocation.longitude)
    assertEquals(location.speed, testLocation.speed!!.toFloat())
    assertEquals(location.time, testLocation.time)
    assertEquals(location.provider, testLocation.provider)
  }

  @Test
  fun convertLocationToDto_returnsExpectedValue() {
    val testLocation = Location("provider")
    testLocation.accuracy = 30.0f
    testLocation.altitude = 60.0
    testLocation.elapsedRealtimeNanos = 90L
    testLocation.bearing = 50.0f
    testLocation.latitude = 10.0
    testLocation.longitude = 20.0
    testLocation.speed = 40.0f
    testLocation.time = 80L

    val location = Convert.convertLocationToDto(testLocation)

    assertEquals(location.accuracy!!.toFloat(), testLocation.accuracy)
    assertEquals(location.altitude, testLocation.altitude)
    assertEquals(location.elapsedRealtimeNanos, testLocation.elapsedRealtimeNanos)
    assertEquals(location.bearing!!.toFloat(), testLocation.bearing)
    assertEquals(location.latitude, testLocation.latitude)
    assertEquals(location.longitude, testLocation.longitude)
    assertEquals(location.speed!!.toFloat(), testLocation.speed)
    assertEquals(location.time, testLocation.time)
    assertEquals(location.provider, testLocation.provider)
  }

  @Test
  fun convertStatusLevelToDto_returnsExpectedValue() {
    assertEquals(
      DriverStatusLevelDto.DEBUG,
      Convert.convertStatusLevelToDto(DriverContext.DriverStatusListener.StatusLevel.DEBUG),
    )
    assertEquals(
      DriverStatusLevelDto.INFO,
      Convert.convertStatusLevelToDto(DriverContext.DriverStatusListener.StatusLevel.INFO),
    )
    assertEquals(
      DriverStatusLevelDto.WARNING,
      Convert.convertStatusLevelToDto(DriverContext.DriverStatusListener.StatusLevel.WARNING),
    )
    assertEquals(
      DriverStatusLevelDto.ERROR,
      Convert.convertStatusLevelToDto(DriverContext.DriverStatusListener.StatusLevel.ERROR),
    )
  }

  @Test
  fun convertStatusCodeToDto_returnsExpectedValue() {
    assertEquals(
      DriverStatusCodeDto.DEFAULT_STATUS,
      Convert.convertStatusCodeToDto(DriverContext.DriverStatusListener.StatusCode.DEFAULT),
    )
    assertEquals(
      DriverStatusCodeDto.UNKNOWN_ERROR,
      Convert.convertStatusCodeToDto(DriverContext.DriverStatusListener.StatusCode.UNKNOWN_ERROR),
    )
    assertEquals(
      DriverStatusCodeDto.VEHICLE_NOT_FOUND,
      Convert.convertStatusCodeToDto(
        DriverContext.DriverStatusListener.StatusCode.VEHICLE_NOT_FOUND
      ),
    )
    assertEquals(
      DriverStatusCodeDto.BACKEND_CONNECTIVITY_ERROR,
      Convert.convertStatusCodeToDto(
        DriverContext.DriverStatusListener.StatusCode.BACKEND_CONNECTIVITY_ERROR
      ),
    )
    assertEquals(
      DriverStatusCodeDto.PERMISSION_DENIED,
      Convert.convertStatusCodeToDto(
        DriverContext.DriverStatusListener.StatusCode.PERMISSION_DENIED
      ),
    )
    assertEquals(
      DriverStatusCodeDto.SERVICE_ERROR,
      Convert.convertStatusCodeToDto(DriverContext.DriverStatusListener.StatusCode.SERVICE_ERROR),
    )
    assertEquals(
      DriverStatusCodeDto.FILE_ACCESS_ERROR,
      Convert.convertStatusCodeToDto(
        DriverContext.DriverStatusListener.StatusCode.FILE_ACCESS_ERROR
      ),
    )
    assertEquals(
      DriverStatusCodeDto.TRAVELED_ROUTE_ERROR,
      Convert.convertStatusCodeToDto(
        DriverContext.DriverStatusListener.StatusCode.TRAVELED_ROUTE_ERROR
      ),
    )
  }
}
