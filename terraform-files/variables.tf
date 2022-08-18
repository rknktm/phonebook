variable "instance-type" {
  type    = string
  default = "t2.micro"
}
variable "key" {
  type    = string
  default = "xxxxxx"
}
variable "DatabaseName" {
  default = "phonebook"
}
variable "UserName" {
  default = "admin"
}
variable "Password" {
  default = "123456789"
}
