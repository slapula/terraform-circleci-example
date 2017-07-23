terragrunt {
  remote_state {
    backend  = "s3"
    config {
      encrypt     = true
      bucket      = "slapula-example-tfstate"
      key         = "staging/terraform.tfstate"
      region      = "us-west-2"
      lock_table  = "slapula-staging-tfstate"
    }
  },
  terraform {
    source = "../../modules/test"
  }
}

aws_region    = "us-west-2"
asg_instance_ami  = "ami-1e299d7e"
