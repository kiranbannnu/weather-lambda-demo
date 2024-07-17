import requests as req
import json
from datetime import datetime
import boto3
from decimal import Decimal

# Define the URL for the weather API
url = "https://archive-api.open-meteo.com/v1/archive"

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('daily-weather-data') 
def calculate_median(numbers):
    sorted_numbers = sorted(numbers)
    n = len(sorted_numbers)
    middle = n // 2

    if n % 2 == 0:  # If even number of elements
        median = (sorted_numbers[middle - 1] + sorted_numbers[middle]) / 2
    else:  # If odd number of elements
        median = sorted_numbers[middle]

    return median


# Lambda function handler
def lambda_handler(event, context):
    # Extract parameters from the SQS message
    for record in event['Records']:
        message = json.loads(record['body'])
        lat = message.get('lat')  
        lon = message.get('lon')  
        start_date = message.get('start_date') 
        end_date = message.get('end_date')  
        property_id = message.get('property_id') 

        # Set up parameters for the API request
        PARAMS = {
            'latitude': lat,
            'longitude': lon,
            'start_date': start_date,
            'end_date': end_date,
            'hourly': 'temperature_2m,relative_humidity_2m'
        }

        # Make the API request
        response = req.get(url=url, params=PARAMS).json()
        hourly_data = response['hourly']

        # Initialize a dictionary to hold the aggregated data
        aggregated_data = {}

        # Process each entry in the hourly data
        for i in range(len(hourly_data['time'])):
            time_str = hourly_data['time'][i]
            temp = hourly_data['temperature_2m'][i]
            humidity = hourly_data['relative_humidity_2m'][i]

            # Convert the time string to a date
            date = datetime.fromisoformat(time_str).date()

            # If the date is not in the aggregated_data dictionary, add it
            if date not in aggregated_data:
                aggregated_data[date] = {'temperature_2m': [], 'relative_humidity_2m': []}

            # Append the temperature and humidity to the lists for the date
            aggregated_data[date]['temperature_2m'].append(temp)
            aggregated_data[date]['relative_humidity_2m'].append(humidity)

        # Calculate the median values for each date and store in DynamoDB
        for date, values in aggregated_data.items():
            median_temp = calculate_median(values['temperature_2m'])
            median_humidity = calculate_median(values['relative_humidity_2m'])

            # Print the aggregated data (for debugging purposes)
            print(f"Date: {date}")
            print(f"Median Temperature (°C): {median_temp:.2f}")
            print(f"Median Relative Humidity (%): {median_humidity:.2f}")

            # Store the aggregated data in DynamoDB
            table.put_item(
                Item={
                    'property_id': property_id,
                    'date': str(date),
                    'median_temperature': Decimal(str(median_temp)),
                    'median_humidity': Decimal(str(median_humidity))
                }
            )

