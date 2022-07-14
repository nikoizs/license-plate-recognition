resource "aws_api_gateway_account" "api" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_api_gateway_rest_api" "api" {
  name = "${local.project_name}-api"
}


resource "aws_api_gateway_resource" "upload" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "upload"
}

resource "aws_api_gateway_resource" "object" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.upload.id
  path_part   = "{object}"
}

resource "aws_api_gateway_method" "put_object" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.object.id
  http_method   = "PUT"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.object" = true
  }
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

resource "aws_api_gateway_integration" "s3" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.object.id
  http_method             = aws_api_gateway_method.put_object.http_method
  integration_http_method = "PUT"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${local.aws_region}:s3:path/${aws_s3_bucket.image_bucket.id}/{object}"
  credentials             = aws_iam_role.api_gateway_role.arn
  request_parameters = {
    "integration.request.path.object" = "method.request.path.object"
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.object.id
  http_method = aws_api_gateway_method.put_object.http_method
  status_code = "200"
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id        = aws_api_gateway_deployment.deploy.id
  rest_api_id          = aws_api_gateway_rest_api.api.id
  stage_name           = "dev"
  xray_tracing_enabled = true
}

resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.object.id,
      aws_api_gateway_method.put_object.id,
      aws_api_gateway_integration.s3.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}
