data "archive_file" "code_create_lambda" {
  type        = "zip"
  source_dir  = "../Crud/lambda_functions/create"
  output_path = "lambdas/create.zip"
}

data "archive_file" "code_delete_lambda" {
  type        = "zip"
  source_dir  = "../Crud/lambda_functions/delete"
  output_path = "lambdas/delete.zip"
}

data "archive_file" "code_read_lambda" {
  type        = "zip"
  source_dir  = "../Crud/lambda_functions/read"
  output_path = "lambdas/read.zip"
}

data "archive_file" "code_update_lambda" {
  type        = "zip"
  source_dir  = "../Crud/lambda_functions/update"
  output_path = "lambdas/update.zip"
}

data "archive_file" "code_charge_json_to_dynamo_lambda" {
  type        = "zip"
  source_dir  = "../Crud/lambda_functions/charge_json_to_dynamo"
  output_path = "lambdas/charge_json_to_dynamo.zip"
}

