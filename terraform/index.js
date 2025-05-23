// index.js
exports.handler = async (event) => {
  return {
    statusCode: 200,
    body: JSON.stringify({ weather: "Sunny", temperature: "27°C" }),
  };
};
