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

import 'package:flutter_test/flutter_test.dart';
import 'package:google_driver_flutter/google_driver_flutter.dart';
import 'package:google_driver_flutter/src/method_channel/method_channel.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'google_driver_flutter_test.mocks.dart';
import 'messages_test.g.dart';

@GenerateMocks(<Type>[
  TestCommonDriverApi,
  TestDeliveryDriverApi,
  TestRidesharingDriverApi,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTestCommonDriverApi mockedCommonDriverApi;
  setUp(() {
    mockedCommonDriverApi = MockTestCommonDriverApi();
    TestCommonDriverApi.setUp(mockedCommonDriverApi);
  });

  for (final DriverApiType driverApiType in <DriverApiType>[
    DriverApiType.delivery,
    DriverApiType.ridesharing
  ]) {
    group('Common API $driverApiType', () {
      const String providerIdIn = 'Foo';
      const String vehicleIdIn = 'vehicle_1';

      late TypedCommonDriverApi publicCommonDriverApi;
      late MockTestDeliveryDriverApi mockedDeliveryDriverApi;
      late MockTestRidesharingDriverApi mockedRidesharingDriverApi;
      late CommonVehicleReporter vehicleReporter;

      setUp(() {
        if (driverApiType == DriverApiType.delivery) {
          publicCommonDriverApi = DeliveryDriver.commonDriverApi;
          mockedDeliveryDriverApi = MockTestDeliveryDriverApi();
          vehicleReporter = DeliveryDriver.vehicleReporter;
          TestDeliveryDriverApi.setUp(mockedDeliveryDriverApi);
        } else if (driverApiType == DriverApiType.ridesharing) {
          publicCommonDriverApi = RidesharingDriver.commonDriverApi;
          mockedRidesharingDriverApi = MockTestRidesharingDriverApi();
          vehicleReporter = RidesharingDriver.vehicleReporter;
          TestRidesharingDriverApi.setUp(mockedRidesharingDriverApi);
        } else {
          assert(false, 'Unknown driverApiType: $driverApiType');
        }
      });

      test('initialize', () async {
        await publicCommonDriverApi.initialize(
            providerId: providerIdIn,
            vehicleId: vehicleIdIn,
            onGetToken: (AuthTokenContext context) => Future<String>.value(''),
            abnormalTerminationReportingEnabled: true);

        // initialize.
        final VerificationResult result = verify(mockedCommonDriverApi
            .initialize(captureAny, captureAny, captureAny, captureAny));
        final String providerIdOut = result.captured[1] as String;
        final String vehicleIdOut = result.captured[2] as String;
        final bool abnormalTerminationReportingEnabledOut =
            result.captured[3] as bool;

        expectDriverApiType(driverApiType, result);
        expect(providerIdIn, providerIdOut);
        expect(vehicleIdIn, vehicleIdOut);
        expect(abnormalTerminationReportingEnabledOut, true);
      });
      test('getProviderId', () async {
        // getProviderId.
        when(mockedCommonDriverApi.getProviderId(any))
            .thenAnswer((Invocation _) => providerIdIn);
        final String providerIdOut =
            await publicCommonDriverApi.getProviderId();
        final VerificationResult result =
            verify(mockedCommonDriverApi.getProviderId(captureAny));
        expectDriverApiType(driverApiType, result);
        expect(providerIdIn, providerIdOut);
      });
      test('getVehicleId', () async {
        // getVehicleId.
        when(mockedCommonDriverApi.getVehicleId(any))
            .thenAnswer((Invocation _) => vehicleIdIn);
        final String vehicleIdOut = await publicCommonDriverApi.getVehicleId();
        final VerificationResult result =
            verify(mockedCommonDriverApi.getVehicleId(captureAny));
        expectDriverApiType(driverApiType, result);
        expect(vehicleIdIn, vehicleIdOut);
      });
      test('getDriverSdkVersion', () async {
        // getDriverSdkVersion.
        const String sdkVersionIn = '1.0.0';
        when(mockedCommonDriverApi.getDriverSdkVersion(any))
            .thenAnswer((Invocation _) => sdkVersionIn);
        final String sdkVersionOut =
            await publicCommonDriverApi.getDriverSdkVersion();
        final VerificationResult result =
            verify(mockedCommonDriverApi.getDriverSdkVersion(captureAny));
        expectDriverApiType(driverApiType, result);
        expect(sdkVersionOut, sdkVersionIn);
      });
      test('setLocationTrackingEnabled', () async {
        await vehicleReporter.setLocationTrackingEnabled(true);
        final VerificationResult result = verify(mockedCommonDriverApi
            .setLocationTrackingEnabled(captureAny, captureAny));
        expectDriverApiType(driverApiType, result);
        expect(result.captured[1] as bool, true);
      });
      test('setLocationTrackingEnabled', () async {
        await vehicleReporter.setLocationTrackingEnabled(false);
        final VerificationResult result = verify(mockedCommonDriverApi
            .setLocationTrackingEnabled(captureAny, captureAny));
        expectDriverApiType(driverApiType, result);
        expect(result.captured[1] as bool, false);
      });
      test('isLocationTrackingEnabled', () async {
        when(mockedCommonDriverApi.isLocationTrackingEnabled(any))
            .thenAnswer((Invocation _) => true);
        await vehicleReporter.isLocationTrackingEnabled();
        final VerificationResult result =
            verify(mockedCommonDriverApi.isLocationTrackingEnabled(captureAny));
        expectDriverApiType(driverApiType, result);
      });
      test('setLocationReportingInterval', () async {
        const int reportingIntervalIn = 12000;
        await vehicleReporter.setLocationReportingInterval(
            const Duration(milliseconds: reportingIntervalIn));
        final VerificationResult result = verify(mockedCommonDriverApi
            .setLocationReportingIntervalMillis(captureAny, captureAny));
        expectDriverApiType(driverApiType, result);
        expect(result.captured[1] as int, reportingIntervalIn);
      });
      test('getLocationReportingInterval', () async {
        const int reportingIntervalIn = 12000;
        when(mockedCommonDriverApi.getLocationReportingIntervalMillis(any))
            .thenAnswer((Invocation _) => reportingIntervalIn);
        final Duration reportingIntervalOut =
            await vehicleReporter.getLocationReportingInterval();
        final VerificationResult result = verify(mockedCommonDriverApi
            .getLocationReportingIntervalMillis(captureAny));
        expectDriverApiType(driverApiType, result);
        expect(reportingIntervalIn, reportingIntervalOut.inMilliseconds);
      });
      test('dispose', () async {
        await publicCommonDriverApi.dispose();
        final VerificationResult result =
            verify(mockedCommonDriverApi.dispose(captureAny));
        expectDriverApiType(driverApiType, result);
      });
    });
  }
}

void expectDriverApiType(
    DriverApiType driverApiType, VerificationResult result) {
  expect(driverApiType.toDto(), result.captured[0] as DriverApiTypeDto);
}
