resource "aws_security_group" "lambda_sg" {
  name        = "${local.name_prefix}-lambda-sg"
  description = "Security group for Lambda functions that access Aurora"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-lambda-sg"
    }
  )
}