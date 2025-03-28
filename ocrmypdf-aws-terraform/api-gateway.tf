resource "aws_api_gateway_rest_api" "ocr_api" {
  name        = "${var.prefix}-ocr-api-${var.environment}"  # API name with prefix
  description = "API for OCR PDF processing"  # API description
}

resource "aws_api_gateway_resource" "upload" {
  rest_api_id = aws_api_gateway_rest_api.ocr_api.id  # Link to REST API
  parent_id   = aws_api_gateway_rest_api.ocr_api.root_resource_id  # Parent resource ID
  path_part   = "upload"  # Path part for resource
  
  depends_on = [aws_api_gateway_rest_api.ocr_api]  # Dependency on REST API
}

resource "aws_api_gateway_method" "upload_post" {
  rest_api_id   = aws_api_gateway_rest_api.ocr_api.id  # Link to REST API
  resource_id   = aws_api_gateway_resource.upload.id  # Resource ID
  http_method   = "POST"  # HTTP method type
  authorization = "NONE"  # No authorization
  
  depends_on = [aws_api_gateway_rest_api.ocr_api, aws_api_gateway_resource.upload]  # Dependencies
}

resource "aws_api_gateway_integration" "upload_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.ocr_api.id  # Link to REST API
  resource_id             = aws_api_gateway_resource.upload.id  # Resource ID
  http_method             = aws_api_gateway_method.upload_post.http_method  # HTTP method
  integration_http_method = "POST"  # Integration method
  type                    = "AWS_PROXY"  # Proxy integration type
  uri                     = aws_lambda_function.file_uploader.invoke_arn  # Lambda function URI
  
  depends_on = [  # Multiple dependencies
    aws_api_gateway_rest_api.ocr_api,
    aws_api_gateway_resource.upload,
    aws_api_gateway_method.upload_post,
    aws_lambda_function.file_uploader
  ]
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"  # Permission statement ID
  action        = "lambda:InvokeFunction"  # Lambda action
  function_name = aws_lambda_function.file_uploader.function_name  # Lambda function name
  principal     = "apigateway.amazonaws.com"  # Principal for API Gateway
  source_arn    = "${aws_api_gateway_rest_api.ocr_api.execution_arn}/*/${aws_api_gateway_method.upload_post.http_method}${aws_api_gateway_resource.upload.path}"  # Source ARN
  
  depends_on = [aws_lambda_function.file_uploader, aws_api_gateway_rest_api.ocr_api]  # Dependencies
}

resource "aws_api_gateway_method" "upload_options" {
  rest_api_id   = aws_api_gateway_rest_api.ocr_api.id  # Link to REST API
  resource_id   = aws_api_gateway_resource.upload.id  # Resource ID
  http_method   = "OPTIONS"  # HTTP method type
  authorization = "NONE"  # No authorization
  
  depends_on = [aws_api_gateway_rest_api.ocr_api, aws_api_gateway_resource.upload]  # Dependencies
}

resource "aws_api_gateway_integration" "upload_options" {
  rest_api_id = aws_api_gateway_rest_api.ocr_api.id  # Link to REST API
  resource_id = aws_api_gateway_resource.upload.id  # Resource ID
  http_method = aws_api_gateway_method.upload_options.http_method  # HTTP method
  type        = "MOCK"  # Mock integration type
  request_templates = {  # Request templates
    "application/json" = jsonencode({ statusCode = 200 })
  }
  
  depends_on = [  # Multiple dependencies
    aws_api_gateway_rest_api.ocr_api,
    aws_api_gateway_resource.upload,
    aws_api_gateway_method.upload_options
  ]
}

resource "aws_api_gateway_method_response" "upload_options_200" {
  rest_api_id = aws_api_gateway_rest_api.ocr_api.id  # Link to REST API
  resource_id = aws_api_gateway_resource.upload.id  # Resource ID
  http_method = aws_api_gateway_method.upload_options.http_method  # HTTP method
  status_code = "200"  # Response status code
  response_parameters = {  # Response parameters
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
  
  depends_on = [  # Multiple dependencies
    aws_api_gateway_rest_api.ocr_api,
    aws_api_gateway_resource.upload,
    aws_api_gateway_method.upload_options,
    aws_api_gateway_integration.upload_options
  ]
}

resource "aws_api_gateway_integration_response" "upload_options_200" {
  rest_api_id = aws_api_gateway_rest_api.ocr_api.id  # Link to REST API
  resource_id = aws_api_gateway_resource.upload.id  # Resource ID
  http_method = aws_api_gateway_method.upload_options.http_method  # HTTP method
  status_code = aws_api_gateway_method_response.upload_options_200.status_code  # Status code
  response_parameters = {  # Response parameters
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
  }
  
  depends_on = [  # Multiple dependencies
    aws_api_gateway_rest_api.ocr_api,
    aws_api_gateway_resource.upload,
    aws_api_gateway_method.upload_options,
    aws_api_gateway_method_response.upload_options_200,
    aws_api_gateway_integration.upload_options
  ]
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.ocr_api.id  # Link to REST API
  
  triggers = {  # Redeployment trigger
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.upload.id,
      aws_api_gateway_method.upload_post.id,
      aws_api_gateway_integration.upload_lambda.id,
      aws_api_gateway_method.upload_options.id,
      aws_api_gateway_integration.upload_options.id,
    ]))
  }
  
  lifecycle {  # Lifecycle policy
    create_before_destroy = true
  }
  
  depends_on = [  # Multiple dependencies
    aws_api_gateway_integration.upload_lambda,
    aws_api_gateway_integration.upload_options,
    aws_api_gateway_integration_response.upload_options_200
  ]
}

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id  # Deployment ID
  rest_api_id   = aws_api_gateway_rest_api.ocr_api.id  # Link to REST API
  stage_name    = var.environment  # Stage name
  
  depends_on = [aws_api_gateway_deployment.api_deployment]  # Dependency on deployment
}
