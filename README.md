# Deployment of Serverless Application

Following are the steps for the deployment of serverless application.

## Build

Follow these steps to run the `build.sh` file:

Run these command
- To make the file executable.
    ```sh
    chmod +x ./build.sh
    ```
 

### Note
Make sure python 3.11 is installed on your system, before running the build.sh file.

- To run the `build.sh` file:
    ```sh
    bash ./build.sh
    ```
   This command creates the zip files of `common`, `internal`, `external`, `web`, and `mobile` lambda functions.

## Deploy

Follow these steps to run the `deployment.sh` file:

Run these command.
- To make the file executable.
    ```sh
    chmod +x ./deployment.sh
    ```


- To run the `deployment.sh`
    ```sh
    bash ./deployment.sh --stage=prod  --region_name=us  --properties=./properties.yaml
    ```

