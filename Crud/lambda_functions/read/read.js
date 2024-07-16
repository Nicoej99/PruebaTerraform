const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, ScanCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const tableName = "productos";

exports.handler = async (event, context) => {
  let statusCode = 200;
  let body;
  const headers = {
    "Content-Type": "application/json",
  };

  try {
    const result = await dynamo.send(
      new ScanCommand({ TableName: tableName })
    );
    body = result.Items;
  } catch (err) {
    statusCode = 400;
    body = err.message;
  } finally {
    body = JSON.stringify(body);
  }

  return {
    statusCode,
    body,
    headers,
  };
};
module.exports = { handler };


