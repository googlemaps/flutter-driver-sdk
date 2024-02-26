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

# Use an appropriate Java base image
FROM openjdk:11

# Install necessary tools
RUN apt-get update && \
    apt-get install -y git wget unzip && \
    rm -rf /var/lib/apt/lists/*

# Install Google Cloud SDK
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get install -y apt-transport-https ca-certificates gnupg && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && apt-get install -y google-cloud-sdk

# Set working directory
WORKDIR /fleetengine-auth

# Download and extract the Fleet Engine Auth Library
ARG FLEET_ENGINE_AUTH_VERSION="1.11.0"
RUN wget https://github.com/googlemaps/java-fleetengine-auth/archive/refs/tags/v${FLEET_ENGINE_AUTH_VERSION}.zip && \
    unzip v${FLEET_ENGINE_AUTH_VERSION}.zip && \
    rm v${FLEET_ENGINE_AUTH_VERSION}.zip

ARG PROJECT_ID
ARG SERVER_SERVICE_ACCOUNT_EMAIL
ARG DRIVER_SERVICE_ACCOUNT_EMAIL
ARG CONSUMER_SERVICE_ACCOUNT_EMAIL
ARG FLEET_READER_SERVICE_ACCOUNT_EMAIL

WORKDIR /fleetengine-auth/java-fleetengine-auth-${FLEET_ENGINE_AUTH_VERSION}/sample

RUN sed -i "/SERVER_TOKEN_ACCOUNT/{n;s/.*/      \"${SERVER_SERVICE_ACCOUNT_EMAIL}\";/}" ./src/main/java/com/google/fleetengine/auth/sample/OdrdConfiguration.java && \
    sed -i "/CONSUMER_TOKEN_ACCOUNT/{n;s/.*/      \"${CONSUMER_SERVICE_ACCOUNT_EMAIL}\";/}" ./src/main/java/com/google/fleetengine/auth/sample/OdrdConfiguration.java && \
    sed -i "/DRIVER_TOKEN_ACCOUNT/{n;s/.*/      \"${DRIVER_SERVICE_ACCOUNT_EMAIL}\";/}" ./src/main/java/com/google/fleetengine/auth/sample/OdrdConfiguration.java && \
    sed -i "s/public static final String PROVIDER_ID =.*/public static final String PROVIDER_ID = \"${PROJECT_ID}\";/" ./src/main/java/com/google/fleetengine/auth/sample/OdrdConfiguration.java && \
    sed -i "/DELIVERY_SERVER_TOKEN_ACCOUNT/{n;s/.*/      \"${SERVER_SERVICE_ACCOUNT_EMAIL}\";/}" ./src/main/java/com/google/fleetengine/auth/sample/LmfsConfiguration.java && \
    sed -i "/DELIVERY_CONSUMER_TOKEN_ACCOUNT/{n;s/.*/      \"${CONSUMER_SERVICE_ACCOUNT_EMAIL}\";/}" ./src/main/java/com/google/fleetengine/auth/sample/LmfsConfiguration.java && \
    sed -i "/DELIVERY_UNTRUSTED_DRIVER_TOKEN_ACCOUNT/{n;s/.*/      \"${DRIVER_SERVICE_ACCOUNT_EMAIL}\";/}" ./src/main/java/com/google/fleetengine/auth/sample/LmfsConfiguration.java && \
    sed -i "/DELIVERY_TRUSTED_DRIVER_TOKEN_ACCOUNT/{n;s/.*/      \"${DRIVER_SERVICE_ACCOUNT_EMAIL}\";/}" ./src/main/java/com/google/fleetengine/auth/sample/LmfsConfiguration.java && \
    sed -i "/DELIVERY_FLEET_READER_TOKEN_ACCOUNT/{n;s/.*/      \"${FLEET_READER_SERVICE_ACCOUNT_EMAIL}\";/}" ./src/main/java/com/google/fleetengine/auth/sample/LmfsConfiguration.java && \
    sed -i "s/.*public static final String PROVIDER_ID =.*/public static final String PROVIDER_ID = \"${PROJECT_ID}\";/" ./src/main/java/com/google/fleetengine/auth/sample/LmfsConfiguration.java

# Build the sample app
RUN ./gradlew jar

# Command to run the demo
CMD ["./gradlew", "run"]
