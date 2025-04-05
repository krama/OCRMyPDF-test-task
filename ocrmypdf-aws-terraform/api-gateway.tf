#  ╦═╗╔═╗╔═╗╔╦╗  ╔═╗╔═╗╦  ╔═╗╔═╗╦═╗  ╔═╗╔═╗╦═╗
#  ╠╦╝║╣ ╚═╗ ║   ╠═╣╠═╝║  ╠╣ ║ ║╠╦╝  ║ ║║  ╠╦╝
#  ╩╚═╚═╝╚═╝ ╩   ╩ ╩╩  ╩  ╚  ╚═╝╩╚═  ╚═╝╚═╝╩╚═

resource "aws_api_gateway_rest_api" "ocr_api" {
  name        = "${var.prefix}-ocr-api-${var.environment}"  # API name
  description = "API for OCR PDF processing"  # API description
}

# Create /upload resource in the API
resource "aws_api_gateway_resource" "upload" {
  rest_api_id = aws_api_gateway_rest_api.ocr_api.id  # API ID
  parent_id   = aws_api_gateway_rest_api.ocr_api.root_resource_id  # Root resource
  path_part   = "upload"  # Resource path
}

# Define POST method for /upload resource
resource "aws_api_gateway_method" "upload_post" {
  rest_api_id   = aws_api_gateway_rest_api.ocr_api.id  # API ID
  resource_id   = aws_api_gateway_resource.upload.id  # Resource ID
  http_method   = "POST"  # HTTP method
  authorization = "NONE"  # No authorization
}

# Integrate POST method with Lambda (AWS_PROXY)
resource "aws_api_gateway_integration" "upload_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.ocr_api.id  # API ID
  resource_id             = aws_api_gateway_resource.upload.id  # Resource ID
  http_method             = aws_api_gateway_method.upload_post.http_method  # HTTP method
  integration_http_method = "POST"  # Integration method
  type                    = "AWS_PROXY"  # Proxy integration type
  uri                     = aws_lambda_function.file_uploader.invoke_arn  # Lambda ARN
}

# Allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"  # Permission statement
  action        = "lambda:InvokeFunction"  # Allowed action
  function_name = aws_lambda_function.file_uploader.function_name  # Lambda function name
  principal     = "apigateway.amazonaws.com"  # Principal
  source_arn    = "${aws_api_gateway_rest_api.ocr_api.execution_arn}/*/${aws_api_gateway_method.upload_post.http_method}${aws_api_gateway_resource.upload.path}"  # Source ARN
}

#  ╔═╗╔═╗╦═╗╔═╗
#  ║  ║ ║╠╦╝╚═╗
#  ╚═╝╚═╝╩╚═╚═╝
resource "aws_api_gateway_method" "upload_options" {
  rest_api_id   = aws_api_gateway_rest_api.ocr_api.id  # API ID
  resource_id   = aws_api_gateway_resource.upload.id  # Resource ID
  http_method   = "OPTIONS"  # HTTP method
  authorization = "NONE"  # No authorization
}

# Set up MOCK integration for OPTIONS method (CORS)
resource "aws_api_gateway_integration" "upload_options" {
  rest_api_id = aws_api_gateway_rest_api.ocr_api.id  # API ID
  resource_id = aws_api_gateway_resource.upload.id  # Resource ID
  http_method = aws_api_gateway_method.upload_options.http_method  # HTTP method
  type        = "MOCK"  # MOCK integration
  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })  # Response template
  }
}

# Define method response for OPTIONS with CORS headers
resource "aws_api_gateway_method_response" "upload_options_200" {
  depends_on  = [aws_api_gateway_integration.upload_options]  # Dependency
  rest_api_id = aws_api_gateway_rest_api.ocr_api.id  # API ID
  resource_id = aws_api_gateway_resource.upload.id  # Resource ID
  http_method = aws_api_gateway_method.upload_options.http_method  # HTTP method
  status_code = "200"  # HTTP status code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Set up integration response for OPTIONS with CORS headers
resource "aws_api_gateway_integration_response" "upload_options_200" {
  depends_on = [aws_api_gateway_integration.upload_options]  # Dependency
  rest_api_id = aws_api_gateway_rest_api.ocr_api.id  # API ID
  resource_id = aws_api_gateway_resource.upload.id  # Resource ID
  http_method = aws_api_gateway_method.upload_options.http_method  # HTTP method
  status_code = aws_api_gateway_method_response.upload_options_200.status_code  # Status code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
  }
}

# Deploy the API
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.upload_lambda,  # Depends on Lambda integration
    aws_api_gateway_integration.upload_options   # Depends on OPTIONS integration
  ]
  rest_api_id = aws_api_gateway_rest_api.ocr_api.id  # API ID
}

#  ╔═╗╔═╗╦  ╔═╗╔╦╗╔═╗╔═╗╔═╗
#  ╠═╣╠═╝║  ╚═╗ ║ ╠═╣║ ╦║╣ 
#  ╩ ╩╩  ╩  ╚═╝ ╩ ╩ ╩╚═╝╚═╝
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id  # Deployment ID
  rest_api_id   = aws_api_gateway_rest_api.ocr_api.id  # API ID
  stage_name    = var.environment  # Stage name
}
