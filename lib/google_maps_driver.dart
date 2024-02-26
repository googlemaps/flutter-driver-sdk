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

/// A flutter library for interacting with the Google Maps Driver SDK.
///
/// The Driver SDK for flutter is a library that you integrate into your
/// driver app. It is responsible for updating the Fleet Engine with the
/// driver’s location, route, distance remaining, and ETA.
/// It also integrates with the Navigation SDK, which provides turn-by-turn
/// navigation instructions for the driver.
///
/// This library provides support for two types of drivers:
///  - [Delivery Driver](../topics/Delivery%20Driver-topic.html) (LMFS)
///  - [RideSharing Driver](../topics/RideSharing%20Driver-topic.html) (ODRD)
library google_maps_driver;

export 'src/google_maps_driver.dart';
export 'src/types/types.dart';
