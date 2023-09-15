terraform {
  backend "s3" {
    bucket = "terraform-state-general"
    key    = "k3s-at-home/terraform.tfstate"
    region = "eu-central-1"
  }
}