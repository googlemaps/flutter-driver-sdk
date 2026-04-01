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
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_driver_flutter/google_driver_flutter.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import '../api/odrd.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';

/// Google Maps Driver ODRD demo page.
///
/// This demo page shows how to use the Google Maps Driver SDK plugin
/// with ODRD API.
class ODRDDriverPage extends ExamplePage {
  /// Creates a Google Maps Driver ODRD demo page.
  const ODRDDriverPage({super.key})
    : super(
        leading: const Icon(Icons.directions),
        title: 'Ridesharing Driver (ODRD)',
      );

  @override
  ExamplePageState<ODRDDriverPage> createState() => _DriverPageState();
}

class _ExampleTrip {
  _ExampleTrip(this.pickup, this.dropoff);

  final NavigationWaypoint pickup;
  final NavigationWaypoint dropoff;
}

final List<_ExampleTrip> _exampleTrips = <_ExampleTrip>[
  _ExampleTrip(
    NavigationWaypoint.withLatLngTarget(
      title: 'Kuusiluoto, Oulu',
      target: const LatLng(latitude: 65.0105737, longitude: 25.4564055),
    ),
    NavigationWaypoint.withLatLngTarget(
      title: 'Höyhtyä, Oulu',
      target: const LatLng(latitude: 64.9955575, longitude: 25.4865491),
    ),
  ),
  _ExampleTrip(
    NavigationWaypoint.withLatLngTarget(
      title: 'Valtatie, Oulu',
      target: const LatLng(latitude: 65.027869, longitude: 25.457963),
    ),
    NavigationWaypoint.withLatLngTarget(
      title: 'Hollihaka, Oulu',
      target: const LatLng(latitude: 65.007450, longitude: 25.449969),
    ),
  ),
  _ExampleTrip(
    NavigationWaypoint.withLatLngTarget(
      title: 'Tuira, Oulu',
      target: const LatLng(latitude: 65.0161051, longitude: 25.4983671),
    ),
    NavigationWaypoint.withLatLngTarget(
      title: 'Nokela, Oulu',
      target: const LatLng(latitude: 64.9904488, longitude: 25.4719577),
    ),
  ),
];

