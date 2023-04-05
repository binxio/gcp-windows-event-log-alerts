resource "google_service_account" "task_runner" {
  project      = var.project_id
  account_id   = "task-runner"
  display_name = "Task runner"
}

# Grant permissions to publish logs and metrics, source: https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent/authorization#use-service-account
resource "google_project_iam_member" "task_runner_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.task_runner.email}"
}

resource "google_project_iam_member" "task_runner_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.task_runner.email}"
}

# Task runner instance
resource "null_resource" "task_runner_replacement_trigger" {
  triggers = {
    "sysprep_script" = filesha256("${path.module}/assets/task_runner_sysprep.ps1")
  }
}

resource "google_compute_instance" "task_runner" {
  project      = var.project_id
  zone         = "europe-west4-a"
  name         = "task-runner"
  machine_type = "e2-medium"

  tags = [
    "allow-rdp-access",
  ]

  boot_disk {
    initialize_params {
      image = "projects/windows-cloud/global/images/family/windows-2022"
      size  = 50
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = google_compute_network.example.self_link
    subnetwork = google_compute_subnetwork.example_nl.self_link
  }

  service_account {
    email = google_service_account.task_runner.email
    scopes = [
      "cloud-platform",
    ]
  }

  # Install tooling -> https://cloud.google.com/compute/docs/instances/startup-scripts/windows#metadata-keys
  metadata = {
    "sysprep-specialize-script-ps1" = file("${path.module}/assets/task_runner_sysprep.ps1")
    "windows-startup-script-ps1"    = file("${path.module}/assets/task_runner_startup.ps1")
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.task_runner_replacement_trigger,
    ]
  }
}
