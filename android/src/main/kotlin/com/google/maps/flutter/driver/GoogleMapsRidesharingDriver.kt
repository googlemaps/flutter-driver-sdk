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
import com.google.android.libraries.mapsplatform.transportation.driver.api.ridesharing.RidesharingDriverApi as NativeRidesharingDriverApi
import com.google.android.libraries.mapsplatform.transportation.driver.api.ridesharing.vehiclereporter.RidesharingVehicleReporter
import com.google.android.libraries.navigation.NavigationApi
import com.google.android.libraries.navigation.Navigator
import com.google.maps.flutter.navigation.GoogleMapsNavigationSessionManager
import io.flutter.plugin.common.BinaryMessenger

class GoogleMapsRidesharingDriver(private val messenger: BinaryMessenger) :
  GoogleMapsBaseDriver(messenger), RidesharingDriverApi {
  private var _ridesharingDriverApi: NativeRidesharingDriverApi? = null
  private var _statusListener: GoogleMapsDriverStatusListener? = null

  init {
    RidesharingDriverApi.setUp(messenger, this)
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

    _ridesharingDriverApi = NativeRidesharingDriverApi.createInstance(driverContext)
    this.driverContext = driverContext

    NativeRidesharingDriverApi.setAbnormalTerminationReportingEnabled(
      abnormalTerminationReportingEnabled
    )
  }

  override fun isInitialized(): Boolean {
    return _ridesharingDriverApi != null
  }

  override fun getDriverSdkVersion(): String {
    return NativeRidesharingDriverApi.getDriverSdkVersion()
  }

  override fun getVehicleReporter(): RidesharingVehicleReporter {
    if (_ridesharingDriverApi != null) {
      return _ridesharingDriverApi!!.ridesharingVehicleReporter
    } else {
      throw FlutterError(
        "driverNotInitialized",
        "Cannot access RidesharingVehicleReporter before the RidesharingDriver has been initialized.",
      )
    }
  }

  override fun dispose() {
    NativeRidesharingDriverApi.clearInstance()
    _ridesharingDriverApi = null
    driverContext = null
  }

  override fun setVehicleState(state: VehicleStateDto) {
    getVehicleReporter().setVehicleState(Convert.convertVehicleStateFromDto(state))
  }
}
