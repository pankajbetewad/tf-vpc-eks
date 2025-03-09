output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.eks-vpc.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.eks-public-subnets[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.eks-private-subnets[*].id
}