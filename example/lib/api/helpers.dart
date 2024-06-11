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

import 'dart:math';

/// Read the environment variables given to the app at build time as
/// dart defines. If the environment variable is not defined, use the
/// default value.
/// See ./tools/backend/docker-compose.yml for the values of these environment
/// variables.
const String _projectId = String.fromEnvironment('PROJECT_ID');

/// Check if project ID / provider ID has been defined.
bool hasProjectId() {
  return _projectId.isNotEmpty;
}

/// Returns the project ID / provider ID.
String getProjectId() {
  assert(_projectId.isNotEmpty, 'PROJECT_ID dart define is not set.');
  return _projectId;
}

String _clientId = 'google_driver_flutter_demo_${generateRandomString(4)}';

/// Returns the client ID.
String getClientId() {
  return _clientId;
}

/// Generates a random string of [length] using letters and digits.
String generateRandomString(int length) {
  const String characters =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final Random random = Random();

  return String.fromCharCodes(Iterable<int>.generate(
    length,
    (_) => characters.codeUnitAt(random.nextInt(characters.length)),
  ));
}
