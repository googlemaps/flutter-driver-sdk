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

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_driver_flutter/google_driver_flutter.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api/lmfs.dart';
import 'api/odrd.dart';
import 'pages/pages.dart';
import 'utils/cleanup.dart';
import 'widgets/widgets.dart';

final List<ExamplePage> _allPages = <ExamplePage>[
  const LMFSDriverPage(),
  const ODRDDriverPage(),
];

class DriverDemo extends StatelessWidget {
  const DriverDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const DriverBody();
  }
}

class DriverBody extends StatefulWidget {
  const DriverBody({super.key});
  @override
  State<StatefulWidget> createState() => _DriverDemoState();
}

class _DriverDemoState extends State<DriverBody> with WidgetsBindingObserver {
  _DriverDemoState();

  bool _lmfsBackendRunning = false;
  bool _odrdBackendRunning = false;

  bool _locationPermitted = false;
  bool _notificationsPermitted = false;

  String _driverSDKVersion = '';
  String _navSDKVersion = 'Unknown version';
  Timer? _backendStatusPollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions();
    _checkBackendServicesStatus();
    _checkSDKVersions();
    _startBackendStatusPolling();
  }

  @override
  void dispose() {
    _stopBackendStatusPolling();
    cleanupAll();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkBackendServicesStatus();
      _startBackendStatusPolling();
    } else if (state == AppLifecycleState.paused) {
      _stopBackendStatusPolling();
    }
  }

  Future<void> _checkSDKVersions() async {
    // Get the Driver SDK version.
    _driverSDKVersion = await DeliveryDriver.getDriverSdkVersion();
    // Get the Navigation SDK version.
    _navSDKVersion = await GoogleMapsNavigator.getNavSDKVersion();
  }

  Future<void> _pushPage(BuildContext context, ExamplePage page) async {
    if (!_isBackendRunning(page)) {
      String backendName = '';
      if (page is LMFSDriverPage) {
        backendName = 'LMFS';
      } else if (page is ODRDDriverPage) {
        backendName = 'ODRD';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$backendName backend is not running\n'
            'Read the README.md file for instructions on '
            'how to start the backend services.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  bool _isBackendRunning(ExamplePage page) {
    if (page is LMFSDriverPage) {
      return _lmfsBackendRunning;
    } else if (page is ODRDDriverPage) {
      return _odrdBackendRunning;
    } else {
      return _lmfsBackendRunning && _odrdBackendRunning;
    }
  }

  void _startBackendStatusPolling() {
    _backendStatusPollingTimer = Timer.periodic(const Duration(seconds: 5), (
      Timer timer,
    ) {
      _checkBackendServicesStatus();
    });
  }

  void _stopBackendStatusPolling() {
    _backendStatusPollingTimer?.cancel();
  }

  /// Request permission for accessing the device's location and notifications.
  ///
  /// Android: Fine and Coarse Location
  /// iOS: CoreLocation (Always and WhenInUse), Notification
  Future<void> _requestPermissions() async {
    final PermissionStatus locationPermission = await Permission.location
        .request();

    PermissionStatus notificationPermission = PermissionStatus.denied;
    if (Platform.isIOS) {
      notificationPermission = await Permission.notification.request();
    }
    setState(() {
      _locationPermitted = locationPermission == PermissionStatus.granted;
      _notificationsPermitted =
          notificationPermission == PermissionStatus.granted;
    });
  }

  /// Check if the backend services are running.
  Future<void> _checkBackendServicesStatus() async {
    _lmfsBackendRunning = await getLMFSApi().backendIsRunning();
    _odrdBackendRunning = await getODRDApi().backendIsRunning();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String buildPermissionsStatus() => (Platform.isIOS
        ? 'Location ${_locationPermitted ? 'granted' : 'denied'} • Notifications ${_notificationsPermitted ? 'granted' : 'denied'}'
        : 'Location ${_locationPermitted ? 'granted' : 'denied'} ');

    return Scaffold(
      appBar: AppBar(title: const Text('Google Maps Driver examples')),
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: _allPages.length + 1,
          itemBuilder: (_, int index) {
            if (index == 0) {
              return Card(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  alignment: Alignment.center,
                  child: Text(
                    '${buildPermissionsStatus()}\n'
                    'Driver SDK version: $_driverSDKVersion\n'
                    'Navigation SDK version: $_navSDKVersion',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final ExamplePage page = _allPages[index - 1];
            return ListTile(
              leading: page.leading,
              title: Text(page.title),
              trailing: Icon(
                _isBackendRunning(page) ? Icons.check_circle : Icons.error,
                color: _isBackendRunning(page) ? Colors.green : Colors.red,
              ),
              onTap: () => _pushPage(context, page),
            );
          },
        ),
      ),
    );
  }
}

void main() {
  final ElevatedButtonThemeData exampleButtonDefaultTheme =
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(minimumSize: const Size(160, 36)),
      );
  runApp(
    MaterialApp(
      home: const DriverDemo(),
      theme: ThemeData.light().copyWith(
        elevatedButtonTheme: exampleButtonDefaultTheme,
      ),
      darkTheme: ThemeData.dark().copyWith(
        elevatedButtonTheme: exampleButtonDefaultTheme,
      ),
    ),
  );
}
