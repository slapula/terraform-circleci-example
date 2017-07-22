resource "aws_s3_bucket" "elb_log_bucket" {
  bucket = "synoptic-elb-logs-${var.environment_name}"
  acl    = "private"

  lifecycle_rule {
    enabled = true
    prefix = "/"
    noncurrent_version_expiration {
      days = 30
    }
  }

  tags {
    Name = "synoptic-elb-logs-${var.environment_name}"
    Environment = "${var.environment_name}"
    Role = "storage"
  }
}

data "aws_iam_policy_document" "elb_s3_policy" {
  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      "${aws_s3_bucket.elb_log_bucket.arn}",
      "${aws_s3_bucket.elb_log_bucket.arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["655437640759"]
    }
  }
}

resource "aws_s3_bucket_policy" "elb_log_s3_policy" {
  bucket = "${aws_s3_bucket.elb_log_bucket.id}"
  policy = "${data.aws_iam_policy_document.elb_s3_policy.json}"
}
