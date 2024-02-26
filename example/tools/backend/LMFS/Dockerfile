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

# Install git
RUN apt-get update && \
    apt-get install -y git && \
    rm -rf /var/lib/apt/lists/*

# Accept build arguments for the git hash
ARG GIT_HASH

# Clone only the backend directory
WORKDIR /lmfs-backend
RUN git init && \
    git remote add origin https://github.com/googlemaps/last-mile-fleet-solution-samples.git && \
    git config core.sparseCheckout true && \
    echo "backend/*" >> .git/info/sparse-checkout && \
    git fetch --depth 1 origin ${GIT_HASH} && \
    git checkout ${GIT_HASH}

# Move to the backend directory
WORKDIR /lmfs-backend/backend

# Append the force gRPC versions to the build.gradle file
RUN echo '\nconfigurations.all {\n\
    resolutionStrategy {\n\
        force '\''io.grpc:grpc-stub:1.55.1'\''\n\
        force '\''io.grpc:grpc-protobuf:1.55.1'\''\n\
        force '\''io.grpc:grpc-netty:1.55.1'\''\n\
    }\n\
}' >> build.gradle

# Precompile the backend and download the Google Cloud SDK
RUN ./gradlew compileJava war downloadCloudSdk

# Add the Google Cloud SDK to the PATH
ENV PATH="/root/.cache/google-cloud-tools-java/managed-cloud-sdk/LATEST/google-cloud-sdk/bin:${PATH}"

# Accept build arguments
ARG PROJECT_ID
ARG SERVER_SERVICE_ACCOUNT_EMAIL
ARG DRIVER_SERVICE_ACCOUNT_EMAIL
ARG CONSUMER_SERVICE_ACCOUNT_EMAIL
ARG FLEET_READER_SERVICE_ACCOUNT_EMAIL
ARG JS_API_KEY
ARG HOST="http:\\localhost:8091"

# Update config.properties file with provided credentials
RUN sed -i "s/\*\*\*\*\*UPDATE_WITH_PROJECT_ID\*\*\*\*\*/${PROJECT_ID}/g" src/main/resources/config.properties && \
    sed -i "s/\*\*\*\*\*UPDATE_WITH_SERVER_SERVICE_ACCOUNT_EMAIL\*\*\*\*\*/${SERVER_SERVICE_ACCOUNT_EMAIL}/g" src/main/resources/config.properties && \
    sed -i "s/\*\*\*\*\*UPDATE_WITH_DRIVER_SERVICE_ACCOUNT_EMAIL\*\*\*\*\*/${DRIVER_SERVICE_ACCOUNT_EMAIL}/g" src/main/resources/config.properties && \
    sed -i "s/\*\*\*\*\*UPDATE_WITH_CONSUMER_SERVICE_ACCOUNT_EMAIL\*\*\*\*\*/${CONSUMER_SERVICE_ACCOUNT_EMAIL}/g" src/main/resources/config.properties && \
    sed -i "s/\*\*\*\*\*UPDATE_WITH_FLEET_READER_SERVICE_ACCOUNT_EMAIL\*\*\*\*\*/${FLEET_READER_SERVICE_ACCOUNT_EMAIL}/g" src/main/resources/config.properties && \
    sed -i "s/\*\*\*\*\*UPDATE_WITH_JS_API_KEY\*\*\*\*\*/${JS_API_KEY}/g" src/main/resources/config.properties && \
    sed -i "s|http://localhost:8080|${HOST}|g" src/main/resources/config.properties && \
    sed -i "s/YOUR-APPID-HERE/${PROJECT_ID}/g" src/main/webapp/WEB-INF/appengine-web.xml && \
    sed -i '/automaticRestart = true/a \    host = '\''0.0.0.0'\''' build.gradle

# Expose the port the backend runs on
EXPOSE 8080

# Command to start the backend with App Engine
CMD ["./gradlew", "appengineRun"]
