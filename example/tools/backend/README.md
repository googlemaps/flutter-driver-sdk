# Setting Up the Docker Environment for LMFS and ODRD Backends
This guide explains how to set up the Docker environment for the Last Mile Fleet Solution (LMFS) and On-demand Rides and Deliveries Solution (ODRD) sample backends using Docker Compose.

These are sample backends that should not be used for production purposes, but are used in examples and integration tests.

> [!NOTE]
> These services can also be set locally without this docker setup. 
>
> See github pages for individual services documentation for more information:
> - [LMFS backend](https://github.com/googlemaps/last-mile-fleet-solution-samples/tree/70e79e31a64d5b39e00374c3ea0b6cfc69fcf865/backend)
> - [ORRD provider](https://github.com/googlemaps/java-on-demand-rides-deliveries-stub-provider/tree/9ae34af34a0abc51e1139ce2a4fc7e0d30f368b2)
> - [Fleet Engine Auth Library for Java](https://github.com/googlemaps/java-fleetengine-auth/)

## Prerequisites:

- Docker (and Docker Compose) installed on your machine.
- A Google Cloud Platform account
  - With roles: `Fleet Engine Delivery Super User`, `Fleet Engine Service Super User` and `Service Account Token Creator`
- The Google Cloud SDK installed on your machine.

## Setup:

1. Clone the Repository
   
    Clone this repository to your local machine. If you already have the repository, make sure it's up to date.
    ```bash
    git clone [your-repository-url]
    cd [repository-name]
    ```
2. Create a .env File
   
    Copy the `.env.sample` file to a new file named `.env` and edit the file contents to include your specific environment variables.

    This file should never be committed to version control.

    ```bash
    cp .env.sample .env
    ```

    If you need to update the values in .env file later follow instructions in [Updating the .env file](#updating-the-env-file) section.

    > [!IMPORTANT]
    > Backend instances share the gcloud login information with the host machine, so you need to set the `GCLOUD_CONFIG_DIR` environment variable to the path of your local gcloud config directory.
    > This is typically `~/.config/gcloud` on MacOS and Linux, or `%APPDATA%\gcloud` on Windows

3.  Log in to gcloud and set project
    
    Run the following command to acquire new user credentials to use for Application Default Credentials:
    ```bash
    gcloud auth application-default login
    ```
    This will open a browser window asking you to log in to your Google Cloud account.

    Set the project to the one you want to use for this example:
    ```bash
    gcloud config set project [PROJECT_ID]
    ```

## Running the services:

### Running the backend sample services as Docker Containers
With everything set up, you can now run the backend service Docker containers using the following commands:

```bash
docker compose up
```
This will start the services defined in docker-compose.yml, including the `LMFS` and `ODRD` backends.

LMFS backend will be available at `http://localhost:8091` and ODRD backend at `http://localhost:8092`.

### Running individual services:

It is also possible to run individual backend services if there is no need to run all of them at once. 

To run only the `LMFS` backend, use the following command:

```bash
docker compose up lmfs-backend
```

To run only the `ODRD` backend, use the following command:

```bash
docker compose up odrd-backend
```

### Run FleetEngine Auth sample app

docker-compose file also describes a service for running the FleetEngine Auth sample app. As this application has command-line interface, it should be runned with following `docker compose run` command:
```bash
docker compose run fleetengine-auth
```

## Updating the .env file

If there is a need to update the `.env` file, the services need to be rebuilt for the changes to take effect. This can be done by running the following command:

```bash
docker compose build [--no-cache]
```
