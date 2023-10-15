
create_layer_zip () {
    # @params:
    #  - zip_file_name:- Layer zip file name
    #  - destination_folder:- Destination folder in which zip file need to moved


    local zip_file_name="$1"
    local destination_folder="$2"

    SOURCE_FOLDER="platform/common"
    DEST_PYTHON_FOLDER="python"
    DEST_LIB_FOLDER="${DEST_PYTHON_FOLDER}/lib/python3.10/site-packages"

    # Ensure the destination folders exist
    mkdir -p "${DEST_PYTHON_FOLDER}"
    mkdir -p "${DEST_LIB_FOLDER}"

    # cp the 'common' folder to the desired structure
    cp -r "${SOURCE_FOLDER}" "${DEST_PYTHON_FOLDER}"

    # Install dependencies from requirements.txt into 'lib' folder
    pip install -r "${DEST_PYTHON_FOLDER}/common/requirements.txt" -t "${DEST_LIB_FOLDER}"

    # Create a zip file from the 'python' folder
    zip -r "$zip_file_name" "$DEST_PYTHON_FOLDER"
    
    # mode zip file into destination folder
    mv "$zip_file_name" "$destination_folder"

    # delete temporary python folder
    rm -r $DEST_PYTHON_FOLDER
}

create_external_handlers_zip () {
    # @params:
    #  - source_directory:- Source directory from where all external handlers source code need to be taken
    #  - destination_folder:- Destination folder in which zip file need to moved


    local source_directory="$1"
    local destination_folder="$2"

    cd $source_directory || exit

    # Iterate through each subdirectory
    for dir in */; do
        if [ -d "$dir" ]; then
            # Navigate to the subdirectory
            cd "$dir" || exit

            # Check if a requirements.txt file exists
            if [ -e requirements.txt ]; then
                echo "Installing requirements for $dir"
                pip install -r requirements.txt -t .
            else
                echo "No requirements.txt found in $dir"
            fi

            # Create a zip file for the directory
            zip -r "${dir%/}.zip" .

            # Move that zip file into the build directory
            mv "${dir%/}.zip" "../../../$destination_folder"

            # Navigate back to the external directory
            cd ..
        fi
    done

    cd .. || exit
    cd .. || exit
}

create_api_handler_zip () {
    # @params:
    #  - source_folder:- Source directory from where code need to taken to zip
    #  - zip_file_name:- API handler zip file name
    #  - destination_folder:- Destination folder in which zip file need to moved


    local source_folder="$1"
    local zip_file_name="$2"
    local destination_folder="$3"

    # Change directory to source folder
    cd $source_folder || exit

    # Create a zip file from the current directory
    zip -r "$zip_file_name" .

    # Move zip file into destination folder
    mv "$zip_file_name" "../../$destination_folder"

    # Jump back to root directory
    cd ../..
}


BUILD_DIRECTORY="build"
EXTERNAL_HANDLER_SOURCE="platform/external"
WEB_API_SOURCE="platform/web-api"

LAYER_ZIP_FILE_NAME="layer.zip"
WEB_API_ZIP_FILE_NAME="web-api-handler.zip"


create_layer_zip $LAYER_ZIP_FILE_NAME $BUILD_DIRECTORY
create_external_handlers_zip  $EXTERNAL_HANDLER_SOURCE $BUILD_DIRECTORY

create_api_handler_zip $WEB_API_SOURCE $WEB_API_ZIP_FILE_NAME $BUILD_DIRECTORY
