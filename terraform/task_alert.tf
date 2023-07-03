## Email notification channel
resource "google_monitoring_notification_channel" "scheduled_task_status_email" {
  project      = var.project_id
  display_name = "Scheduled task status emails"
  type         = "email"
  labels = {
    email_address = var.notification_email
  }
}

## FailureTask alert; sends an email on FailureTask error.
resource "google_monitoring_alert_policy" "failuretask_failed" {
  project = var.project_id

  display_name = "FailureTask failed"

  notification_channels = [
    google_monitoring_notification_channel.scheduled_task_status_email.id,
  ]

  documentation {
    mime_type = "text/markdown"
    content   = <<EOT
    FailureTask failed!

    Connect to the active VM and resolve the issue by checking logs at ...
    EOT
  }

  combiner = "OR"
  conditions {
    display_name = "task_failed"
    condition_matched_log {
      filter = <<EOT
      resource.type="gce_instance"
      jsonPayload.Channel="Microsoft-Windows-TaskScheduler/Operational"
      jsonPayload.EventID="201"
      jsonPayload.StringInserts="\\FailureTask"
      jsonPayload.Message !~ "return code 0\.$"
      EOT
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "3600s"
    }

    auto_close = "1800s"
  }
}

## FailureTask alert; sends an email on FailureTask not running.
resource "google_logging_metric" "failuretask_not_running" {
  project = var.project_id
  name   = "task-runner/failuretask_run_count"

  filter = <<EOT
  resource.type="gce_instance"
  jsonPayload.Channel="Microsoft-Windows-TaskScheduler/Operational"
  jsonPayload.EventID="201"
  jsonPayload.StringInserts="\\FailureTask"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"

    labels {
      key = "host_name"
      value_type = "STRING"
    }
  }

  label_extractors = {
    "host_name" = "EXTRACT(jsonPayload.Computer)"
  }
}

resource "google_monitoring_alert_policy" "failuretask_not_running" {
  project = var.project_id

  display_name = "FailureTask not running"

  notification_channels = [
    google_monitoring_notification_channel.scheduled_task_status_email.id,
  ]

  documentation {
    mime_type = "text/markdown"
    content   = <<EOT
    FailureTask not running!

    Ensure that the $${metadata.system_label.name} VM instance runs and the scheduled task is enabled ...
  
    [Quick link to the VM](https://console.cloud.google.com/compute/instancesDetail/zones/$${resource.label.zone}/instances/$${resource.label.instance_id}?project=$${resource.label.project_id})
    EOT
  }

  combiner = "OR"
  conditions {
    display_name = "FailureTask not running"

    condition_absent {
      filter = <<EOT
      resource.type = "gce_instance" AND metric.type = "logging.googleapis.com/user/${google_logging_metric.failuretask_not_running.name}"
      EOT
      aggregations {
        group_by_fields = [
          "metadata.system_labels.name",
        ]
        alignment_period = "300s"
        per_series_aligner = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_COUNT"
      }
      
      duration = "600s" # Fail after 10 minutes without events
      trigger {
        count = 1
      }
    }
  }

  alert_strategy {
    auto_close = "3600s"
  }
}