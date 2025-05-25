const https = require('https');

exports.handler = async (event) => {
    const city = 'Sydney';  // Later, make this dynamic via query params
    const apiKey = "c51a86e60b8adc73e50727651cbc1bb8"
    const url = `https://api.openweathermap.org/data/2.5/weather?q=${city}&units=metric&appid=${apiKey}`;

    return new Promise((resolve, reject) => {
        https.get(url, (res) => {
            let data = '';

            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const weatherData = JSON.parse(data);
                    if (weatherData.cod !== 200) {
                        resolve({
                            statusCode: 400,
                            body: JSON.stringify({ error: weatherData.message }),
                        });
                    } else {
                        const response = {
                            weather: weatherData.weather[0].main,
                            temperature: `${weatherData.main.temp}°C`,
                            city: weatherData.name,
                        };
                        resolve({
                            statusCode: 200,
                            body: JSON.stringify(response),
                        });
                    }
                } catch (e) {
                    reject(e);
                }
            });
        }).on('error', (e) => {
            reject(e);
        });
    });
};
