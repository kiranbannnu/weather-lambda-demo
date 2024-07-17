
# Weather Data Processing Project

This project processes historical weather data using an AWS Lambda function, stores the aggregated data in DynamoDB, and handles incoming data through SQS.

## Prerequisites

- [AWS CLI](https://aws.amazon.com/cli/)
- [Terraform](https://www.terraform.io/downloads.html)
- Python 3.9+
- Boto3 (AWS SDK for Python)
- Requests library

## Setup Guide

### 1. Clone the Repository

```sh
git clone https://github.com/your-repo/weather-data-processing.git 
```
cd weather-data-processing

2. Install Dependencies

Ensure you have Python 3.9+ and pip installed, then install the required Python packages:


```
# Create a working directory and navigate into it

mkdir -p lambda_function
cd lambda_function

# Create a Python virtual environment
python3 -m venv lambda_function

# Activate the virtual environment
source lambda_function/bin/activate

# Install the required dependencies
pip install boto3 requests
deactivate

# Create a package directory for dependencies
mkdir -p PACKAGE_DIR

# Copy installed dependencies to the package directory
cp -r lambda_function/lib/python3.*/site-packages/* PACKAGE_DIR/


# Copy the Lambda function code into the package directory
cp ../lambda_function.py PACKAGE_DIR/



```
3. Create Lambda Deployment Package

Zip your Lambda function code and dependencies:


```
cd $VENV_DIR
cp lambda_function.py 
zip -r lambda_function.zip .

```
Move this lambda_function.zip to terraform project directory.
```
tree
.
├── lambda_function.zip
├── main.tf
├── outputs.tf
├── README.md
└── vars.tf
```
4. Configure Terraform

Edit the variables.tf file to set the AWS region if needed:

```

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"  # Change if necessary
}
```
5. Deploy Resources with Terraform
```
Initialize Terraform:

```
```
terraform init
```
Plan and Apply the Terraform configuration:

```
terraform plan

terraform apply
```
6. Verify Deployment

After Terraform completes, verify the resources are created in your AWS account:

    SQS Queue: Check the SQS console for weather-data-queue.
    DynamoDB Table: Check the DynamoDB console for daily-weather-data.
    Lambda Function: Check the Lambda console for weather-data-processor.

7. Testing the Lambda Function

You can test the Lambda function by sending a message to the SQS queue from UI or CLI or SDK.
AWS CLI command to send message to SQS:


```
aws sqs send-message --queue-url YOUR_SQS_QUEUE_URL --message-body '{
    "lat": "40.7128",
    "lon": "-74.0060",
    "start_date": "2023-01-01",
    "end_date": "2023-01-31",
    "property_id": "12345"
}'
```

Replace YOUR_SQS_QUEUE_URL with the actual URL of your SQS queue.
Files

    lambda_function.py: Contains the Lambda function code.
    terraform/: Contains Terraform configuration files.
Cleanup

To clean up all the resources created by Terraform, run:

```
terraform destroy
```
This will delete all the AWS resources created by this project.
