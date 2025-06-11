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

import com.google.android.libraries.mapsplatform.transportation.driver.api.base.data.DriverContext
import com.google.android.libraries.mapsplatform.transportation.driver.api.base.data.VehicleStop
import com.google.android.libraries.mapsplatform.transportation.driver.api.delivery.DeliveryDriverApi as NativeDeliveryDriverApi
import com.google.android.libraries.mapsplatform.transportation.driver.api.delivery.DeliveryVehicleManager
import com.google.android.libraries.mapsplatform.transportation.driver.api.delivery.data.DeliveryVehicle
import com.google.android.libraries.mapsplatform.transportation.driver.api.delivery.vehiclereporter.DeliveryVehicleReporter
import com.google.android.libraries.navigation.NavigationApi
import com.google.android.libraries.navigation.Navigator
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.FutureCallback
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.MoreExecutors
import com.google.maps.flutter.navigation.GoogleMapsNavigationSessionManager
import io.flutter.plugin.common.BinaryMessenger

class GoogleMapsDeliveryDriver(private val messenger: BinaryMessenger) :
  GoogleMapsBaseDriver(messenger), DeliveryDriverApi {
  private var _deliveryDriverApi: NativeDeliveryDriverApi? = null
  private var _statusListener: GoogleMapsDriverStatusListener? = null

  init {
    DeliveryDriverApi.setUp(messenger, this)
  }

  override fun initialize(
    providerId: String,
    vehicleId: String,
    abnormalTerminationReportingEnabled: Boolean,
  ) {
    val navigator: Navigator =
      GoogleMapsNavigationSessionManager.getInstance().getNavigatorWithoutError()
        ?: throw FlutterError(
          "sessionNotInitialized",
          "Cannot access navigation functionality before the navigation session has been initialized.",
        )

    _statusListener = GoogleMapsDriverStatusListener(messenger, getActivity())

    val driverContext: DriverContext =
      DriverContext.builder(getActivity().application)
        .setProviderId(providerId)
        .setVehicleId(vehicleId)
        .setNavigator(navigator)
        .setAuthTokenFactory(getAuthTokenFactory())
        .setDriverStatusListener(_statusListener)
        .setRoadSnappedLocationProvider(
          NavigationApi.getRoadSnappedLocationProvider(getActivity().application)
        )
        .build()

    _deliveryDriverApi = NativeDeliveryDriverApi.createInstance(driverContext)
    this.driverContext = driverContext

    NativeDeliveryDriverApi.setAbnormalTerminationReportingEnabled(
      abnormalTerminationReportingEnabled
    )
  }

  override fun isInitialized(): Boolean {
    return _deliveryDriverApi != null
  }

  override fun getDriverSdkVersion(): String {
    return NativeDeliveryDriverApi.getDriverSdkVersion()
  }

  override fun getVehicleReporter(): DeliveryVehicleReporter {
    if (_deliveryDriverApi != null) {
      return _deliveryDriverApi!!.deliveryVehicleReporter
    } else {
      throw FlutterError(
        "driverNotInitialized",
        "Cannot access DeliveryVehicleReporter before the DeliveryDriver has been initialized.",
      )
    }
  }

  private fun getVehicleManager(): DeliveryVehicleManager {
    if (_deliveryDriverApi != null) {
      return _deliveryDriverApi!!.deliveryVehicleManager
    } else {
      throw FlutterError(
        "driverNotInitialized",
        "Cannot access DeliveryVehicleManager before the DeliveryDriver has been initialized.",
      )
    }
  }

  override fun dispose() {
    NativeDeliveryDriverApi.clearInstance()
    _deliveryDriverApi = null
    driverContext = null
  }

  override fun arrivedAtStop(callback: (Result<List<VehicleStopDto>>) -> Unit) {
    try {
      val future = getVehicleReporter().arrivedAtStop()
      Futures.addCallback(
        future,
        object : FutureCallback<ImmutableList<VehicleStop>> {
          override fun onSuccess(result: ImmutableList<VehicleStop>) {
            val values = result.map { Convert.convertVehicleStopToDto(it) }
            callback(Result.success(values))
          }

          override fun onFailure(t: Throwable) {
            callback(Result.failure(Convert.convertToDriverException(t)))
          }
        },
        MoreExecutors.directExecutor(),
      )
    } catch (error: Throwable) {
      callback(Result.failure(error))
    }
  }

  override fun completedStop(callback: (Result<List<VehicleStopDto>>) -> Unit) {
    try {
      val future = getVehicleReporter().completedStop()
      Futures.addCallback(
        future,
        object : FutureCallback<ImmutableList<VehicleStop>> {
          override fun onSuccess(result: ImmutableList<VehicleStop>) {
            val values = result.map { Convert.convertVehicleStopToDto(it) }
            callback(Result.success(values))
          }

          override fun onFailure(t: Throwable) {
            callback(Result.failure(Convert.convertToDriverException(t)))
          }
        },
        MoreExecutors.directExecutor(),
      )
    } catch (error: Throwable) {
      callback(Result.failure(error))
    }
  }

  override fun enrouteToNextStop(callback: (Result<List<VehicleStopDto>>) -> Unit) {
    try {
      val future = getVehicleReporter().enrouteToNextStop()
      Futures.addCallback(
        future,
        object : FutureCallback<ImmutableList<VehicleStop>> {
          override fun onSuccess(result: ImmutableList<VehicleStop>) {
            val values = result.map { Convert.convertVehicleStopToDto(it) }
            callback(Result.success(values))
          }

          override fun onFailure(t: Throwable) {
            callback(Result.failure(Convert.convertToDriverException(t)))
          }
        },
        MoreExecutors.directExecutor(),
      )
    } catch (error: Throwable) {
      callback(Result.failure(error))
    }
  }

  override fun getRemainingVehicleStops(callback: (Result<List<VehicleStopDto>>) -> Unit) {
    try {
      val future = getVehicleReporter().remainingVehicleStops
      Futures.addCallback(
        future,
        object : FutureCallback<ImmutableList<VehicleStop>> {
          override fun onSuccess(result: ImmutableList<VehicleStop>) {
            val values = result.map { Convert.convertVehicleStopToDto(it) }
            callback(Result.success(values))
          }

          override fun onFailure(t: Throwable) {
            callback(Result.failure(Convert.convertToDriverException(t)))
          }
        },
        MoreExecutors.directExecutor(),
      )
    } catch (error: Throwable) {
      callback(Result.failure(error))
    }
  }

  override fun setVehicleStops(
    stops: List<VehicleStopDto>,
    callback: (Result<List<VehicleStopDto>>) -> Unit,
  ) {
    try {
      val future =
        getVehicleReporter().setVehicleStops(stops.map { Convert.convertVehicleStopFromDto(it) })
      Futures.addCallback(
        future,
        object : FutureCallback<ImmutableList<VehicleStop>> {
          override fun onSuccess(result: ImmutableList<VehicleStop>) {
            val values = result.map { Convert.convertVehicleStopToDto(it) }
            callback(Result.success(values))
          }

          override fun onFailure(t: Throwable) {
            callback(Result.failure(Convert.convertToDriverException(t)))
          }
        },
        MoreExecutors.directExecutor(),
      )
    } catch (error: Throwable) {
      callback(Result.failure(error))
    }
  }

  override fun getDeliveryVehicle(callback: (Result<DeliveryVehicleDto>) -> Unit) {
    try {
      val future = getVehicleManager().vehicle
      Futures.addCallback(
        future,
        object : FutureCallback<DeliveryVehicle> {
          override fun onSuccess(result: DeliveryVehicle) {
            val values = Convert.convertDeliveryVehicleToDto(result)
            callback(Result.success(values))
          }

          override fun onFailure(t: Throwable) {
            callback(Result.failure(Convert.convertToDriverException(t)))
          }
        },
        MoreExecutors.directExecutor(),
      )
    } catch (error: Throwable) {
      callback(Result.failure(error))
    }
  }
}
