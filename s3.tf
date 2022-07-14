resource "aws_s3_bucket" "image_bucket" {
  bucket = "${local.project_name}-image-bucket"

}
