/*
 * Copyright 2024 Google LLC
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
import com.google.android.libraries.mapsplatform.transportation.driver.api.base.data.DriverContext
import com.google.android.libraries.mapsplatform.transportation.driver.api.base.data.DriverContext.DriverStatusListener
import io.flutter.plugin.common.BinaryMessenger

internal class GoogleMapsDriverStatusListener(
  private val messenger: BinaryMessenger,
  private val activity: Activity
) : DriverContext.DriverStatusListener {
  private val _statusListener: DriverStatusListenerApi = DriverStatusListenerApi(messenger)

  override fun updateStatus(
    level: DriverStatusListener.StatusLevel,
    code: DriverStatusListener.StatusCode,
    message: String,
    error: Throwable?
  ) {
    var errorCode: String? = null
    var errorMessage: String? = null
    if (error != null) {
      errorCode = Convert.extractErrorCode(error)
      errorMessage = Convert.extractErrorMessage(error)
    }
    activity.runOnUiThread {
      _statusListener.onStatusUpdate(
        Convert.convertStatusLevelToDto(level),
        Convert.convertStatusCodeToDto(code),
        message,
        errorCode,
        errorMessage
      ) {}
    }
  }
}
