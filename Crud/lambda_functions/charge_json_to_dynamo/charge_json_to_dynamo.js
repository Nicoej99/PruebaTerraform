const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const { DynamoDBClient, PutItemCommand } = require('@aws-sdk/client-dynamodb');
const { fromUtf8 } = require('@aws-sdk/util-utf8-node');

const s3 = new S3Client();
const dynamodb = new DynamoDBClient();
const TABLE_NAME = process.env.TABLE_NAME;

exports.handler = async (event) => {
    const bucket = event.Records[0].s3.bucket.name;
    const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));

    try {
        // Obtener el objeto desde S3
        const getObjectParams = {
            Bucket: bucket,
            Key: key
        };
        const data = await s3.send(new GetObjectCommand(getObjectParams));
        
        // Convertir el flujo de datos a una cadena
        const bodyContents = await streamToString(data.Body);
        const jsonData = JSON.parse(bodyContents);
        console.log('JSON Data:', jsonData);

        // Procesar cada elemento del JSON y enviarlo a DynamoDB
        const tableName = TABLE_NAME;
        for (const item of jsonData) {
            const putItemParams = {
                TableName: tableName,
                Item: {
                    id: { N: item.id.toString() },
                    nombre: { S: item.nombre },
                    precio: { N: item.precio.toString() }
                }
            };
            await dynamodb.send(new PutItemCommand(putItemParams));
        }

       console.log(`Se insertaron ${jsonData.length} elementos exitosamente en la tabla de DynamoDB ${tableName}`);
    } catch (err) {
        console.error('Error al procesar los datos del objeto:', err);
      throw new Error(`Error al procesar el objeto ${key} del bucket ${bucket}.`);
    }
};

// Utilidad para convertir stream a string
async function streamToString(stream) {
    return new Promise((resolve, reject) => {
        const chunks = [];
        stream.on("data", (chunk) => chunks.push(chunk));
        stream.on("error", reject);
        stream.on("end", () => resolve(Buffer.concat(chunks).toString("utf-8")));
    });
}
