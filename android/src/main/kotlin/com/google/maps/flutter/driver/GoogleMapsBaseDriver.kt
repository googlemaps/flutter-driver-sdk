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

import android.app.Activity
import android.location.Location
import com.google.android.libraries.mapsplatform.transportation.driver.api.base.NavigationVehicleReporter
import com.google.android.libraries.mapsplatform.transportation.driver.api.base.data.AuthTokenContext
import com.google.android.libraries.mapsplatform.transportation.driver.api.base.data.AuthTokenContext.AuthTokenFactory
import com.google.android.libraries.mapsplatform.transportation.driver.api.base.data.DriverContext
import com.google.common.util.concurrent.SettableFuture
import io.flutter.plugin.common.BinaryMessenger
import java.lang.ref.WeakReference
import java.util.concurrent.TimeUnit

abstract class GoogleMapsBaseDriver(
  private val messenger: BinaryMessenger,
  private val _authTokenEventApi: AuthTokenEventApi = AuthTokenEventApi(messenger)
) {

  protected var driverContext: DriverContext? = null
  private var weakActivity: WeakReference<Activity>? = null

  /** Set activity instance to use. Some functions require [Activity] instance to show user UI. */
  fun onActivityCreated(activity: Activity) {
    weakActivity = WeakReference(activity)
  }

  /** Convenience function for returning the activity. */
  protected fun getActivity(): Activity {
    return weakActivity?.get() ?: throw FlutterError("activityNotFound", "Activity not created.")
  }

  protected fun getAuthTokenFactory(): AuthTokenFactory {
    return AuthTokenFactory { context: AuthTokenContext? ->
      val future = SettableFuture.create<String>()
      getActivity().runOnUiThread {
        _authTokenEventApi.getToken(context?.taskId ?: "", context?.vehicleId ?: "") {
          if (it.isSuccess) {
            future.set(it.getOrThrow())
          } else {
            future.setException(
              RuntimeException(
                it.exceptionOrNull()?.message ?: "Token retrieval from the backend failed."
              )
            )
          }
        }
      }
      future.get()
    }
  }

  abstract fun initialize(
    providerId: String,
    vehicleId: String,
    abnormalTerminationReportingEnabled: Boolean
  )

  abstract fun isInitialized(): Boolean

  abstract fun dispose()

  abstract fun getDriverSdkVersion(): String

  abstract fun getVehicleReporter(): NavigationVehicleReporter

  fun setLocationTrackingEnabled(enabled: Boolean) {
    if (enabled) {
      getVehicleReporter().enableLocationTracking()
    } else {
      getVehicleReporter().disableLocationTracking()
    }
  }

  fun isLocationTrackingEnabled(): Boolean {
    return getVehicleReporter().isLocationTrackingEnabled
  }

  fun getLocationReportingIntervalMillis(): Long {
    return getVehicleReporter().locationReportingIntervalMillis
  }

  fun setLocationReportingIntervalMillis(milliseconds: Long) {
    getVehicleReporter().setLocationReportingInterval(milliseconds, TimeUnit.MILLISECONDS)
  }

  fun setSupplementalLocation(location: Location) {
    getVehicleReporter().setSupplementalLocation(location)
  }

  fun getProviderId(): String {
    return driverContext?.providerId ?: ""
  }

  fun getVehicleId(): String {
    return driverContext?.vehicleId ?: ""
  }
}
