terragrunt {
  remote_state {
    backend  = "s3"
    config {
      encrypt     = true
      bucket      = "slapula-example-tfstate"
      key         = "production/terraform.tfstate"
      region      = "us-west-2"
      lock_table  = "slapula-production-tfstate"
    }
  },
  terraform {
    source = "../../modules/test"
  }
}

aws_region    = "us-west-2"