/// Driver demo page state.
class _DriverPageState extends ExamplePageState<ODRDDriverPage>
    with WidgetsBindingObserver {
  static const LatLng _startLocation = LatLng(
    latitude: 65.002822,
    longitude: 25.463639,
  );

  final Completer<GoogleNavigationViewController>
  _navigationControllerCompleter = Completer<GoogleNavigationViewController>();

  bool _backendInitialized = false;
  bool _driverInitialized = false;
  bool _navigationRunning = false;
  bool _simulationRunning = false;
  bool _navigatorInitialized = false;
  bool _locationTrackingEnabled = false;
  bool _showFleetEngineLocationOnMap = false;

  final double simulationSpeedMultiplier = 7;

  VehicleState _vehicleState = VehicleState.offline;
  // ignore: unused_field
  Duration? _locationReportingIntervalMillis;

  LatLng? _lastKnownDriverLocation;

  Timer? _tripUpdateTimer;
  Timer? _vehicleUpdateTimer;
  bool _tripMatched = false;
  bool _vehicleUpdated = false;

  // Start waypoint for this navigation example.
  final NavigationWaypoint startWaypoint = NavigationWaypoint.withLatLngTarget(
    title: 'Heinäpää, Oulu',
    target: _startLocation,
  );

  // Backend token repsonse object.
  TokenResponse? _tokenResponse;

  ODRDVehicle? _vehicle;
  ODRDTrip? _trip;
  ODRDTrip? _lastCreatedTrip;
  String? _selectedTripId;

  // List of waypoints for current vehicle.
  List<NavigationWaypoint> _waypoints = <NavigationWaypoint>[];
  // Waypoint index to be used to navigate through the waypoints one by one.
  int _waypointIndex = 0;

  // Current example trip index.
  int _exampleTripIndex = 0;

  // Marker used to show the fleet engine location.
  Marker? _fleetEngineLocationMarker;

  StreamSubscription<OnArrivalEvent>? _onArrivalSubscription;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadingWrapper(_checkPrerequisites);
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _checkPrerequisites({bool cleanup = true}) async {
    if (!await getODRDApi().backendIsRunning()) {
      _showMessage('Could not connect to the ODRD backend.');
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

    await _initializeNavigationSession();
    await _initODRDBackend();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // This example app does not have internal state handling for the app, to
    // keep the example simple, we just dispose the page when the app is paused.
    if (mounted &&
        state == AppLifecycleState.hidden &&
        Navigator.canPop(context)) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        cleanupAll();
      }
    }
  }

  // This method initializes the backend by creating a vehicle for example app
  // and starts polling the vehicle updates.
  //
  // Note: In production apps, it is recommended to handle vehicle creation and
  // state changes in a more secure way at the backend.
  Future<void> _initODRDBackend() async {
    // Create vehicle.
    _vehicle = await createODRDVehicle(
      vehicleId: 'ODRD_vehicle',
      supportedTripTypes: <ODRDTripType>[
        ODRDTripType.exclusive,
        ODRDTripType.shared,
      ],
    );

    debugPrint(
      'ODRD backend initialized.\nVehicle ID: ${_vehicle!.vehicleId}\nVehicle state: ${_vehicle!.vehicleState?.name}',
    );
    setState(() {
      _backendInitialized = true;
      _vehicleUpdated = true;
    });

    _pollVehicleUpdates();
  }

  Future<void> _createExampleTrip() async {
    // Create trip (this is normally done by the consumer app).
    final _ExampleTrip exampleTrip = _exampleTrips[_exampleTripIndex];
    await _loadingWrapper(() async {
      _lastCreatedTrip = await createODRDTrip(
        pickup: exampleTrip.pickup,
        dropoff: exampleTrip.dropoff,
      );
    });
    debugPrint('ODRD backend Trip ID: ${_lastCreatedTrip!.tripId}');
    setState(() {
      _vehicleUpdated = false;
      _trip = _lastCreatedTrip;
      _exampleTripIndex = (_exampleTripIndex + 1) % _exampleTrips.length;
    });
    _pollTripUpdates();
  }

  Future<void> _selectTrip(String tripId) async {
    _stopPollingVehicleUpdates();
    _stopPollingTripUpdates();
    _selectedTripId = tripId;
    _trip = await getODRDApi().getTrip(_selectedTripId!);
    debugPrint('ODRD backend Trip ID: ${_trip!.tripId}');

    if (_vehicle?.waypoints != null) {
      _waypoints = _vehicle!.waypoints!
          .asMap()
          .entries
          .map(
            (MapEntry<int, ODRDWaypoint> waypointEntry) =>
                NavigationWaypoint.withLatLngTarget(
                  target: waypointEntry.value.location,
                  title: 'Waypoint ${waypointEntry.key + 1}',
                ),
          )
          .toList();
    }
    await _initNavigation();
    _pollVehicleUpdates();
    _pollTripUpdates();
    setState(() {
      _waypointIndex = 0;
    });
  }

  Future<void> _initializeDriver() async {
    assert(_vehicle != null, 'vehicle is required');
    if (!await RidesharingDriver.isInitialized()) {
      try {
        // Navigation session must be initialized before Driver API is used.
        await _initializeNavigationSession();
        await GoogleMapsNavigator.simulator.setUserLocation(_startLocation);

        // Initialize Ridesharing Driver SDK.
        await RidesharingDriver.initialize(
          providerId: getProjectId(),
          vehicleId: _vehicle!.vehicleId,
          onGetToken: (AuthTokenContext context) async {
            if (_tokenResponse == null ||
                DateTime.now().millisecondsSinceEpoch >
                    _tokenResponse!.expirationTimestampMs) {
              _tokenResponse = await getODRDApi().getToken(
                ODRDTokenType.driver,
                _vehicle!.vehicleId,
              );
            }
            if (_tokenResponse == null || _tokenResponse!.token.isEmpty) {
              throw Exception('Token retrieval from the backend failed.');
            }

            return Future<String>.value(_tokenResponse!.token);
          },
          onStatusUpdate: Platform.isAndroid
              ? (
                  DriverStatusLevel level,
                  DriverStatusCode code,
                  String message,
                  DriverException? exception,
                ) {
                  debugPrint(
                    'Driver status changed: $level - $code - $message, e: ${exception?.code} ${exception?.message}',
                  );
                }
              : null,
        );

        if (Platform.isIOS) {
          RidesharingDriver.vehicleReporter.setListener(
            VehicleReporterListener(
              onDidSucceed: (VehicleUpdate vehicleUpdate) {
                debugPrint(
                  'Vehicle update succeeded - location (${vehicleUpdate.location?.latitude.toStringAsFixed(3) ?? '-'}, ${vehicleUpdate.location?.longitude.toStringAsFixed(3) ?? '-'}) and state: ${vehicleUpdate.vehicleState == VehicleState.online ? 'online' : 'offline'}',
                );
              },
              onDidFail: (VehicleUpdate vehicleUpdate, DriverException exception) {
                debugPrint(
                  'Vehicle updated failed - location (${vehicleUpdate.location?.latitude.toStringAsFixed(3) ?? '-'}, ${vehicleUpdate.location?.longitude.toStringAsFixed(3) ?? '-'}) state: ${vehicleUpdate.vehicleState == VehicleState.online ? 'online' : 'offline'}',
                );
                debugPrint('  Error ${exception.message}');
              },
            ),
          );
        }

        // Fetch the current locationReportintInterval
        await RidesharingDriver.vehicleReporter.setLocationReportingInterval(
          const Duration(seconds: 5),
        );
        _locationReportingIntervalMillis = await RidesharingDriver
            .vehicleReporter
            .getLocationReportingInterval();
        if (!_locationTrackingEnabled) {
          await _setLocationTrackingEnabled(true);
        }
        if (_vehicleState != VehicleState.online) {
          await _setVehicleState(VehicleState.online);
        }

        setState(() {
          _driverInitialized = true;
        });
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

  /// Starts the polling of trip information with retries.
  ///
  /// [tripId] is the ID of the trip to fetch.
  void _pollTripUpdates() {
    assert(_trip != null && _trip!.tripId.isNotEmpty, 'tripId is required');
    _stopPollingTripUpdates();
    _tripUpdateTimer = Timer.periodic(const Duration(seconds: 5), (
      Timer timer,
    ) async {
      try {
        if (_trip == null) {
          _stopPollingTripUpdates();
          return;
        }
        _trip = await getODRDApi().getTrip(_selectedTripId ?? _trip!.tripId);
        debugPrint(
          ' - Trip (${_trip!.tripId}) status: ${_trip!.tripStatus.name}',
        );
        bool tripMatched = false;
        if (_trip!.vehicleId.isNotEmpty && !_tripMatched) {
          debugPrint(' - Trip has matched vehicle: ${_trip!.vehicleId}');

          tripMatched = true;
        }
        setState(() {
          _tripMatched = tripMatched;
        });
      } catch (e) {
        debugPrint('- Error fetching trip: $e');
      }
    });
  }

  void _stopPollingTripUpdates() {
    _tripUpdateTimer?.cancel();
    _tripUpdateTimer = null;
  }

  /// Starts the polling of trip information with retries.
  ///
  /// [tripId] is the ID of the trip to fetch.
  void _pollVehicleUpdates() {
    assert(_vehicle != null, 'vehicle is required');
    _stopPollingVehicleUpdates();
    _vehicleUpdateTimer = Timer.periodic(
      _locationReportingIntervalMillis ?? const Duration(seconds: 5),
      (Timer timer) async {
        try {
          final ODRDVehicle vehicle = await getODRDApi().getVehicle(
            _vehicle!.vehicleId,
          );
          debugPrint(
            ' - Vehicle (${vehicle.vehicleId}) state: ${vehicle.vehicleState?.name}, vehicle trips: ${vehicle.currentTripsIds}, vehicle waypoints: ${vehicle.waypoints}, last location ${vehicle.lastLocation?.latitude},${vehicle.lastLocation?.longitude}',
          );

          if (_simulationRunning && vehicle.lastLocation != null) {
            _lastKnownDriverLocation = vehicle.lastLocation;
          }

          _vehicleState = vehicle.vehicleState == ODRDVehicleState.online
              ? VehicleState.online
              : VehicleState.offline;

          setState(() {
            _vehicleUpdated = true;
            _vehicle = vehicle;
          });

          await _updateFleetEngineLocationMarker(
            show: _showFleetEngineLocationOnMap,
          );
        } catch (e) {
          debugPrint(' - Error fetching vehicle: $e');
        }
      },
    );
  }

  void _stopPollingVehicleUpdates() {
    _vehicleUpdateTimer?.cancel();
  }

  // Fetches all vehicles from the backend and prints them to the console.
  Future<void> _fetchVehicles() async {
    final List<ODRDVehicle> allVehicles = await getODRDApi().getVehicles();
    allVehicles.map((ODRDVehicle vehicle) {
      debugPrint(
        'Vehicle: ${vehicle.vehicleId}, Vehicle state: ${vehicle.vehicleState?.name}, Vehicle trips: ${vehicle.currentTripsIds}',
      );
    }).toList();
  }

  Future<void> _updateTripStatus(ODRDTripStatus status) async {
    // Update trip. This can be called only after the trip has vehicle assigned.
    // Otherwise it will fail.
    if (_trip != null && _trip!.vehicleId.isNotEmpty) {
      try {
        _trip = await updateODRDTrip(
          tripId: _trip!.tripId,
          update: ODRDTripUpdate(tripStatus: status),
        );

        if (status.name.contains('enroute')) {
          if (_waypointIndex > 0 && _navigationRunning) {
            // After arriving to waypoint, continue to next destination.
            // ignore: deprecated_member_use
            await GoogleMapsNavigator.continueToNextDestination();
          }
          // Simulate the user location to the next waypoint.
          await _startSimulationToNextWaypoint();
        } else if (status == ODRDTripStatus.complete ||
            status == ODRDTripStatus.canceled) {
          // Stop navigation when trip is complete or canceled.
          await _stopNavigation();
        }
        debugPrint('Trip updated: ${_trip!.tripStatus}');
      } catch (e) {
        debugPrint('Failed to update trip: $e');
      }
    }
  }

  Future<void> _setVehicleState(VehicleState state) async {
    await RidesharingDriver.vehicleReporter.setVehicleState(state);
    setState(() {
      _vehicleState = state;
    });
  }

  Future<void> _setLocationTrackingEnabled(bool enabled) async {
    await RidesharingDriver.vehicleReporter.setLocationTrackingEnabled(enabled);
    setState(() {
      _locationTrackingEnabled = enabled;
    });
  }

  Future<void> _disposeDriver() async {
    if (await RidesharingDriver.isInitialized()) {
      if (_navigationRunning) {
        await _stopNavigation();
      }

      await RidesharingDriver.dispose();
      if (mounted) {
        setState(() {
          _driverInitialized = false;
          _selectedTripId = null;
          _vehicleUpdated = false;
        });
      }
    }
  }

  // ignore: unused_element
  Future<void> _initNavigation() async {
    if (_waypoints.isNotEmpty) {
      await _initializeNavigationSession();

      final Destinations msg = Destinations(
        waypoints: _waypoints,
        displayOptions: NavigationDisplayOptions(showDestinationMarkers: false),
      );

      final NavigationRouteStatus status =
          await GoogleMapsNavigator.setDestinations(msg);

      if (status == NavigationRouteStatus.statusOk) {
        await GoogleMapsNavigator.startGuidance();
        await _followMyLocation(CameraPerspective.tilted);

        setState(() {
          _navigationRunning = true;
        });
      }
    }
  }

  Future<void> _followMyLocation(CameraPerspective cameraPerspective) async {
    final GoogleNavigationViewController viewController =
        await _navigationControllerCompleter.future;
    await viewController.followMyLocation(cameraPerspective);
  }

  Future<void> _initializeNavigationSession() async {
    if (!_navigatorInitialized) {
      if (!await GoogleMapsNavigator.areTermsAccepted()) {
        await GoogleMapsNavigator.showTermsAndConditionsDialog(
          'test_title',
          'test_company_name',
        );
      }
      await GoogleMapsNavigator.initializeNavigationSession();
      _setupListeners();
      await _followMyLocation(CameraPerspective.tilted);

      setState(() {
        _navigatorInitialized = true;
      });
    }
  }

  Future<void> _stopNavigation() async {
    if (_navigationRunning) {
      // Stop simulation by removing re-setting user location.
      await _resetSimulatedLocation(_lastKnownDriverLocation);

      // Clears the destinations and stops the navigation.
      await GoogleMapsNavigator.clearDestinations();

      if (mounted) {
        setState(() {
          _navigationRunning = false;
          _selectedTripId = null;
          _waypoints = <NavigationWaypoint>[];
          _waypointIndex = 0;
        });
      }
    }
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
    setState(() {
      _simulationRunning = false;
    });
  }

  Future<void> _startSimulationToNextWaypoint() async {
    if (_waypoints.length > _waypointIndex) {
      // Reset simulated user location. If navigation is running, this will use the
      // last location from the fleet engine.
      await GoogleMapsNavigator.simulator.setUserLocation(
        _lastKnownDriverLocation ?? _startLocation,
      );
      await GoogleMapsNavigator.simulator
          .simulateLocationsAlongNewRouteWithRoutingAndSimulationOptions(
            <NavigationWaypoint>[_waypoints[_waypointIndex]],
            RoutingOptions(),
            SimulationOptions(speedMultiplier: simulationSpeedMultiplier),
          );
      setState(() {
        _waypointIndex = _waypointIndex + 1;
        _simulationRunning = true;
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
      _lastKnownDriverLocation = event.waypoint.target;
    }
    debugPrint('Arrived to waypoint');
    _resetSimulatedLocation(_lastKnownDriverLocation);
    setState(() {
      _simulationRunning = false;
    });
  }

  @override
  void dispose() {
    _stopPollingTripUpdates();
    _stopPollingVehicleUpdates();
    _clearListeners();
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
  Widget build(BuildContext context) {
    final String tripState = _trip?.vehicleId != null
        ? 'Trip state: ${_getTripStatusText(_trip?.tripStatus)}'
        : 'No trip';
    final String vehicleState = _trip?.vehicleId != null
        ? 'Assigned vehicle ID: ${_trip?.vehicleId}'
        : 'No assigned vehicle';
    return buildPage(
      context,
      Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Expanded(
                child: GoogleMapsNavigationView(
                  onViewCreated: (GoogleNavigationViewController controller) {
                    _navigationControllerCompleter.complete(controller);
                  },
                  initialCameraPosition: const CameraPosition(
                    target: _startLocation,
                    zoom: 14,
                  ),
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
                          child: Text('$tripState\n$vehicleState'),
                        ),
                      ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(6),
                        child: CircularProgressIndicator(),
                      )
                    else
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        children: <Widget>[
                          if (!_driverInitialized)
                            ElevatedButton(
                              onPressed: _initializeDriver,
                              child: const Text('Initialize driver'),
                            ),
                          if (_driverInitialized && !_locationTrackingEnabled)
                            ElevatedButton(
                              onPressed: () =>
                                  _setLocationTrackingEnabled(true),
                              child: const Text('Enable location tracking'),
                            ),
                          if (_driverInitialized &&
                              _locationTrackingEnabled &&
                              _vehicleState == VehicleState.offline)
                            ElevatedButton(
                              onPressed: () =>
                                  _setVehicleState(VehicleState.online),
                              child: const Text('Set vehicle online'),
                            ),
                          if (_driverInitialized &&
                              !_hasTrips &&
                              _vehicleUpdated)
                            ElevatedButton(
                              onPressed: _createExampleTrip,
                              child: const Text(
                                'Create new trip (as consumer)',
                              ),
                            ),
                          if (_canSelectNewTrip)
                            for (final MapEntry<int, String> entry
                                in _vehicle!.currentTripsIds!.asMap().entries)
                              ElevatedButton(
                                onPressed: () => _selectTrip(entry.value),
                                child: Text('Start trip ${entry.key + 1}'),
                              ),
                          if (_hasTrips &&
                              _hasSelectedTrip &&
                              _trip?.tripId == _selectedTripId)
                            _buildRouteActionButtons(),
                        ],
                      ),
                    getOverlayOptionsButton(
                      context,
                      onPressed: _backendInitialized
                          ? () => toggleOverlay()
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _hasVehicle => _vehicle != null;
  bool get _hasSelectedTrip => _selectedTripId?.isNotEmpty ?? false;
  bool get _hasTrips =>
      _hasVehicle && (_vehicle!.currentTripsIds?.isNotEmpty ?? false);
  bool get _canSelectNewTrip =>
      _hasTrips &&
      (!_hasSelectedTrip ||
          !_vehicle!.currentTripsIds!.contains(_selectedTripId));

  @override
  Widget buildOverlayContent(BuildContext context) {
    return Column(
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          children: <Widget>[
            SwitchListTile(
              title: const Text('Location tracking'),
              value: _locationTrackingEnabled,
              onChanged: (bool value) async {
                if (await RidesharingDriver.isInitialized()) {
                  await RidesharingDriver.vehicleReporter
                      .setLocationTrackingEnabled(value);
                }
                setState(() {
                  _locationTrackingEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Vehicle online'),
              value: _vehicleState == VehicleState.online,
              onChanged: _locationTrackingEnabled
                  ? (bool value) async {
                      final VehicleState newState = value
                          ? VehicleState.online
                          : VehicleState.offline;
                      await _setVehicleState(newState);
                      setState(() {
                        _vehicleState = newState;
                      });
                    }
                  : null,
            ),
            SwitchListTile(
              title: const Text('Show fleet engine location marker'),
              value: _showFleetEngineLocationOnMap,
              onChanged: (bool value) async {
                await _updateFleetEngineLocationMarker(show: value);
              },
            ),
            ElevatedButton(
              onPressed: _driverInitialized
                  ? _disposeDriver
                  : _initializeDriver,
              child: Text(
                _driverInitialized ? 'Dispose driver' : 'Initialize driver',
              ),
            ),
            ElevatedButton(
              onPressed: _fetchVehicles,
              child: const Text('Debug print all vehicles'),
            ),
          ],
        ),
      ],
    );
  }

  Wrap _buildRouteActionButtons() {
    assert(_trip != null, 'trip is required');
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      children: <Widget>[
        if (_trip!.tripStatus == ODRDTripStatus.newTrip)
          _buildTripStatusButton(ODRDTripStatus.enrouteToPickup),
        if (_trip!.tripStatus == ODRDTripStatus.enrouteToPickup)
          _buildTripStatusButton(ODRDTripStatus.arrivedAtPickup),
        if (_trip!.tripStatus == ODRDTripStatus.arrivedAtPickup)
          _buildTripStatusButton(ODRDTripStatus.enrouteToDropoff),
        if (_trip!.tripStatus == ODRDTripStatus.enrouteToDropoff)
          _buildTripStatusButton(ODRDTripStatus.complete),
        if (_trip!.tripStatus != ODRDTripStatus.complete &&
            _trip!.tripStatus != ODRDTripStatus.canceled)
          _buildTripStatusButton(ODRDTripStatus.canceled),
      ],
    );
  }

  ElevatedButton _buildTripStatusButton(ODRDTripStatus status) {
    return ElevatedButton(
      onPressed: () => _updateTripStatus(status),
      child: Text(_getTripStatusText(status)),
    );
  }

  String _getTripStatusText(ODRDTripStatus? status) {
    if (status == null) {
      return 'Unknown';
    }
    switch (status) {
      case ODRDTripStatus.newTrip:
        return 'New trip';
      case ODRDTripStatus.enrouteToPickup:
        return 'Enroute to pickup';
      case ODRDTripStatus.arrivedAtPickup:
        return 'Arrived at pickup';
      case ODRDTripStatus.enrouteToDropoff:
        return 'Enroute to dropoff';
      case ODRDTripStatus.complete:
        return 'Complete trip';
      case ODRDTripStatus.canceled:
        return 'Cancel trip';
      case ODRDTripStatus.enrouteToIntermediateDestination:
        return 'Enroute to intermediate destination';
      case ODRDTripStatus.arrivedAtIntermediateDestination:
        return 'Arrived at intermediate destination';
      case ODRDTripStatus.unknownTripStatus:
        return 'Unknown trip status';
    }
  }

  Future<void> _updateFleetEngineLocationMarker({bool show = false}) async {
    final GoogleNavigationViewController viewController =
        await _navigationControllerCompleter.future;
    if (show) {
      final MarkerOptions options = MarkerOptions(
        position: _lastKnownDriverLocation ?? _startLocation,
        infoWindow: const InfoWindow(title: 'Fleet engine location'),
      );

      if (_fleetEngineLocationMarker != null) {
        final Marker updatedMarker = _fleetEngineLocationMarker!.copyWith(
          options: options,
        );
        _fleetEngineLocationMarker = (await viewController.updateMarkers(
          <Marker>[updatedMarker],
        )).firstOrNull;
      } else {
        _fleetEngineLocationMarker = (await viewController.addMarkers(
          <MarkerOptions>[options],
        )).firstOrNull;
      }
    } else {
      if (_fleetEngineLocationMarker != null) {
        await viewController.removeMarkers(<Marker>[
          _fleetEngineLocationMarker!,
        ]);
        setState(() {
          _fleetEngineLocationMarker = null;
        });
      }
    }

    if (_showFleetEngineLocationOnMap != show) {
      setState(() {
        _showFleetEngineLocationOnMap = show;
      });
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
