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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_navigation/google_maps_navigation.dart';
import '../google_maps_driver.dart';
import 'method_channel/convert/statuslistener.dart';
import 'method_channel/method_channel.dart';

/// Called to request an authorization token when
/// various operations are performed.
///
/// The token is queried on every location tracking update and
/// when the app calls Driver APIs that end up sending data to the
/// Fleet Engine. Note you do not usually need to fetch a new token
/// on every call, only when the token is expired.
///
/// Without a valid token vehicle location and state won't get successfully
/// updated to the Fleet Engine. You can throw your own [Exception]
/// if the token retrieval fails. Returning a null or empty string will
/// result in [DriverException] to be thrown by the API call.
///
/// {@category Delivery Driver}
/// {@category Ridesharing Driver}
typedef OnGetToken = Future<String> Function(
  AuthTokenContext context,
);

/// Called when there are status updates (Android-only).
///
/// Called e.g. when the vehicle location or state update succeed or fail.
///
/// No updates are delivered on iOS, use [VehicleReporterListener] instead.
///
/// {@category Delivery Driver}
/// {@category Ridesharing Driver}
typedef OnStatusUpdate = void Function(DriverStatusLevel level,
    DriverStatusCode code, String message, DriverException? exception);

/// Called when the vehicle location or state update succeeded.
///
/// {@category Delivery Driver}
/// {@category Ridesharing Driver}
typedef OnVehicleUpdateDidSucceed = void Function(
  VehicleUpdate vehicleUpdate,
);

/// Called when the vehicle location or state update failed.
///
/// {@category Delivery Driver}
/// {@category Ridesharing Driver}
typedef OnVehicleUpdateDidFail = void Function(
    VehicleUpdate vehicleUpdate, DriverException exception);

/// Base vehicle reporter containing shared methods between delivery and
/// ridesharing apis.
///
/// @nodoc
@visibleForTesting
class CommonVehicleReporter {
  /// Constructor for [CommonVehicleReporter], base class for delivery and
  /// ridesharing reporters
  CommonVehicleReporter._(this._commonApi);

  final TypedCommonDriverApi _commonApi;

