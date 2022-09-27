
variable "key_name" {
  description = "key name"
}



resource "aws_key_pair" "current" {
  key_name   = var.key_name
  public_key = file("/home/user/.ssh/id_rsa.pub")
}
