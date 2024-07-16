const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, UpdateCommand } = require("@aws-sdk/lib-dynamodb");

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
    const updateParams = {
      TableName: tableName,
      Key: {
        id: Number(event.pathParameters.id),
      },
      UpdateExpression: "set nombre = :nombre, precio = :precio",
      ExpressionAttributeValues: {
        ":nombre": requestJSON.nombre,
        ":precio": requestJSON.precio,
      },
      ReturnValues: "ALL_NEW",
    };

    const result = await dynamo.send(new UpdateCommand(updateParams));
    body = `Producto actualizado: ${JSON.stringify(result.Attributes)}`;
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


