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
FROM openjdk:17-jdk-slim

# Install git
RUN apt-get update && \
    apt-get install -y git python3 && \
    rm -rf /var/lib/apt/lists/*

# Create a directory for the backend
WORKDIR /odrd-backend

# Accept build arguments for the git hash
ARG GIT_HASH

# Clone the specific commit of the repository
RUN git clone https://github.com/googlemaps/java-on-demand-rides-deliveries-stub-provider.git . && \
    git checkout ${GIT_HASH}

# Precompile the backend and download the Google Cloud SDK
RUN ./gradlew compileJava war downloadCloudSdk

# Add the Google Cloud SDK to the PATH
ENV PATH="/root/.cache/google-cloud-tools-java/managed-cloud-sdk/LATEST/google-cloud-sdk/bin:${PATH}"

# Accept build arguments
ARG PROJECT_ID
ARG SERVER_SERVICE_ACCOUNT_EMAIL
ARG DRIVER_SERVICE_ACCOUNT_EMAIL
ARG CONSUMER_SERVICE_ACCOUNT_EMAIL

# Update config.properties file with provided credentials and fix app engine address
RUN sed -i "s/YOUR_PROVIDER_ID/${PROJECT_ID}/g" src/main/resources/config.properties && \
    sed -i "s/SERVER_TOKEN_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com/${SERVER_SERVICE_ACCOUNT_EMAIL}/g" src/main/resources/config.properties && \
    sed -i "s/DRIVER_TOKEN_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com/${DRIVER_SERVICE_ACCOUNT_EMAIL}/g" src/main/resources/config.properties && \
    sed -i "s/CONSUMER_TOKEN_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com/${CONSUMER_SERVICE_ACCOUNT_EMAIL}/g" src/main/resources/config.properties && \
    sed -i "s/YOUR-APPID-HERE/${PROJECT_ID}/g" src/main/webapp/WEB-INF/appengine-web.xml && \
    sed -i '/automaticRestart = true/a \    host = '\''0.0.0.0'\''' build.gradle

# Expose the port the backend runs on
EXPOSE 8080

# Command to start the backend with App Engine
CMD ["./gradlew", "appengineRun"]
