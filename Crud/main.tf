terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

//creacion de la tabla en dynamodb
resource "aws_dynamodb_table" "productos" {
  name         = "productos"
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "N"
  }
}

//Creacion del bucket 
resource "aws_s3_bucket" "bucket" {
  bucket = "prueba2-nej2024-practice"
}

//creacion del rol
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "apigateway.amazonaws.com",
            "states.amazonaws.com",
            "cloudwatch.amazonaws.com",
            "dynamodb.amazonaws.com"
          ]

        }
      }
    ]
  })
}

//Politica para el rol para utilizar dynamo, s3, cloudwatch, logs
resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:*",
          "s3:*",
          "logs:*",
          "cloudwatch:*",
          "lambda:*"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn

}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

//FUnciones lambda
resource "aws_lambda_function" "create_product" {
  function_name = "create_product"
  role          = aws_iam_role.lambda_role.arn
  handler       = "create.handler"
  runtime       = "nodejs20.x"

  filename         = data.archive_file.code_create_lambda.output_path
  source_code_hash = filebase64sha256(data.archive_file.code_create_lambda.output_path)


}

resource "aws_lambda_function" "read_product" {
  function_name = "read_product"
  role          = aws_iam_role.lambda_role.arn
  handler       = "read.handler"
  runtime       = "nodejs20.x"

  filename         = data.archive_file.code_read_lambda.output_path
  source_code_hash = filebase64sha256(data.archive_file.code_read_lambda.output_path)

}

resource "aws_lambda_function" "update_product" {
  function_name = "update_product"
  role          = aws_iam_role.lambda_role.arn
  handler       = "update.handler"
  runtime       = "nodejs20.x"

  filename         = data.archive_file.code_update_lambda.output_path
  source_code_hash = filebase64sha256(data.archive_file.code_update_lambda.output_path)


}

resource "aws_lambda_function" "delete_product" {
  function_name = "delete_product"
  role          = aws_iam_role.lambda_role.arn
  handler       = "delete.handler"
  runtime       = "nodejs20.x"

  filename         = data.archive_file.code_delete_lambda.output_path
  source_code_hash = filebase64sha256(data.archive_file.code_delete_lambda.output_path)

}

resource "aws_lambda_function" "charge_json_to_dynamo" {
  function_name = "charge_json_to_dynamo"
  role          = aws_iam_role.lambda_role.arn
  handler       = "charge_json_to_dynamo.handler"
  runtime       = "nodejs20.x"

  filename         = data.archive_file.code_charge_json_to_dynamo_lambda.output_path
  source_code_hash = filebase64sha256(data.archive_file.code_charge_json_to_dynamo_lambda.output_path)

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.productos.name
    }
  }
}

//Notificacion de la creacion de un nuevo archivo en el bucket
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.charge_json_to_dynamo.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "s3_notification_charge" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.charge_json_to_dynamo.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

//Creacion de la API
resource "aws_api_gateway_rest_api" "api" {
  name        = "crud_api"
  description = "Api para el CRUD"
}

//Define un recurso de la api /product
resource "aws_api_gateway_resource" "product" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "product"
}

resource "aws_api_gateway_resource" "productId" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.product.id
  path_part   = "{id}"
}
//Define un recurso de la api /product
//resource "aws_api_gateway_resource" "product/" {
//  rest_api_id = aws_api_gateway_rest_api.api.id
//  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
//  path_part   = "product/"
//}

//definir metodos de la API
resource "aws_api_gateway_method" "create_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.product.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "read_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.product.id
  http_method   = "GET"
  authorization = "NONE"
  
}

resource "aws_api_gateway_method" "update_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.productId.id
  http_method   = "POST"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_method" "delete_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.productId.id
  http_method   = "DELETE"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.id" = true
  }
}

//Integrar metodos con las funciones lambdas
resource "aws_api_gateway_integration" "create_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.product.id
  http_method             = aws_api_gateway_method.create_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_product.invoke_arn
}

resource "aws_api_gateway_integration" "read_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.product.id
  http_method             = aws_api_gateway_method.read_method.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.read_product.invoke_arn
  
}

resource "aws_api_gateway_integration" "update_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.productId.id
  http_method             = aws_api_gateway_method.update_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.update_product.invoke_arn
}

resource "aws_api_gateway_integration" "delete_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.productId.id
  http_method             = aws_api_gateway_method.delete_method.http_method
  integration_http_method = "DELETE"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.delete_product.invoke_arn
  credentials             = aws_iam_role.lambda_role.arn

}

//Permisos de la api para invocar funciones lambdas
resource "aws_lambda_permission" "api_gateway_create" {
  statement_id  = "AllowAPIGatewayInvokeCreate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_product.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/POST/product"
}

resource "aws_lambda_permission" "api_gateway_read" {
  statement_id  = "AllowAPIGatewayInvokeRead"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.read_product.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/product"
}

resource "aws_lambda_permission" "api_gateway_update" {
  statement_id  = "AllowAPIGatewayInvokeUpdate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_product.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/product/{id}"
}

resource "aws_lambda_permission" "api_gateway_delete" {
  statement_id  = "AllowAPIGatewayInvokeDelete"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_product.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/product/{id}"

}

output "api_url" {
  value = aws_api_gateway_rest_api.api.execution_arn
}
