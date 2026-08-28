output "s3_buckets" {
  value       = { for k, v in aws_s3_bucket.mfe_assets : k => v.id }
  description = "Map of MFE keys to S3 bucket names"
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.mfe_cdn.domain_name
  description = "The domain name of the CloudFront distribution"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.mfe_cdn.id
  description = "The ID of the CloudFront distribution"
}