  /// Start or stop uploading position reports to the Fleet Engine backend.
  Future<void> setLocationTrackingEnabled(bool enabled) async {
    try {
      return await _commonApi.setLocationTrackingEnabled(enabled);
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Returns whether location tracking is enabled.
  Future<bool> isLocationTrackingEnabled() async {
    return _commonApi.isLocationTrackingEnabled();
  }

  /// Returns the current location reporting interval.
  Future<Duration> getLocationReportingInterval() async {
    return _commonApi.getLocationReportingInterval();
  }

  /// Sets the interval at which location reports will be delivered
  /// to the Fleet Engine backend.
  ///
  /// By default, the interval is 10 seconds. The minimum allowed
  /// interval is 5 seconds and the maximum 60 seconds.
  Future<void> setLocationReportingInterval(Duration duration) async {
    assert(duration.inSeconds >= 5,
        'Minimum supported reporting interval is 5 seconds');
    assert(duration.inSeconds <= 60,
        'Maximum supported reporting interval is 60 seconds');
    return _commonApi.setLocationReportingInterval(duration);
  }

  /// Register [VehicleReporterListener] for listening to the vehicle location
  /// and state updates (iOS-only).
  ///
  /// Setting the listener to null will stop updates from being delivered.
  /// No updates are delivered on Android, use [OnStatusUpdate] driver
  /// initialization callback instead.
  void setListener(VehicleReporterListener? vehicleReporterListener) {
    if (vehicleReporterListener != null) {
      VehicleReporterListenerApi.setup(_VehicleReporterListenerApiImpl(
          vehicleReporterListener: vehicleReporterListener));
    } else {
      VehicleReporterListenerApi.setup(null);
    }
  }
}

/// Vehicle reporter for a delivery vehicle that reports location
/// and stop information.
///
/// This class extends the [CommonVehicleReporter] class and provides
/// additional functionality specific to delivery vehicles.
///
/// Example usage:
/// ```dart
/// DeliveryVehicleReporter reporter = DeliveryDriver.vehicleReporter();
/// await reporter.setLocationReportingInterval(const Duration(milliseconds: 1000));
/// await reporter.arrivedAtStop();
/// await reporter.completedStop();
/// ```
///
/// The [DeliveryVehicleReporter] is a singleton and can be accessed
/// via the static method `DeliveryDriver.vehicleReporter()`.
///
/// {@category Delivery Driver}
class DeliveryVehicleReporter extends CommonVehicleReporter {
  DeliveryVehicleReporter._(this._api, TypedCommonDriverApi _commonApi)
      : super._(_commonApi);

  final DeliveryDriverApi _api;

  /// Signals that vehicle has arrived at the next scheduled stop.
  Future<List<VehicleStop>> arrivedAtStop() async {
    try {
      final List<VehicleStopDto?> stops = await _api.arrivedAtStop();
      return stops.nonNulls
          .map((VehicleStopDto stop) => stop.toVehicleStop())
          .toList();
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Signals that all tasks associated with the current stop have been attempted
  /// or cancelled.
  Future<List<VehicleStop>> completedStop() async {
    try {
      final List<VehicleStopDto?> stops = await _api.completedStop();
      return stops.nonNulls
          .map((VehicleStopDto stop) => stop.toVehicleStop())
          .toList();
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Signals that vehicle has begun traveling towards the next scheduled stops.
  Future<List<VehicleStop>> enrouteToNextStop() async {
    try {
      final List<VehicleStopDto?> stops = await _api.enrouteToNextStop();
      return stops.nonNulls
          .map((VehicleStopDto stop) => stop.toVehicleStop())
          .toList();
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Gets the remaining vehicle stops.
  Future<List<VehicleStop>> getRemainingVehicleStops() async {
    try {
      final List<VehicleStopDto?> stops = await _api.getRemainingVehicleStops();
      return stops.nonNulls
          .map((VehicleStopDto stop) => stop.toVehicleStop())
          .toList();
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Provides a list of stops that vehicle is expected to visit in the given
  /// ordered, uninterrupted sequence.
  Future<List<VehicleStop>> setVehicleStops(List<VehicleStop> stops) async {
    try {
      final List<VehicleStopDto?> stopsDto = await _api.setVehicleStops(
          stops.map((VehicleStop stop) => stop.toDto()).toList());
      return stopsDto.nonNulls
          .map((VehicleStopDto stop) => stop.toVehicleStop())
          .toList();
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Gets [DeliveryVehicle].
  Future<DeliveryVehicle> getDeliveryVehicle() async {
    try {
      final DeliveryVehicleDto vehicle = await _api.getDeliveryVehicle();
      return vehicle.toDeliveryVehicle();
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }
}

/// Vehicle reporter for a ridesharing vehicle that reports location
/// and vehicle state.
///
/// This class extends the [CommonVehicleReporter] class and provides
/// additional functionality specific to delivery vehicles.
///
/// Example usage:
/// ```dart
/// RidesharingVehicleReporter reporter = RidesharingDriver.vehicleReporter();
/// await reporter.setLocationReportingInterval(const Duration(milliseconds: 1000));
/// await reporter.setVehicleState(VehicleState.online);
/// ```
///
/// The [RidesharingVehicleReporter] is a singleton and can be accessed
/// via the static method `RidesharingDriver.vehicleReporter()`.
///
/// {@category Ridesharing Driver}
class RidesharingVehicleReporter extends CommonVehicleReporter {
  RidesharingVehicleReporter._(this._api, TypedCommonDriverApi _commonApi)
      : super._(_commonApi);

  final RidesharingDriverApi _api;

  /// Signals that vehicle has arrived at the next scheduled stop.
  Future<void> setVehicleState(VehicleState state) async {
    try {
      await _api.setVehicleState(state.toDto());
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }
}

/// Listen to the vehicle location and state updates (iOS-only).
///
/// No updates are delivered on Android, use [OnStatusUpdate] driver
/// initialization callback instead.
///
/// {@category Delivery Driver}
/// {@category Ridesharing Driver}
class VehicleReporterListener {
  /// Constructs an instance of [VehicleReporterListener].
  VehicleReporterListener(
      {required this.onDidSucceed, required this.onDidFail});

  /// Called when the vehicle location or state update succeeded.
  final OnVehicleUpdateDidSucceed onDidSucceed;

  /// Called when the vehicle location or state update failed.
  final OnVehicleUpdateDidFail onDidFail;
}

/// Common api implementation for all driver APIs.
///
/// This class should not be used directly. Instead, use the DeliveryDriver and
/// RidesharingDriver classes.
///
/// @nodoc
@visibleForTesting
class TypedCommonDriverApi {
  /// Constructs an instance of [TypedCommonDriverApi] with the given [apiType].
  TypedCommonDriverApi._(this.apiType);

  /// The type of the driver API.
  final DriverApiType apiType;

  final CommonDriverApi _commonApi = CommonDriverApi();

  /// Initialize Driver api instance for [apiType] with the given
  /// [providerId] and [vehicleId].
  Future<void> initialize(
      {required String providerId,
      required String vehicleId,
      required OnGetToken onGetToken,
      OnStatusUpdate? onStatusUpdate,
      bool abnormalTerminationReportingEnabled = false}) async {
    try {
      await _commonApi.initialize(apiType.toDto(), providerId, vehicleId,
          abnormalTerminationReportingEnabled);

      AuthTokenEventApi.setup(
          _AuthTokenEventApiImpl(onGetTokenEvent: onGetToken));
      if (onStatusUpdate != null) {
        DriverStatusListenerApi.setup(
            _DriverStatusListenerApiImpl(onStatusUpdateEvent: onStatusUpdate));
      } else {
        DriverStatusListenerApi.setup(null);
      }
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'sessionNotInitialized':
          throw const DriverInitializationException(
              DriverInitializationError.navigationNotInitialized);
        case 'apiAlreadyInitialized':
          throw const DriverInitializationException(
              DriverInitializationError.apiAlreadyInitialized);
        default:
          rethrow;
      }
    }
  }

  /// Returns true if the Driver api instance for [apiType] has been
  /// successfully initialized.
  Future<bool> isInitialized() async {
    return _commonApi.isInitialized(apiType.toDto());
  }

  /// Returns the unique identifier for this provider.
  Future<String> getProviderId() async {
    return _commonApi.getProviderId(apiType.toDto());
  }

  /// Returns the unique identifier for this vehicle for this provider.
  Future<String> getVehicleId() async {
    return _commonApi.getVehicleId(apiType.toDto());
  }

  /// Cleans up instance of the api with type [apiType] before all references
  /// to it are destroyed.
  Future<void> dispose() async {
    return _commonApi.dispose(apiType.toDto());
  }

  /// Returns the current Driver SDK version.
  Future<String> getDriverSdkVersion() async {
    return _commonApi.getDriverSdkVersion(apiType.toDto());
  }

  /// Start or stop uploading position reports to the Fleet Engine backend.
  Future<void> setLocationTrackingEnabled(bool enabled) async {
    try {
      return await _commonApi.setLocationTrackingEnabled(
          apiType.toDto(), enabled);
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Returns whether location tracking is enabled.
  Future<bool> isLocationTrackingEnabled() async {
    return _commonApi.isLocationTrackingEnabled(apiType.toDto());
  }

  /// Returns the current location reporting interval.
  Future<Duration> getLocationReportingInterval() async {
    try {
      return Duration(
          milliseconds: await _commonApi
              .getLocationReportingIntervalMillis(apiType.toDto()));
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Sets the interval at which location reports will be delivered
  /// to the Fleet Engine backend.
  ///
  /// By default, the interval is 10 seconds. The minimum allowed
  /// interval is 5 seconds and the maximum 60 seconds.
  Future<void> setLocationReportingInterval(Duration duration) async {
    assert(duration.inSeconds >= 5,
        'Minimum supported reporting interval is 5 seconds');
    assert(duration.inSeconds <= 60,
        'Maximum supported reporting interval is 60 seconds');
    try {
      return await _commonApi.setLocationReportingIntervalMillis(
          apiType.toDto(), duration.inMilliseconds);
    } on PlatformException catch (e) {
      throw _convertException(e);
    }
  }

  /// Sets supplementary location information which FleetEngine will use when
  /// it deems it more accurate or current than the road-snapped locations
  /// generated internally by the Driver SDK.
  ///
  /// Android-only. Throws [UnsupportedError] on iOS.
  Future<void> setSupplementalLocation(Location location) async {
    try {
      return _commonApi.setSupplementalLocation(
          apiType.toDto(), location.toDto());
    } on PlatformException catch (error) {
      if (error.code == 'notSupported') {
        throw UnsupportedError(
            'Setting supplemental location is not supported on iOS.');
      } else {
        rethrow;
      }
    }
  }
}

/// Delivery driver API implementation.
///
/// Provides an implementation of the delivery driver API. It allows
/// developers to interact with the Fleet Engine backend and perform various
/// operations related to delivery drivers.
///
/// Serves as a communication layer with the native Delivery driver SDK,
/// allowing developers to initialize the SDK, retrieve driver and vehicle information,
/// report vehicle updates, and perform other related tasks.
///
/// {@category Delivery Driver}
class DeliveryDriver {
  DeliveryDriver._();

  static final TypedCommonDriverApi _deliveryCommonDriverApi =
      TypedCommonDriverApi._(DriverApiType.delivery);
  static final DeliveryDriverApi _deliveryApi = DeliveryDriverApi();
  static final DeliveryVehicleReporter _reporter =
      DeliveryVehicleReporter._(_deliveryApi, _deliveryCommonDriverApi);

  /// Initialize DeliveryDriver instance with the given
  /// [providerId] and [vehicleId].
  ///
  /// Also, you need to implement [onGetToken] callback that is called
  /// whenever data needs to be sent to the Fleet Engine backend to query
  /// a valid authentication token.
  ///
  /// Optional parameter [abnormalTerminationReportingEnabled] can be used to
  /// disable reporting abnormal SDK terminations such as app crashes while the
  /// SDK is still running. By default, the reporting is enabled.
  static Future<void> initialize(
      {required String providerId,
      required String vehicleId,
      required OnGetToken onGetToken,
      OnStatusUpdate? onStatusUpdate,
      bool abnormalTerminationReportingEnabled = false}) async {
    return _deliveryCommonDriverApi.initialize(
        providerId: providerId,
        vehicleId: vehicleId,
        onGetToken: onGetToken,
        onStatusUpdate: onStatusUpdate,
        abnormalTerminationReportingEnabled:
            abnormalTerminationReportingEnabled);
  }

  /// Returns an instance of the [DeliveryVehicleReporter],
  /// which reports vehicle information to FleetEngine.
  static DeliveryVehicleReporter get vehicleReporter {
    return _reporter;
  }

  /// Returns an instance of the [TypedCommonDriverApi] for delivery driver.
  /// This should only be used for testing.
  @visibleForTesting
  static TypedCommonDriverApi get commonDriverApi {
    return _deliveryCommonDriverApi;
  }

  /// Returns true if the DeliveryDriver instance has been successfully initialized.
  static Future<bool> isInitialized() async {
    return _deliveryCommonDriverApi.isInitialized();
  }

  /// Returns the unique identifier for this provider.
  static Future<String> getProviderId() async {
    return _deliveryCommonDriverApi.getProviderId();
  }

  /// Returns the unique identifier for this vehicle for this provider.
  static Future<String> getVehicleId() async {
    return _deliveryCommonDriverApi.getVehicleId();
  }

  /// Cleans up instance of the DeliveryDriver before all references to it are
  /// destroyed.
  static Future<void> dispose() async {
    return _deliveryCommonDriverApi.dispose();
  }

  /// Returns the current Driver SDK version.
  static Future<String> getDriverSdkVersion() async {
    return _deliveryCommonDriverApi.getDriverSdkVersion();
  }

  /// Sets supplementary location information which FleetEngine will use when
  /// it deems it more accurate or current than the road-snapped locations
  /// generated internally by the Driver SDK.
  ///
  /// Android-only. Throws [UnsupportedError] on iOS.
  static Future<void> setSupplementalLocation(Location location) async {
    return _deliveryCommonDriverApi.setSupplementalLocation(location);
  }
}

/// Ridesharing driver API implementation.
///
/// Provides an implementation of the ridesharing driver API. It allows
/// developers to interact with the Fleet Engine backend and perform various
/// operations related to ridesharing drivers.
///
/// Serves as a communication layer with the native Ridesharing driver SDK,
/// allowing developers to initialize the SDK, set vehicle state, and perform
/// other related tasks.
///
/// {@category Ridesharing Driver}
class RidesharingDriver {
  RidesharingDriver._();

  static final TypedCommonDriverApi _ridesharingCommonDriverApi =
      TypedCommonDriverApi._(DriverApiType.ridesharing);
  static final RidesharingDriverApi _ridesharingApi = RidesharingDriverApi();
  static final RidesharingVehicleReporter _reporter =
      RidesharingVehicleReporter._(
          _ridesharingApi, _ridesharingCommonDriverApi);

  /// Initialize RidesharingDriver instance with the given
  /// [providerId] and [vehicleId].
  ///
  /// Also, you need to implement [onGetToken] callback that is called
  /// whenever data needs to be sent to the Fleet Engine backend to query
  /// a valid authentication token.
  ///
  /// Optional parameter [abnormalTerminationReportingEnabled] can be used to
  /// disable reporting abnormal SDK terminations such as app crashes while the
  /// SDK is still running. By default, the reporting is enabled.
  static Future<void> initialize(
      {required String providerId,
      required String vehicleId,
      required OnGetToken onGetToken,
      OnStatusUpdate? onStatusUpdate,
      bool abnormalTerminationReportingEnabled = false}) async {
    return _ridesharingCommonDriverApi.initialize(
        providerId: providerId,
        vehicleId: vehicleId,
        onGetToken: onGetToken,
        onStatusUpdate: onStatusUpdate,
        abnormalTerminationReportingEnabled:
            abnormalTerminationReportingEnabled);
  }

  /// Returns an instance of the [RidesharingVehicleReporter],
  /// which reports vehicle information to FleetEngine.
  static RidesharingVehicleReporter get vehicleReporter {
    return _reporter;
  }

  /// Returns an instance of the [TypedCommonDriverApi] for ridesharing driver.
  /// This should only be used for testing.
  @visibleForTesting
  static TypedCommonDriverApi get commonDriverApi {
    return _ridesharingCommonDriverApi;
  }

  /// Returns true if the RidesharingDriver instance has been successfully initialized.
  static Future<bool> isInitialized() async {
    return _ridesharingCommonDriverApi.isInitialized();
  }

  /// Returns the unique identifier for this provider.
  static Future<String> getProviderId() async {
    return _ridesharingCommonDriverApi.getProviderId();
  }

  /// Returns the unique identifier for this vehicle for this provider.
  static Future<String> getVehicleId() async {
    return _ridesharingCommonDriverApi.getVehicleId();
  }

  /// Cleans up instance of the RidesharingDriver before all references to it are
  /// destroyed.
  static Future<void> dispose() async {
    return _ridesharingCommonDriverApi.dispose();
  }

  /// Returns the current Driver SDK version.
  static Future<String> getDriverSdkVersion() async {
    return _ridesharingCommonDriverApi.getDriverSdkVersion();
  }

  /// Sets supplementary location information which FleetEngine will use when
  /// it deems it more accurate or current than the road-snapped locations
  /// generated internally by the Driver SDK.
  ///
  /// Android-only. Throws [UnsupportedError] on iOS.
  static Future<void> setSupplementalLocation(Location location) async {
    return _ridesharingCommonDriverApi.setSupplementalLocation(location);
  }
}

/// Possible errors that [DeliveryDriver.initialize] can throw.
///
/// This enum represents the possible errors that can be thrown when
/// initializing the [DeliveryDriver] instance using the
/// [DeliveryDriver.initialize] method.
///
/// {@category Delivery Driver}
/// {@category Ridesharing Driver}
enum DriverInitializationError {
  /// Navigation was not initialized yet.
  ///
  /// This error is thrown when the navigation session has not been initialized
  /// before initializing the driver. To resolve this error, make sure to call
  /// [GoogleMapsNavigator.initializeNavigationSession] before initializing
  /// the driver.
  navigationNotInitialized,

  /// Driver API was already initialized.
  ///
  /// This error is thrown when the driver API has already been initialized.
  /// To resolve this error, make sure to call [DeliveryDriver.dispose] or
  /// [RidesharingDriver.dispose] before initializing the driver instance again.
  apiAlreadyInitialized,
}

/// Exception thrown by [DeliveryDriver.initialize].
///
/// {@category Delivery Driver}
/// {@category Ridesharing Driver}
class DriverInitializationException implements Exception {
  /// Default constructor for [DriverInitializationException].
  const DriverInitializationException(this.code);

  /// The error code for the exception.
  final DriverInitializationError code;
}

/// Method call has failed, because [DeliveryDriver]
/// hasn't yet been successfully initialized.
///
/// {@category Delivery Driver}
/// {@category Ridesharing Driver}
class DriverNotInitializedException implements Exception {
  /// Default constructor for [DriverNotInitializedException].
  const DriverNotInitializedException();
}

/// Exception thrown when an operation fails due to a failure in the Driver SDK.
///
/// This exception can occur when the Driver SDK fails to send data to the Fleet Engine backend.
/// Possible reasons for the failure include an invalid authentication token or exceeding the API rate limit.
///
/// This exception can be thrown by Driver SDK methods that communicate with the Fleet Engine,
/// or it can be thrown to the [VehicleReporterListener] when periodic vehicle location and state updates fail.
///
/// {@category Delivery Driver}
/// {@category Ridesharing Driver}
class DriverException implements Exception {
  /// Constructs a [DriverException] with the specified error [message] and [code].
  const DriverException({required this.message, required this.code});

  /// The error code associated with the exception.
  final String code;

  /// The error message associated with the exception.
  /// Note that the exact error message may vary between Android and iOS.
  final String message;
}

Exception _convertException(PlatformException exception) {
  switch (exception.code) {
    case 'driverNotInitialized':
      return const DriverNotInitializedException();
    case 'driverException':
      return DriverException(
        code: exception.details.toString(),
        message:
            exception.message ?? 'Failed to send data to the Fleet Engine.',
      );
    default:
      return exception;
  }
}

/// The AuthTokenContext class encapsulates the state needed to generate an auth
/// token for a given request.
///
/// {@category Delivery Driver}
/// {@category Ridesharing Driver}
class AuthTokenContext {
  /// Construct [AuthTokenContext].
  const AuthTokenContext._({this.taskId, this.vehicleId});

  /// Optional task ID, defined if it is a required for the auth token claim.
  final String? taskId;

  /// Optional vehicle ID, defined if it is a required for the auth token claim.
  final String? vehicleId;
}

/// Event API implementation to receive token requests from Driver SDK.
class _AuthTokenEventApiImpl implements AuthTokenEventApi {
  /// Basic constructor
  const _AuthTokenEventApiImpl({
    this.onGetTokenEvent,
  });

  /// Callback for authentication token retrieval.
  final OnGetToken? onGetTokenEvent;

  @override
  Future<String> getToken(String? taskId, String? vehicleId) async {
    return onGetTokenEvent!
        .call(AuthTokenContext._(taskId: taskId, vehicleId: vehicleId));
  }
}

/// VehicleReporterListener API implementation to receive vehicle location and
/// state updates from Driver SDK (iOS-only).
class _VehicleReporterListenerApiImpl implements VehicleReporterListenerApi {
  /// Construct [_VehicleReporterListenerApiImpl]
  const _VehicleReporterListenerApiImpl({
    required this.vehicleReporterListener,
  });

  /// Public VehicleReporterListener object.
  final VehicleReporterListener vehicleReporterListener;

  @override
  void onDidSucceed(VehicleUpdateDto vehicleUpdate) {
    vehicleReporterListener.onDidSucceed(vehicleUpdate.toVehicleUpdate());
  }

  @override
  void onDidFail(
      VehicleUpdateDto vehicleUpdate, String? errorCode, String? errorMessage) {
    vehicleReporterListener.onDidFail(vehicleUpdate.toVehicleUpdate(),
        DriverException(code: errorCode ?? '', message: errorMessage!));
  }
}

/// Event API implementation to receive driver status updates from Driver SDK (Android-only).
class _DriverStatusListenerApiImpl implements DriverStatusListenerApi {
  /// Basic constructor
  const _DriverStatusListenerApiImpl({
    this.onStatusUpdateEvent,
  });

  /// Callback for authentication token retrieval.
  final OnStatusUpdate? onStatusUpdateEvent;

  @override
  void onStatusUpdate(DriverStatusLevelDto level, DriverStatusCodeDto code,
      String message, String? errorCode, String? errorMessage) {
    return onStatusUpdateEvent!.call(
        level.toStatusLevel(),
        code.toStatusCode(),
        message,
        errorCode != null
            ? DriverException(
                message: errorMessage ?? 'Unknown error.', code: errorCode)
            : null);
  }
}
