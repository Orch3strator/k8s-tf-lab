terraform {
  required_providers {
    ssh = {
      source  = "loafoe/ssh"
      version = "1.2.0"
    }

    null = {
      version = "~> 3.0.0"
    }

  }
}

provider "ssh" {
  # Configuration options

}


# K8S Control Panel
resource "null_resource" "k8s-cpnl" {
  # Changes to any instance of the cluster requires re-provisioning
  depends_on = []
  triggers = {
    always_run = "${timestamp()}"
  }
  connection {
    type        = "ssh"
    user        = var.ssh_user_name
    timeout     = "500s"
    private_key = file(var.ssh_key_priv)
    host        = var.ssh_host_name_k8s_cpnl
  }
  provisioner "local-exec" {
    command = "echo ' ' >> ${var.name_prefix}.log"
  }
  provisioner "local-exec" {
    command = "echo 'CTM Prep: \"${var.ssh_host_name_k8s_cpnl}\"' >> ${var.name_prefix}.log"
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"OS Prep\"",
      "sudo mkdir -p ${var.project_setup_dir}/os",
      "sudo mkdir -p ${var.project_setup_dir}/config",
    ]
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = var.ssh_user_name
      timeout     = "500s"
      private_key = file(var.ssh_key_priv)
      host        = var.ssh_host_name_k8s_cpnl
    }
    source      = "./os/"
    destination = "${var.project_setup_dir}/"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = var.ssh_user_name
      timeout     = "500s"
      private_key = file(var.ssh_key_priv)
      host        = var.ssh_host_name_k8s_cpnl
    }
    source      = "./config/"
    destination = "${var.project_setup_dir}/config/"
  }


  provisioner "remote-exec" {
    inline = [
      "echo \"User Prep\"",
      # Execute user setup script
      "sudo chmod +x ${var.project_setup_dir}/setup.*.sh",
      "sudo ${var.project_setup_dir}/setup.rhel.base.sh",

      # Authentication and Security
      # "sudo ${var.project_setup_dir}/setup.user.security.sh",       

      # Clean-Up prior install
      # "sudo ${var.project_setup_dir}/setup.clean.up.sh",

      # Create users and groups
      # "sudo ${var.project_setup_dir}/setup.user.sh",

      # DNS Update
      # "sudo ${var.project_setup_dir}/setup.dns.sh",

      # NFS Server
      # "sudo ${var.project_setup_dir}/setup.nfs.server.sh",      

      # NFS Client
      # "sudo ${var.project_setup_dir}/setup.nfs.client.sh"

    ]
  }
}
