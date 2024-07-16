const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, DeleteCommand } = require("@aws-sdk/lib-dynamodb");

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
    await dynamo.send(
      new DeleteCommand({
        TableName: tableName,
        Key: {
          id: Number(event.pathParameters.id),
        },
      })
    );
    body = `Se ha borrado el producto ${event.pathParameters.id}`;
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


