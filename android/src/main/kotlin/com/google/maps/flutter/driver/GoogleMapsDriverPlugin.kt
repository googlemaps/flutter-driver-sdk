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
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/** GoogleMapsDriverPlugin */
class GoogleMapsDriverPlugin : FlutterPlugin, ActivityAware {
  private var _deliveryDriverApi: GoogleMapsDeliveryDriver? = null
  private var _ridesharingDriverApi: GoogleMapsRidesharingDriver? = null
  private var _commonDriverApiHandler: GoogleMapsCommonDriverApiHandler? = null
  private var _activity: Activity? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    _deliveryDriverApi = GoogleMapsDeliveryDriver(flutterPluginBinding.binaryMessenger)
    _ridesharingDriverApi = GoogleMapsRidesharingDriver(flutterPluginBinding.binaryMessenger)
    _commonDriverApiHandler =
      GoogleMapsCommonDriverApiHandler(
        flutterPluginBinding.binaryMessenger,
        _deliveryDriverApi!!,
        _ridesharingDriverApi!!
      )
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    _activity = binding.activity
    _deliveryDriverApi?.onActivityCreated(binding.activity)
    _ridesharingDriverApi?.onActivityCreated(binding.activity)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    TODO("Not yet implemented")
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    TODO("Not yet implemented")
  }

  override fun onDetachedFromActivity() {
    _activity = null
  }
}
