output "cluster_id" {
  description = "RDS cluster ID"
  value       = aws_rds_cluster.this.id
}

output "cluster_endpoint" {
  description = "Writer endpoint of the RDS cluster"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint of the RDS cluster"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "security_group_id" {
  description = "Security group ID attached to the RDS cluster"
  value       = aws_security_group.db.id
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.this.name
}