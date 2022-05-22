provider "aws" {
    region = "eu-central-1"
    access_key = "AKIA5IO5TXW7F7755A4V"
    secret_key = "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"
}
variable "cidr_blocks" {
    type          = list(object({
       cidr_block = string 
       name       = string
     }))
     description  = "cidr block and name tags for both vpc and subnet"
}

resource "aws_vpc" "mainvpc" {
  cidr_block = var.cidr_blocks[0].cidr_block
  tags = {
      Name: var.cidr_blocks[0].name
  }
}

resource "aws_subnet" "mainsubnet" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = var.cidr_blocks[1].cidr_block
  availability_zone  = "eu-central-1a"
  tags = {
      Name: var.cidr_blocks[1].name
  }
}

data "aws_vpc" "existing_vpc" {
    default = true
}

resource "aws_subnet" "mainsubnet2" {
  vpc_id     = data.aws_vpc.existing_vpc.id
  cidr_block = "172.31.48.0/20"
  availability_zone  = "eu-central-1a"
  tags = {
      Name: "subnet2-dev"
  }
}

# output "subnet2" {
#   value       = "mainsu bnet2"
#   sensitive   = true
#   description = "description"
#   depends_on  = []
# }
