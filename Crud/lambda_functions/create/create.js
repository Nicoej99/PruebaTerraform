const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");

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
    const requestJSON = JSON.parse(event.body);
    await dynamo.send(
      new PutCommand({
        TableName: tableName,
        Item: {
          id: Number(requestJSON.id),
          nombre: requestJSON.nombre,
          precio: requestJSON.precio,
        },
      })
    );
    body = `Se ha guardado un nuevo producto ${requestJSON.id}`;
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

