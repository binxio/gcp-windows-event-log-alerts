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
