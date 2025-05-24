import json
import requests
import os

OPENWEATHER_API_KEY = "c51a86e60b8adc73e50727651cbc1bb8"

def lambda_handler(event, context):
    # Extract 'city' from query parameters
    city = event.get("queryStringParameters", {}).get("city", "")
    if not city:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Missing 'city' parameter"})
        }

    # Call OpenWeather API
    try:
        url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={OPENWEATHER_API_KEY}&units=metric"
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()

        weather = {
            "city": city,
            "weather": data["weather"][0]["main"],
            "description": data["weather"][0]["description"],
            "temperature": f"{data['main']['temp']}°C"
        }

        return {
            "statusCode": 200,
            "body": json.dumps(weather)
        }

    except requests.exceptions.RequestException as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
