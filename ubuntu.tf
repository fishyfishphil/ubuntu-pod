locals {
  pvc_name = "ubuntu-pvc"
}

resource "kubernetes_namespace" "test" {
  metadata {
    name = "test"
  }
}

resource "kubernetes_stateful_set_v1" "ubuntu" {
  metadata {
    name      = "ubuntu"
    namespace = kubernetes_namespace.test.metadata[0].name
  }

  spec {
    selector {
      match_labels = {
        app = "ubuntu"
      }
    }

    service_name = "ubuntu"
    replicas     = 3

    template {
      metadata {
        labels = {
          app = "ubuntu"
        }
      }

      spec {
        container {
          name    = "ubuntu"
          image   = "ubuntu:22.04"
          command = ["/bin/sleep", "infinity"]

          volume_mount {
            name       = "ubuntu-volume"
            mount_path = "/data"
          }
        }

        volume {
          name = "ubuntu-volume"
          persistent_volume_claim {
            claim_name = local.pvc_name
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "ubuntu-volume"
      }

      spec {
        storage_class_name = "ebs-gp3"
        access_modes       = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "1Gi"
          }
        }
      }
    }
  }
}

resource "kubernetes_pod_disruption_budget_v1" "ubuntu_pdb" {
  metadata {
    name      = "ubuntu-pdb"
    namespace = kubernetes_namespace.test.metadata[0].name
  }

  spec {
    selector {
      match_labels = {
        app = "ubuntu"
      }
    }

    max_unavailable = 1
  }
}
