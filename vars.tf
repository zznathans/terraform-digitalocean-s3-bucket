variable "do_token" {
    type = string
    default = ""
}

variable "name" {
    type = string
    default = ""
}

variable "region" {
    type = string
    default = ""
}

variable "is_public" {
  type        = string
  default = "private"

  validation {
    condition     = contains(["private", "public-read"], var.is_public)
    error_message = "Options are either private or public-read"
  } 
}

variable "force_destroy" {
    type = bool
    default = false
}

variable "expiration" {
    type = number
    default = 30
}
