# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These parameters must be supplied when consuming this module.
# ---------------------------------------------------------------------------------------------------------------------

variable "name_prefix" {
  description = "A name prefix used in resource names to ensure uniqueness across a project."
  type        = string
  default     = "abcd"
}

variable "project_setup_dir" {
  description = "Folder name for all setup files"
  type        = string
  default     = "/setup"
}

variable "ssh_user_name" {
  description = "The name of the core user."
  type        = string
  default     = "root"
}

variable "ssh_user_admin" {
  description = "The name of the core user."
  type        = string
  default     = "abcd"
}

variable "ssh_key_priv" {
  description = "The SSH private key file"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "ssh_host_name_k8s_cpnl" {
  description = "Host name of K8S Control Panel"
  type        = string
  default     = "abcd"
}

variable "ssh_host_name_k8s_wrkr-01" {
  description = "Host name of K8S Worker Node 01"
  type        = string
  default     = "abcd"
}

variable "ssh_host_name_k8s_wrkr-02" {
  description = "Host name of K8S Worker Node 03"
  type        = string
  default     = "abcd"
}

variable "ssh_host_name_k8s_wrkr-03" {
  description = "Host name of K8S Worker Node 03"
  type        = string
  default     = "abcd"
}
