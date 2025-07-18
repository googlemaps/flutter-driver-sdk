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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_driver_flutter/google_driver_flutter.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import '../api/lmfs.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';

/// Google Maps Driver LMFS demo page.
///
/// This demo page shows how to use the Google Maps Driver SDK plugin
/// with LMFS API.
class LMFSDriverPage extends ExamplePage {
  /// Creates a Google Maps Driver LMFS demo page.
  const LMFSDriverPage({super.key})
    : super(
        leading: const Icon(Icons.directions),
        title: 'Delivery Driver (LMFS)',
      );

  @override
  ExamplePageState<LMFSDriverPage> createState() => _DriverPageState();
}

/// Driver demo page state.
class _DriverPageState extends ExamplePageState<LMFSDriverPage>
    with WidgetsBindingObserver {
  bool _backendInitialized = false;
  bool _driverInitialized = false;
  bool _navigationRunning = false;
  bool _locationTrackingEnabled = true;
  bool _simulationEnabled = true;
  Duration? _locationReportingInterval;
  List<VehicleStop> _vehicleStops = <VehicleStop>[];
  VehicleStop? _nextStop;
  LatLng _supplementalLocation = const LatLng(latitude: 65.0, longitude: 25.5);

  /// Controls how the stop date is updatad, using backend methods or driver API.
  ///
  /// NOTE: DriverAPI currently is not able to update the stops status properly,
  /// this is fixed with the [_forceLocalStopStateOnDriverApiUpdates] flag.
  _StopUpdateMethod _stopUpdateMethod = _StopUpdateMethod.backend;

  /// This flag is used to force the stop state to be updated locally, as the
  /// driver API is not updating the stop state properly.
  bool _forceLocalStopStateOnDriverApiUpdates = true;

  StreamSubscription<OnArrivalEvent>? _onArrivalSubscription;

  late final GoogleNavigationViewController _navigationViewController;

  late LMFSManifest _manifest;
  TokenResponse? _tokenResponse;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadingWrapper(_checkPrerequisites);
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _checkPrerequisites({bool cleanup = true}) async {
    if (!await getLMFSApi().backendIsRunning()) {
      _showMessage('Could not connect to the LMFS backend.');
      return;
    }
    if (!hasProjectId()) {
      _showMessage('The required Project ID has not been defined.');
      return;
    }

    if (cleanup) {
      /// Cleans up possible previous driver and navigation SDKs states.
      await cleanupAll();
    }

    await initBackend();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // This example app does not have internal state handling for the app, to
    // keep the example simple, we just close the page when the app is paused.
    if (mounted &&
        state == AppLifecycleState.hidden &&
        Navigator.canPop(context)) {
      Navigator.pop(context);
      cleanupAll();
    }
  }

  Future<void> initBackend() async {
    _manifest = await initLMFSBackendForVehicle(
      vehicleId: 'vehicle_1',
      startLocation: NavigationWaypoint.withLatLngTarget(
        title: 'GWC3, 1505 Salado, Mountain View, CA 94043',
        target: const LatLng(latitude: 37.4231623, longitude: -122.0925322),
      ),
      deliveryWaypoints: <NavigationWaypoint>[
        NavigationWaypoint.withLatLngTarget(
          title: 'LMK6-A, 1947 Landings Drive, Mountain View, CA 94043',
          target: const LatLng(latitude: 37.41937, longitude: -122.08882),
        ),
        NavigationWaypoint.withLatLngTarget(
          title: 'Google Building 1900',
          target: const LatLng(latitude: 37.422917, longitude: -122.087528),
        ),
      ],
      stopWaypoints: <NavigationWaypoint>[
        NavigationWaypoint.withLatLngTarget(
          title: 'Google Landmark Bldgs',
          target: const LatLng(latitude: 37.41914, longitude: -122.08845),
        ),
        NavigationWaypoint.withLatLngTarget(
          title: 'CWF7+748, 1700 Amphitheatre Pkwy, Mountain View, CA 94043',
          target: const LatLng(latitude: 37.4231613, longitude: -122.087159),
        ),
      ],
    );

    debugPrint('LMFS backend initialized:\n${jsonEncode(_manifest.toJson())}');
    if (mounted) {
      setState(() {
        _backendInitialized = true;
      });
    }
  }

  Future<void> _initDriver() async {
    if (!await DeliveryDriver.isInitialized()) {
      if (!await GoogleMapsNavigator.areTermsAccepted()) {
        await GoogleMapsNavigator.showTermsAndConditionsDialog(
          'test_title',
          'test_company_name',
        );
      }
      try {
        await GoogleMapsNavigator.initializeNavigationSession();
        _setupListeners();

        final LatLng? startLocation = _manifest.vehicle.startLocation?.target;
        if (startLocation != null) {
          await GoogleMapsNavigator.simulator.setUserLocation(startLocation);
        }

        await DeliveryDriver.initialize(
          providerId: _manifest.vehicle.providerId,
          vehicleId: _manifest.vehicle.vehicleId,
          onGetToken: (AuthTokenContext context) async {
            if (_tokenResponse == null ||
                DateTime.now().millisecondsSinceEpoch >
                    _tokenResponse!.expirationTimestampMs) {
              _tokenResponse = await getLMFSApi().getToken(
                LMFSTokenType.deliveryDriver,
                _manifest.vehicle.vehicleId,
              );
            }
            if (_tokenResponse == null || _tokenResponse!.token.isEmpty) {
              throw Exception('Token retrieval from the backend failed.');
            }

            return _tokenResponse!.token;
          },
          onStatusUpdate:
              Platform.isAndroid
                  ? (
                    DriverStatusLevel level,
                    DriverStatusCode code,
                    String message,
                    DriverException? exception,
                  ) {
                    debugPrint(
                      // ignore: unnecessary_brace_in_string_interps
                      'Driver status changed: $level - $code - $message, e: ${exception?.code} ${exception?.message}',
                    );
                  }
                  : null,
        );

        if (Platform.isIOS) {
          DeliveryDriver.vehicleReporter.setListener(
            VehicleReporterListener(
              onDidSucceed: (VehicleUpdate vehicleUpdate) {
                debugPrint(
                  'Vehicle update succeeded - location (${vehicleUpdate.location?.latitude.toStringAsFixed(3) ?? '-'}, ${vehicleUpdate.location?.longitude.toStringAsFixed(3) ?? '-'})',
                );
              },
              onDidFail: (
                VehicleUpdate vehicleUpdate,
                DriverException exception,
              ) {
                debugPrint(
                  'Vehicle updated failed - location (${vehicleUpdate.location?.latitude.toStringAsFixed(3) ?? '-'}, ${vehicleUpdate.location?.longitude.toStringAsFixed(3) ?? '-'})',
                );
                debugPrint('  Error ${exception.message}');
              },
            ),
          );
        }

        _locationReportingInterval =
            await DeliveryDriver.vehicleReporter.getLocationReportingInterval();
        await DeliveryDriver.vehicleReporter.setLocationTrackingEnabled(
          _locationTrackingEnabled,
        );
        await DeliveryDriver.vehicleReporter.setLocationReportingInterval(
          _locationReportingInterval!,
        );

        _driverInitialized = true;
        if (_stopUpdateMethod == _StopUpdateMethod.driverApi) {
          await _updateVehicleStopsFromVehicleReporter();
        } else {
          _updateVehicleStopsFromManifest();
        }

        if (_nextStop == null) {
          _showMessage('No vehicle stops found.');
        }
      } on SessionInitializationException catch (e) {
        switch (e.code) {
          case SessionInitializationError.locationPermissionMissing:
            _showMessage(
              'No user location is available. Did you allow location permission?',
            );
          case SessionInitializationError.termsNotAccepted:
            _showMessage('Accept the terms and conditions dialog first.');
          case SessionInitializationError.notAuthorized:
            _showMessage(
              'Your API key is empty, invalid or not authorized to use Navigation.',
            );
        }
      }
    }
  }

  Future<void> _updateVehicleStopsFromVehicleReporter() async {
    final VehicleStopState prevState =
        _nextStop?.vehicleStopState ?? VehicleStopState.newStop;
    final List<VehicleStop> stops =
        await DeliveryDriver.vehicleReporter.getRemainingVehicleStops();
    _forceUpdateLocalStopState(prevState, stops);
    _updateStops(stops);
  }

  void _updateVehicleStopsFromManifest() {
    final List<VehicleStop> stops = getStopsFromLMFSManifest(_manifest);
    _updateStops(stops);
  }

  Future<void> _disposeDriver() async {
    if (await DeliveryDriver.isInitialized()) {
      if (_navigationRunning) {
        await _stopNavigation();
      }
      await DeliveryDriver.vehicleReporter.setLocationTrackingEnabled(false);

      await DeliveryDriver.dispose();
      setState(() {
        _driverInitialized = false;
      });
    }
  }

  void _setupListeners() {
    _clearListeners();
    _onArrivalSubscription = GoogleMapsNavigator.setOnArrivalListener(
      _onArrivalEvent,
    );
  }

  void _clearListeners() {
    _onArrivalSubscription?.cancel();
    _onArrivalSubscription = null;
  }

  void _onArrivalEvent(OnArrivalEvent event) {
    if (!mounted) {
      return;
    }

    if (event.waypoint.target != null) {
      _resetSimulatedLocation(event.waypoint.target);
    }
    debugPrint('Arrived to waypoint');
  }

  Future<void> _resetSimulatedLocation(
    LatLng? location, {
    bool stopSimulation = true,
  }) async {
    if (location != null) {
      if (stopSimulation) {
        await GoogleMapsNavigator.simulator.removeUserLocation();
      }
      await GoogleMapsNavigator.simulator.setUserLocation(location);
    }
  }

  Future<void> _startNavigation() async {
    if (_nextStop != null) {
      final NavigationWaypoint? waypoint = _nextStop!.waypoint;
      if (waypoint != null) {
        final Destinations msg = Destinations(
          waypoints: <NavigationWaypoint>[
            NavigationWaypoint.withLatLngTarget(
              title: waypoint.title.isNotEmpty ? waypoint.title : 'Waypoint',
              target: waypoint.target,
            ),
          ],
          displayOptions: NavigationDisplayOptions(
            showDestinationMarkers: false,
          ),
        );

        final NavigationRouteStatus status =
            await GoogleMapsNavigator.setDestinations(msg);

        if (status == NavigationRouteStatus.statusOk) {
          await GoogleMapsNavigator.startGuidance();
          await _navigationViewController.followMyLocation(
            CameraPerspective.tilted,
          );
          if (_simulationEnabled) {
            await _startSimulation();
          }
          setState(() {
            _navigationRunning = true;
          });
        }
      }
    }
  }

  void _updateStops(List<VehicleStop> vehicleStops) {
    setState(() {
      _vehicleStops = vehicleStops;
      _nextStop = _vehicleStops.isNotEmpty ? _vehicleStops.first : null;
    });
  }

  Future<void> _enrouteToNextStop() async {
    if (_stopUpdateMethod == _StopUpdateMethod.driverApi) {
      try {
        final List<VehicleStop> stops =
            await DeliveryDriver.vehicleReporter.enrouteToNextStop();
        _forceUpdateLocalStopState(VehicleStopState.enroute, stops);
        _updateStops(stops);
      } on DriverException catch (e) {
        _showMessage('Vehicle stop state change failed: ${e.message}');
      }
    } else {
      await _loadingWrapper(() async {
        _manifest = await updateLMFSStopState(
          _manifest,
          VehicleStopState.enroute,
        );
      });
      _updateVehicleStopsFromManifest();
    }
  }

  Future<void> _arrivedAtStop() async {
    if (_stopUpdateMethod == _StopUpdateMethod.driverApi) {
      try {
        final List<VehicleStop> stops =
            await DeliveryDriver.vehicleReporter.arrivedAtStop();
        _forceUpdateLocalStopState(VehicleStopState.arrived, stops);
        _updateStops(stops);
      } on DriverException catch (e) {
        _showMessage('Vehicle stop state change failed: ${e.message}');
      }
    } else {
      await _loadingWrapper(() async {
        _manifest = await updateLMFSStopState(
          _manifest,
          VehicleStopState.arrived,
        );
      });
      _updateVehicleStopsFromManifest();
    }
  }

  Future<void> _completedStop() async {
    if (_stopUpdateMethod == _StopUpdateMethod.driverApi) {
      try {
        final List<VehicleStop> stops =
            await DeliveryDriver.vehicleReporter.completedStop();
        _forceUpdateLocalStopState(VehicleStopState.newStop, stops);
        _updateStops(stops);
      } on DriverException catch (e) {
        _showMessage('Vehicle stop state change failed: ${e.message}');
      }
    } else {
      await _loadingWrapper(() async {
        _manifest = await completeFirstLMFSStop(_manifest);
      });
      _updateVehicleStopsFromManifest();
    }
  }

  String _vehicleStopStateToString(VehicleStopState state) {
    switch (state) {
      case VehicleStopState.stateUnspecified:
        return 'Unspecified';
      case VehicleStopState.newStop:
        return 'New stop';
      case VehicleStopState.enroute:
        return 'Enroute';
      case VehicleStopState.arrived:
        return 'Arrived';
    }
  }

  Future<void> _stopNavigation() async {
    if (_navigationRunning) {
      await GoogleMapsNavigator.stopGuidance();
      await _navigationViewController.setNavigationUIEnabled(false);
      await GoogleMapsNavigator.clearDestinations();

      setState(() {
        _navigationRunning = false;
      });
    }
  }

  Future<void> _startSimulation() async {
    await GoogleMapsNavigator.simulator
        .simulateLocationsAlongExistingRouteWithOptions(
          SimulationOptions(speedMultiplier: 5),
        );
  }

  Future<void> _pauseSimulation() async {
    await GoogleMapsNavigator.simulator.pauseSimulation();
  }

  Future<void> _setSupplementalLocation() async {
    final Location location = Location(
      latitude: _supplementalLocation.latitude,
      longitude: _supplementalLocation.longitude,
      accuracy: 1,
      time: DateTime.now().millisecondsSinceEpoch,
    );
    await DeliveryDriver.setSupplementalLocation(location);
    showOverlaySnackBar(
      'DeliveryDriver supplemental location set successfully',
    );
  }

  Future<void> _showDeliveryVehicle() async {
    final DeliveryVehicle vehicle =
        await DeliveryDriver.vehicleReporter.getDeliveryVehicle();
    showOverlaySnackBar('''
Delivery vehicle
Id: ${vehicle.id}
Name: ${vehicle.name}
Provider: ${vehicle.providerId}
Stops: ${vehicle.stops.length}''');
  }

  @override
  void dispose() {
    cleanupAll();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _showMessage(String message) {
    _hideMessage();

    final SnackBar snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(milliseconds: 2000),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _hideMessage() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
  }

  @override
  Widget build(BuildContext context) => buildPage(
    context,
    Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Expanded(
              child: GoogleMapsNavigationView(
                onViewCreated: (GoogleNavigationViewController controller) {
                  _navigationViewController = controller;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: <Widget>[
                  if (_driverInitialized)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          _nextStop != null
                              ? 'Stop state: ${_vehicleStopStateToString(_nextStop!.vehicleStopState)}\nStops remaining: ${_vehicleStops.length}'
                              : 'No planned vehicle stops',
                        ),
                      ),
                    ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      children: <Widget>[
                        if (!_driverInitialized)
                          ElevatedButton(
                            onPressed: _backendInitialized ? _initDriver : null,
                            child: const Text('Initialize driver'),
                          ),
                        if (!_driverInitialized && _backendInitialized)
                          ElevatedButton(
                            onPressed:
                                () => Clipboard.setData(
                                  ClipboardData(
                                    text: _manifest.vehicle.vehicleId,
                                  ),
                                ),
                            child: const Text('Copy vehicle ID'),
                          ),
                        if (_driverInitialized &&
                            _nextStop?.vehicleStopState ==
                                VehicleStopState.newStop)
                          ElevatedButton(
                            onPressed: () async {
                              await _enrouteToNextStop();
                              await _startNavigation();
                            },
                            child: const Text('Navigate to next stop'),
                          ),
                        if (_nextStop == null && _driverInitialized)
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Exit'),
                          ),
                        if (_driverInitialized &&
                            _nextStop?.vehicleStopState ==
                                VehicleStopState.enroute)
                          ElevatedButton(
                            onPressed: () async {
                              await _stopNavigation();
                              await _pauseSimulation();
                              await _arrivedAtStop();
                            },
                            child: const Text('Arrived at stop'),
                          ),
                        if (_driverInitialized &&
                            _nextStop?.vehicleStopState ==
                                VehicleStopState.arrived)
                          ElevatedButton(
                            onPressed: _completedStop,
                            child: const Text('Completed stop'),
                          ),
                      ],
                    ),
                  getOverlayOptionsButton(
                    context,
                    onPressed:
                        _backendInitialized ? () => toggleOverlay() : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget buildOverlayContent(BuildContext context) {
    return Column(
      children: <Widget>[
        Card(
          child: ExpansionTile(
            title: const Text('Driver initialization'),
            children: <Widget>[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                children: <Widget>[
                  ElevatedButton(
                    onPressed:
                        _driverInitialized ? _disposeDriver : _initDriver,
                    child: Text(
                      _driverInitialized
                          ? 'Dispose driver'
                          : 'Initialize driver',
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        () => Clipboard.setData(
                          ClipboardData(text: _manifest.vehicle.vehicleId),
                        ),
                    child: const Text('Copy vehicle ID'),
                  ),
                  ElevatedButton(
                    onPressed:
                        _driverInitialized
                            ? _navigationRunning
                                ? _stopNavigation
                                : _startNavigation
                            : null,
                    child: Text(
                      _navigationRunning
                          ? 'Stop navigation'
                          : 'Start navigation',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _driverInitialized ? _showDeliveryVehicle : null,
                    child: const Text('Show delivery vehicle'),
                  ),
                  SwitchListTile(
                    title: const Text('Simulation'),
                    value: _simulationEnabled,
                    onChanged: (bool value) async {
                      if (_navigationRunning) {
                        if (value) {
                          await _startSimulation();
                        } else {
                          await GoogleMapsNavigator.simulator
                              .removeUserLocation();
                        }
                      }

                      setState(() {
                        _simulationEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        IgnorePointer(
          ignoring: !_driverInitialized,
          child: Card(
            child: ExpansionTile(
              title: const Text('Vehicle stop handling'),
              children: <Widget>[
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  children: <Widget>[
                    ExampleDropdownButton<_StopUpdateMethod>(
                      title: 'Stop update method',
                      value: _stopUpdateMethod,
                      items: _StopUpdateMethod.values,
                      onChanged: (_StopUpdateMethod? newValue) {
                        setState(() {
                          _stopUpdateMethod = newValue!;
                        });
                      },
                    ),
                    ElevatedButton(
                      onPressed: _nextStop != null ? _enrouteToNextStop : null,
                      child: const Text('Enroute to stop'),
                    ),
                    ElevatedButton(
                      onPressed: _nextStop != null ? _arrivedAtStop : null,
                      child: const Text('Arrived at stop'),
                    ),
                    ElevatedButton(
                      onPressed:
                          _driverInitialized && _nextStop != null
                              ? _completedStop
                              : null,
                      child: const Text('Completed stop'),
                    ),
                    if (_stopUpdateMethod == _StopUpdateMethod.driverApi)
                      SwitchListTile(
                        title: const Text('Force local stop state on update'),
                        value: _forceLocalStopStateOnDriverApiUpdates,
                        onChanged: (bool value) async {
                          setState(() {
                            _forceLocalStopStateOnDriverApiUpdates = value;
                          });
                        },
                      ),
                    if (_stopUpdateMethod == _StopUpdateMethod.driverApi)
                      ElevatedButton(
                        onPressed: () async {
                          await _updateVehicleStopsFromVehicleReporter();
                        },
                        child: const Text('Update stops from vehicle reporter'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Card(
          child: ExpansionTile(
            title: const Text('Vehicle location reporting'),
            children: <Widget>[
              SwitchListTile(
                title: const Text('Location tracking'),
                value: _locationTrackingEnabled,
                onChanged: (bool value) async {
                  if (await DeliveryDriver.isInitialized()) {
                    await DeliveryDriver.vehicleReporter
                        .setLocationTrackingEnabled(value);
                  }
                  setState(() {
                    _locationTrackingEnabled = value;
                  });
                },
              ),
              ExampleSlider(
                unit: 's',
                title: 'Reporting interval',
                min: 5,
                max: 60,
                value: _locationReportingInterval?.inSeconds.toDouble() ?? 5,
                fractionDigits: 0,
                onChanged:
                    _locationTrackingEnabled
                        ? (double newValue) async {
                          _locationReportingInterval = Duration(
                            seconds: newValue.toInt(),
                          );
                          if (_driverInitialized) {
                            await DeliveryDriver.vehicleReporter
                                .setLocationReportingInterval(
                                  _locationReportingInterval!,
                                );
                            setState(() {
                              _locationReportingInterval =
                                  _locationReportingInterval;
                            });
                          }
                        }
                        : null,
              ),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            title: const Text('Supplemental location'),
            children: <Widget>[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                children: <Widget>[
                  ExampleLatLngEditor(
                    title: 'Coordinates',
                    initialLatLng: const LatLng(
                      latitude: 65.0,
                      longitude: 25.5,
                    ),
                    onChanged: (LatLng newTarget) {
                      _supplementalLocation = newTarget;
                    },
                  ),
                  ElevatedButton(
                    onPressed:
                        _driverInitialized ? _setSupplementalLocation : null,
                    child: const Text('Set supplemental location'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Current version of the driver API does not update the stop state properly,
  // this is a workaround to force the stop state to be updated locally.
  void _forceUpdateLocalStopState(
    VehicleStopState state,
    List<VehicleStop> stops,
  ) {
    if (_forceLocalStopStateOnDriverApiUpdates &&
        _stopUpdateMethod == _StopUpdateMethod.driverApi &&
        stops.isNotEmpty) {
      stops[0] = VehicleStop(
        vehicleStopState: state,
        waypoint: stops[0].waypoint,
        taskInfoList: stops[0].taskInfoList,
      );
    }
  }

  // Wrapper for calling backend API and handling loading state.
  Future<void> _loadingWrapper(Future<void> Function() apiCall) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await apiCall();
    } catch (e) {
      _showMessage('Error while loading: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

enum _StopUpdateMethod { backend, driverApi }
