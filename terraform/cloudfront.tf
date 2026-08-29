resource "aws_cloudfront_origin_access_control" "mfe_assets_oac" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for MFE S3 Assets Buckets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "mfe_cdn" {
  # Default Origin (Shell Host)
  origin {
    domain_name              = aws_s3_bucket.mfe_assets["shell"].bucket_regional_domain_name
    origin_id                = "S3-Mfe-shell"
    origin_access_control_id = aws_cloudfront_origin_access_control.mfe_assets_oac.id
  }

  # Dynamic Origins for Remote MFEs
  dynamic "origin" {
    for_each = keys(var.micro_frontends)
    content {
      domain_name              = aws_s3_bucket.mfe_assets[origin.value].bucket_regional_domain_name
      origin_id                = "S3-Mfe-${origin.value}"
      origin_access_control_id = aws_cloudfront_origin_access_control.mfe_assets_oac.id
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Default Cache Behavior (for Shell)
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Mfe-shell"

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_s3.id
    viewer_protocol_policy   = "redirect-to-https"
    compress                 = true
  }

  # Specific No-Cache Behaviors for Entry Points
  ordered_cache_behavior {
    path_pattern     = "/index.html"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Mfe-shell"

    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.cors_s3.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.no_cache.id
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
  }

  ordered_cache_behavior {
    path_pattern     = "/federation.manifest.json"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Mfe-shell"

    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.cors_s3.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.no_cache.id
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
  }

  dynamic "ordered_cache_behavior" {
    for_each = keys(var.micro_frontends)
    content {
      path_pattern     = "/${ordered_cache_behavior.value}/remoteEntry.json"
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "S3-Mfe-${ordered_cache_behavior.value}"

      cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
      origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.cors_s3.id
      response_headers_policy_id = aws_cloudfront_response_headers_policy.no_cache.id
      viewer_protocol_policy     = "redirect-to-https"
      compress                   = true
    }
  }

  # Dynamic Ordered Cache Behaviors for Remote MFEs Assets (Cache Optimized)
  dynamic "ordered_cache_behavior" {
    for_each = keys(var.micro_frontends)
    content {
      path_pattern     = "/${ordered_cache_behavior.value}/*"
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "S3-Mfe-${ordered_cache_behavior.value}"

      cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_s3.id
      viewer_protocol_policy   = "redirect-to-https"
      compress                 = true
    }
  }

  # SPA Routing: Redirect 403/404 back to index.html with HTTP 200
  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "cors_s3" {
  name = "Managed-CORS-S3Origin"
}

resource "aws_cloudfront_response_headers_policy" "no_cache" {
  name    = "${var.project_name}-${var.environment}-no-cache-policy"
  comment = "Disable browser caching for entry points (index, manifest, remoteEntry)"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = true
      value    = "no-cache, no-store, must-revalidate"
    }
  }
}
