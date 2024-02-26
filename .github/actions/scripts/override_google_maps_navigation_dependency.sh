#!/bin/bash
# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script creates or updates a pubspec_overrides.yaml file in the given directory with a google_maps_navigation override.
# Usage: ./override_google_maps_navigation_dependency.sh <path_to_directory> <google_maps_navigation override>

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <path_to_directory> <google_maps_navigation override>"
  exit 1
fi

dirpath="$1"
override="${@:2}"
overrides_file="${dirpath%/}/pubspec_overrides.yaml"

if [ -z "$override" ]; then
  echo "No override supplied"
  exit 1
fi

if [ ! -f "$overrides_file" ]; then
  touch "$overrides_file"
fi

# Check if override already exists
if grep -q "dependency_overrides:" "$overrides_file"; then
  echo "dependency_overrides already exists in $overrides_file"
else
  echo "Adding dependency_overrides to $overrides_file"
  {
    echo -e "\n\ndependency_overrides:"
    echo "  google_maps_navigation:"
    echo -e "    $override\n"
  } >> "$overrides_file"
fi
