terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Project   = "MeraparChallenge"
      Owner     = "Jacob Vidal"
      CostCenter = "InterviewProcess"
    }
  }
}

