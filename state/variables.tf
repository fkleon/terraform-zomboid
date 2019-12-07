variable "region" {
  default = "eu-central-1"
}

variable "bucket_prefix" {
  default = "zomboid"
}

variable "tags" {
  type = map(string)
  default = {
    "Project" : "zomboid"
  }
}
