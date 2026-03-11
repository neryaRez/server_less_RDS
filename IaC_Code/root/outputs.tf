output "vpc_id" {
  description = "VPC ID created for the Aurora deployment"
  value       = aws_vpc.serverless_vpc.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by the Aurora DB subnet group"
  value = [
    aws_subnet.private_rds_a.id,
    aws_subnet.private_rds_b.id
  ]
}

output "rds_cluster_id" {
  description = "Aurora cluster ID"
  value       = module.rds_cluster.cluster_id
}

output "rds_cluster_endpoint" {
  description = "Aurora writer endpoint"
  value       = module.rds_cluster.cluster_endpoint
}

output "rds_reader_endpoint" {
  description = "Aurora reader endpoint"
  value       = module.rds_cluster.reader_endpoint
}

output "rds_security_group_id" {
  description = "Security group attached to the Aurora cluster"
  value       = module.rds_cluster.security_group_id
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = module.rds_cluster.db_subnet_group_name
}