resource "google_project_service" "composer_api" {

  project = var.project_id
  service = "composer.googleapis.com"
  #prevent api from being disabled upon deletion of composer env
  disable_on_destroy = false
}


resource "google_compute_router" "composer-router" {
  name    = "composer-router"
  region  = "europe-west4"
  network = var.network_self_link

}

resource "google_compute_router_nat" "nat" {
  name                               = "composer-router-nat"
  router                             = google_compute_router.composer-router.name
  region                             = google_compute_router.composer-router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_composer_environment" "oracle-hfm-composer" {
  provider = google-beta
  name = "composer-${var.env}"
  config {
    workloads_config {

      scheduler {
        cpu = 0.5
        memory_gb = 1.875
        storage_gb = 1
      }
      triggerer {
        cpu = 0.5
        memory_gb = 0.5
        count = 1
      }
      web_server {
        cpu = 0.5
        memory_gb = 1.875
        storage_gb = 1
      }
      worker {
        cpu = 4
        memory_gb = 8
        storage_gb = 10
      }
    }
    environment_size = "ENVIRONMENT_SIZE_MEDIUM"
    node_config {
        network = var.network_self_link
        subnetwork = var.subnetwork_self_link
        service_account = var.service_account_email
    }
    private_environment_config {
        enable_private_endpoint = true
    }
    software_config {
      airflow_config_overrides = {
        email-email_backend = "airflow.utils.email.send_email_smtp"
        email-email_from = "####"
        email-email_conn_id = "outlook_smtp"
        secrets-backend = "airflow.providers.google.cloud.secrets.secret_manager.CloudSecretManagerBackend"      
      }
      
      image_version = "composer-2.6.2-airflow-2.6.3"
      pypi_packages = {
        pyspark = ""
        apache-airflow-providers-sendgrid = ""
        apache-airflow-providers-smtp = ""
        openpyxl = ""
        xlrd = ""
        numpy = ""
        toml = ""
        pandas_gbq = ""
      }
    } 
  }
  depends_on = [google_project_service.composer_api]
}

