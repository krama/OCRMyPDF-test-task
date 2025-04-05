# Output variables of API Gateway module ---------------------------------------------------------

output "api_id" {
  description = "ID of REST API"
  value       = aws_api_gateway_rest_api.ocr_api.id
}

output "api_execution_arn" {
  description = "ARN for executing API"
  value       = aws_api_gateway_rest_api.ocr_api.execution_arn
}

output "api_endpoint" {
  description = "Base URL of API Gateway"
  value       = "${aws_api_gateway_deployment.api_deployment.invoke_url}${aws_api_gateway_stage.api_stage.stage_name}/upload"
}

output "api_deployment_id" {
  description = "ID of API deployment"
  value       = aws_api_gateway_deployment.api_deployment.id
}

output "api_stage_name" {
  description = "Name of API stage"
  value       = aws_api_gateway_stage.api_stage.stage_name
}
