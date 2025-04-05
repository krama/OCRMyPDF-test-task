# Create REST API
resource "aws_api_gateway_rest_api" "ocr_api" {
  name        = "${var.prefix}-ocr-api-${var.environment}"
  description = "API for processing PDF with OCR"
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-ocr-api"
    }
  )
}

# Create resource /upload
resource "aws_api_gateway_resource" "upload" {
  rest_api_id = aws_api_gateway_rest_api.ocr_api.id
  parent_id   = aws_api_gateway_rest_api.ocr_api.root_resource_id
  path_part   = "upload"
}

# Create method POST for /upload
resource "aws_api_gateway_method" "upload_post" {
  rest_api_id   = aws_api_gateway_rest_api.ocr_api.id
  resource_id   = aws_api_gateway_resource.upload.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integrate method POST with Lambda function (AWS_PROXY)
resource "aws_api_gateway_integration" "upload_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.ocr_api.id
  resource_id             = aws_api_gateway_resource.upload.id
  http_method             = aws_api_gateway_method.upload_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.file_uploader_lambda.invoke_arn
}

# Allow API Gateway to call Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.file_uploader_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.ocr_api.execution_arn}/*/${aws_api_gateway_method.upload_post.http_method}${aws_api_gateway_resource.upload.path}"
}

# Create method OPTIONS for /upload (for CORS support)
resource "aws_api_gateway_method" "upload_options" {
  rest_api_id   = aws_api_gateway_rest_api.ocr_api.id
  resource_id   = aws_api_gateway_resource.upload.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# MOCK integration for method OPTIONS (CORS)
resource "aws_api_gateway_integration" "upload_options" {
  rest_api_id = aws_api_gateway_rest_api.ocr_api.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.upload_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

# Define response for method OPTIONS with CORS headers
resource "aws_api_gateway_method_response" "upload_options_200" {
  depends_on  = [aws_api_gateway_integration.upload_options]
  rest_api_id = aws_api_gateway_rest_api.ocr_api.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.upload_options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Configure response for integration with CORS headers
resource "aws_api_gateway_integration_response" "upload_options_200" {
  depends_on  = [aws_api_gateway_integration.upload_options]
  rest_api_id = aws_api_gateway_rest_api.ocr_api.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.upload_options.http_method
  status_code = aws_api_gateway_method_response.upload_options_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
  }
}

# Create API deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.upload_lambda,
    aws_api_gateway_integration.upload_options
  ]
  rest_api_id = aws_api_gateway_rest_api.ocr_api.id
}

# Create API stage
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.ocr_api.id
  stage_name    = var.api_stage_name
  
  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-api-stage-${var.api_stage_name}"
    }
  )
}
