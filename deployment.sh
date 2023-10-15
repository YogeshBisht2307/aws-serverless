#!/bin/bash

reset_tfvars_file() {
    local contents="$1"
    local tfvars_file="$2"

    echo -e $contents > $tfvars_file
}


show_help() {
  echo "Usage: bash apply_deployment.sh [OPTIONS]"
  echo "Deploy the application using Terraform."
  echo ""
  echo "Options:"
  echo "  --stage=VALUE           Set the deployment stage (dev, test, prod)"
  echo "  --cloud=VALUE           Set the cloud provider (aws, azure, google)"
  echo "  --region_name=VALUE     Set the region name (in, us)"
  echo "  -h, --help         Display this help and exit"
}


# Parse command line arguments
for arg in "$@"; do
  case $arg in
    --stage=*)
      STAGE="${arg#*=}"
      shift
      ;;
    --cloud=*)
      CLOUD="${arg#*=}"
      shift
      ;;
    --region_name=*)
      REGION_NAME="${arg#*=}"
      shift
      ;;
    --properties=*)
      PROPERTIES_FILE="${arg#*=}"
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      # Ignore other arguments
      shift
      ;;
  esac
done

# Validate cloud value
case $CLOUD in
  aws)
    # Valid cloud value
    ;;
  *)
    echo "Invalid cloud value. Supported clouds: aws, azure, google."
    exit 1
    ;;
esac

echo "$PROPERTIES_FILE"


if ! command -v yq &> /dev/null; then
    echo "yq not found. Installing yq..."
    if [ "$(uname)" == "Darwin" ]; then
        brew install yq
    else
        # Install yq on Linux
        sudo wget https://github.com/mikefarah/yq/releases/download/v4.13.2/yq_linux_amd64 -O /usr/local/bin/yq
        sudo chmod +x /usr/local/bin/yq
    fi
fi

if [ ! -f "$PROPERTIES_FILE" ]; then
    echo "Error: YAML file not found."
    exit 1
fi

region_name=$(yq eval ".Properties.Region.$REGION_NAME.region_name" "$PROPERTIES_FILE")
region_value=$(yq eval ".Properties.Region.$REGION_NAME.region_value" "$PROPERTIES_FILE")
postgresql_availability_zone=$(yq eval ".Properties.Region.$REGION_NAME.postgresql_availability_zone" "$PROPERTIES_FILE")
timescale_availability_zone=$(yq eval ".Properties.Region.$REGION_NAME.timescale_availability_zone" "$PROPERTIES_FILE")
branch_name=$(yq eval ".Properties.Stage.$STAGE.branch" "$PROPERTIES_FILE")
tfvars_file=$(yq eval ".Properties.Stage.$STAGE.tfvars" "$PROPERTIES_FILE")

if [ -z "$region_name" ]; then
  echo "Error: Invalid properties configuration. region_name required"
  exit 1
fi

if [ -z "$region_value" ]; then
  echo "Error: Invalid properties configuration. region_value required"
  exit 1
fi

if [ -z "$postgresql_availability_zone" ]; then
  echo "Error: Invalid properties configuration. postgresql_availability_zone required"
  exit 1
fi

if [ -z "$timescale_availability_zone" ]; then
  echo "Error: Invalid properties configuration. timescale_availability_zone required"
  exit 1
fi

if [ -z "$branch_name" ]; then
  echo "Error: Invalid properties configuration. branch_name required"
  exit 1
fi

if [ -z "$tfvars_file" ]; then
  echo "Error: Invalid properties configuration. tfvars_file required"
  exit 1
fi


# Validate stage value based on current git branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$branch_name" != "$CURRENT_BRANCH" ]]; then
  echo "Mismatch between specified branch ($branch_name) and current branch mapping ($CURRENT_BRANCH)."
  exit 1
fi


# Check if build directory exists
if [[ ! -d "./build" ]]; then
  echo "Build directory not found in the root folder of the application."
  exit 1
fi

# Check if build directory contains at least one .jar or .zip file
if [[ ! $(find ./build -maxdepth 1 \( -name "*.jar" -o -name "*.zip" \) -print -quit) ]]; then
  echo "Build directory does not contain any .jar or .zip files in the root."
  exit 1
fi

cd infra/$CLOUD || { echo "Unable to switch to directory infra/$CLOUD."; exit 1; }

BUCKET_PREFIX=$(awk -F ' *= *' '/^bucket_prefix *=/ {print $2}' "$tfvars_file")
BUCKET_PREFIX=${BUCKET_PREFIX//[\"]}

if [[ "$CLOUD" == "aws" ]]; then
  # Read account_id from tfvars file
  ACCOUNT_ID_IN_TFVARS=$(awk -F ' *= *' '/^account_id *=/ {print $2}' "$tfvars_file")
  ACCOUNT_ID_IN_TFVARS="${ACCOUNT_ID_IN_TFVARS//\"}"

  # Get the current AWS account ID
  CURRENT_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

  # Compare account IDs
  if [[ $ACCOUNT_ID_IN_TFVARS != "$CURRENT_ACCOUNT_ID" ]]; then
    echo "Account ID in $tfvars_file ($ACCOUNT_ID_IN_TFVARS) does not match the current AWS CLI account ID ($CURRENT_ACCOUNT_ID)."
    exit 1
  fi

  tf_file_path="./terraform.tfstate"
  if [ -e "$tf_file_path" ]; then
    echo "File '$tf_file_path' exists."
  else
    echo "File '$tf_file_path' does not exist. Downloading..."
    aws s3 cp s3://$REGION_NAME.com.$BUCKET_PREFIX.application-code/tf/terraform.tfstate $tf_file_path || { echo "Error downloading terraform.tfstate."; exit 1; }
  fi
fi

# Read and update tfvars file

while IFS= read -r line; do
  input_content="$input_content$line\n"
done < "$tfvars_file"

additional_text=$(cat <<EOF
postgresql_availability_zone = "$postgresql_availability_zone"\n
timescale_availability_zone = "$timescale_availability_zone"\n
stage = "$STAGE"\n
region = "$region_value"\n
region_name = "$region_name"
EOF
)

output_content="$input_content$additional_text"
echo -e $output_content > $tfvars_file

# Run terraform plan and apply
echo "Enable terraform logs"
export TF_LOG=ERROR

echo "Running 'terraform init'"
sleep 1
terraform init || { reset_tfvars_file "$input_content" "$tfvars_file"; echo "Error initializing Terraform."; exit 1; }

echo "Running 'terraform validate'"
terraform validate || { reset_tfvars_file "$input_content $tfvars_file"; echo "Error validating Terraform."; exit 1; }

echo "Running 'terraform plan -var-file="$tfvars_file"'"
sleep 1
terraform plan -var-file="$tfvars_file" || { reset_tfvars_file "$input_content" "$tfvars_file"; echo "Error running Terraform plan."; exit 1; }

echo "Running 'terraform apply -var-file="$tfvars_file"'"
sleep 1
terraform apply -var-file="$tfvars_file" || { reset_tfvars_file "$input_content" "$tfvars_file"; echo "Error applying Terraform configuration."; exit 1; }

# Upload updated terraform.tfstate back to the bucket
if [[ "$CLOUD" == "aws" ]]; then
  aws s3 cp ./terraform.tfstate s3://$REGION_NAME.com.$BUCKET_PREFIX.application-code/tf/terraform.tfstate || { echo "Error uploading terraform.tfstate."; exit 1; }
fi

reset_tfvars_file "$input_content" "$tfvars_file";
echo "Deployment completed successfully."
