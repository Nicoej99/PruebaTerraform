output "dynamodb_table_name" {
  value = aws_dynamodb_table.productos.name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}

output "api_gateway_url" {
  value = aws_api_gateway_rest_api.api.execution_arn
}
