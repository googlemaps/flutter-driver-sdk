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

import io.flutter.plugin.common.BinaryMessenger

class GoogleMapsCommonDriverApiHandler(
  messenger: BinaryMessenger,
  private val deliveryDriverApi: GoogleMapsDeliveryDriver,
  private val ridesharingDriverApi: GoogleMapsRidesharingDriver,
) : CommonDriverApi {
  init {
    CommonDriverApi.setUp(messenger, this)
  }

  private fun getApi(type: DriverApiTypeDto): GoogleMapsBaseDriver =
    when (type) {
      DriverApiTypeDto.DELIVERY -> deliveryDriverApi
      DriverApiTypeDto.RIDESHARING -> ridesharingDriverApi
      else -> throw FlutterError("unsupportedDriverApi", "Driver api type $type is not supported")
    }

  override fun initialize(
    type: DriverApiTypeDto,
    providerId: String,
    vehicleId: String,
    abnormalTerminationReportingEnabled: Boolean
  ) {
    if (deliveryDriverApi.isInitialized()) {
      throw FlutterError(
        "apiAlreadyInitialized",
        "DeliveryDriverAPI instance already exists, and must be disposed before $type can be initialized"
      )
    }
    if (ridesharingDriverApi.isInitialized()) {
      throw FlutterError(
        "apiAlreadyInitialized",
        "RidesharingDriverAPI instance already exists, and must be disposed before $type can be initialized"
      )
    }
    return getApi(type).initialize(providerId, vehicleId, abnormalTerminationReportingEnabled)
  }

  override fun isInitialized(type: DriverApiTypeDto): Boolean {
    return getApi(type).isInitialized()
  }

  override fun getProviderId(type: DriverApiTypeDto): String {
    return getApi(type).getProviderId()
  }

  override fun getVehicleId(type: DriverApiTypeDto): String {
    return getApi(type).getVehicleId()
  }

  override fun isLocationTrackingEnabled(type: DriverApiTypeDto): Boolean {
    return getApi(type).isLocationTrackingEnabled()
  }

  override fun setLocationTrackingEnabled(type: DriverApiTypeDto, enabled: Boolean) {
    return getApi(type).setLocationTrackingEnabled(enabled)
  }

  override fun getLocationReportingIntervalMillis(type: DriverApiTypeDto): Long {
    return getApi(type).getLocationReportingIntervalMillis()
  }

  override fun setLocationReportingIntervalMillis(type: DriverApiTypeDto, milliseconds: Long) {
    return getApi(type).setLocationReportingIntervalMillis(milliseconds)
  }

  override fun dispose(type: DriverApiTypeDto) {
    return getApi(type).dispose()
  }

  override fun getDriverSdkVersion(type: DriverApiTypeDto): String {
    return getApi(type).getDriverSdkVersion()
  }

  override fun setSupplementalLocation(type: DriverApiTypeDto, location: LocationDto) {
    getApi(type).setSupplementalLocation(Convert.convertLocationFromDto(location))
  }
}
