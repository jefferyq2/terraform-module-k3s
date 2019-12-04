locals {
  server_default_flags = [
    "--node-ip ${var.server_node.ip}",
    "--node-name ${var.server_node.name}",
    "--cluster-domain ${var.cluster_name}",
    "--cluster-cidr ${var.cluster_cidr.pods}",
    "--service-cidr ${var.cluster_cidr.services}",
    "--token ${random_password.k3s_cluster_secret.result}",
  ]
  server_install_flags = join(" ", concat(var.additional_flags.server, local.server_default_flags))
}

resource null_resource k3s_server {
  triggers = {
    install_args = sha1(local.server_install_flags)
  }

  connection {
    type = lookup(var.server_node.connection, "type", "ssh")

    host     = lookup(var.server_node.connection, "host", var.server_node.ip)
    user     = lookup(var.server_node.connection, "user", null)
    password = lookup(var.server_node.connection, "password", null)
    port     = lookup(var.server_node.connection, "port", null)
    timeout  = lookup(var.server_node.connection, "timeout", null)

    script_path    = lookup(var.server_node.connection, "script_path", null)
    private_key    = lookup(var.server_node.connection, "private_key", null)
    certificate    = lookup(var.server_node.connection, "certificate", null)
    agent          = lookup(var.server_node.connection, "agent", null)
    agent_identity = lookup(var.server_node.connection, "agent_identity", null)
    host_key       = lookup(var.server_node.connection, "host_key", null)

    https    = lookup(var.server_node.connection, "https", null)
    insecure = lookup(var.server_node.connection, "insecure", null)
    use_ntlm = lookup(var.server_node.connection, "use_ntlm", null)
    cacert   = lookup(var.server_node.connection, "cacert", null)

    bastion_host        = lookup(var.server_node.connection, "bastion_host", null)
    bastion_host_key    = lookup(var.server_node.connection, "bastion_host_key", null)
    bastion_port        = lookup(var.server_node.connection, "bastion_port", null)
    bastion_user        = lookup(var.server_node.connection, "bastion_user", null)
    bastion_password    = lookup(var.server_node.connection, "bastion_password", null)
    bastion_private_key = lookup(var.server_node.connection, "bastion_private_key", null)
    bastion_certificate = lookup(var.server_node.connection, "bastion_certificate", null)
  }

  # Check if curl is installed
  provisioner remote-exec {
    inline = [
      "if ! command -V curl > /dev/null; then echo >&2 '[ERROR] curl must be installed to continue...'; exit 127; fi",
    ]
  }

  # Remove old k3s installation
  provisioner remote-exec {
    inline = [
      "if ! command -V k3s-uninstall.sh > /dev/null; then exit; fi",
      "echo >&2 [WARN] K3S seems already installed on this node and will be uninstalled.",
      "k3s-uninstall.sh",
    ]
  }
}

resource null_resource k3s_server_installer {
  triggers = {
    server_init = null_resource.k3s_server.id
    version     = local.k3s_version
  }
  depends_on = [
  null_resource.k3s_server]

  connection {
    type = lookup(var.server_node.connection, "type", "ssh")

    host     = lookup(var.server_node.connection, "host", var.server_node.ip)
    user     = lookup(var.server_node.connection, "user", null)
    password = lookup(var.server_node.connection, "password", null)
    port     = lookup(var.server_node.connection, "port", null)
    timeout  = lookup(var.server_node.connection, "timeout", null)

    script_path    = lookup(var.server_node.connection, "script_path", null)
    private_key    = lookup(var.server_node.connection, "private_key", null)
    certificate    = lookup(var.server_node.connection, "certificate", null)
    agent          = lookup(var.server_node.connection, "agent", null)
    agent_identity = lookup(var.server_node.connection, "agent_identity", null)
    host_key       = lookup(var.server_node.connection, "host_key", null)

    https    = lookup(var.server_node.connection, "https", null)
    insecure = lookup(var.server_node.connection, "insecure", null)
    use_ntlm = lookup(var.server_node.connection, "use_ntlm", null)
    cacert   = lookup(var.server_node.connection, "cacert", null)

    bastion_host        = lookup(var.server_node.connection, "bastion_host", null)
    bastion_host_key    = lookup(var.server_node.connection, "bastion_host_key", null)
    bastion_port        = lookup(var.server_node.connection, "bastion_port", null)
    bastion_user        = lookup(var.server_node.connection, "bastion_user", null)
    bastion_password    = lookup(var.server_node.connection, "bastion_password", null)
    bastion_private_key = lookup(var.server_node.connection, "bastion_private_key", null)
    bastion_certificate = lookup(var.server_node.connection, "bastion_certificate", null)
  }

  # Install K3S server
  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${local.k3s_version} sh -s - ${local.server_install_flags}",
      "until kubectl get nodes | grep -v '[WARN] No resources found'; do sleep 1; done"
    ]
  }
}