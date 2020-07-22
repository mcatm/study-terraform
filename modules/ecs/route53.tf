
# STEP1: Route53 Hosted Zone
# ホストゾーンを作成します
# https://www.terraform.io/docs/providers/aws/d/route53_zone.html

resource "aws_route53_zone" "main" {
    name         = var.domain
}



# STEP2: ACM
# 証明書を発行します
# https://www.terraform.io/docs/providers/aws/r/acm_certificate.html

resource "aws_acm_certificate" "main" {
  domain_name = var.domain

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}


# STEP3: Route53 record
# ACMによる検証用レコード
# https://www.terraform.io/docs/providers/aws/r/route53_record.html

resource "aws_route53_record" "validation" {
  depends_on = [aws_acm_certificate.main]

  zone_id = aws_route53_zone.main.id

  ttl = 60

  name    = aws_acm_certificate.main.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.main.domain_validation_options.0.resource_record_type
  records = [aws_acm_certificate.main.domain_validation_options.0.resource_record_value]
}



# STEP4: ACM Validate
# https://www.terraform.io/docs/providers/aws/r/acm_certificate_validation.html

# resource "aws_acm_certificate_validation" "main" {
#   certificate_arn = aws_acm_certificate.main.arn
  
#   validation_record_fqdns = ["${aws_route53_record.validation.fqdn}"]
# }



# STEP5: Route53 record
# https://www.terraform.io/docs/providers/aws/r/route53_record.html

resource "aws_route53_record" "main" {
  type = "A"

  name    = var.domain
  zone_id = aws_route53_zone.main.id

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}


