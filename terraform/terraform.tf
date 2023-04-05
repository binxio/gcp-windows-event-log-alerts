terraform {
  required_version = "~> 1.2.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.59"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "google" {
}

provider "null" {
}

provider "random" {
}
