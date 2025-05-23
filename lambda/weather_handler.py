import json
import requests
import os

def lambda_handler(event, context):
    city = event.get('queryStringParameters', {}).get('city', 'Melbourne')
    api_key = os.getenv('WEATHER_API_KEY')
    url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={api_key}&units=metric"
    
    response = requests.get(url)
    weather = response.json()

    return {
        'statusCode': 200,
        'body': json.dumps({
            'city': city,
            'temperature': weather['main']['temp'],
            'description': weather['weather'][0]['description']
        }),
        'headers': {
            'Content-Type': 'application/json'
        }
    }
