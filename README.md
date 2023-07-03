# Windows event log alerts on GCP

Tired of checking your service statuses every day? Use the Windows event logs to send a notification as soon as a service fails.

## How it works

1. Forward Windows event log events to Cloud Logging

    Use the [Cloud Ops Agent](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent) to forward logs. Make sure to include the configuration to forward TaskScheduler logs:

    ```yaml
    logging:
    receivers:
      windows_event_log:
        type: windows_event_log
        channels: [System, Application, Security, "Microsoft-Windows-TaskScheduler/Operational"]
        receiver_version: 2
    ```

    Additionally, make sure to enable task execution history:

    `wevtutil set-log Microsoft-Windows-TaskScheduler/Operational /enabled:true`

2. Configure alert policies to send out notifications

    Add an alerting policy for scheduled task failures and inactive tasks.

    Task failure alert
    ```
    resource.type="gce_instance"

    -- Only "Action completed logs"
    jsonPayload.Channel="Microsoft-Windows-TaskScheduler/Operational"
    jsonPayload.EventID="201"

    -- Only logs for my task name and failure exit code.
    jsonPayload.StringInserts="\\FailureTask"
    jsonPayload.Message !~ "return code 0\.$"
    ```

    Inactive task logs metric and alert
    ```
    -- Filter action completed logs for scheduled task
    resource.type="gce_instance"
    jsonPayload.Channel="Microsoft-Windows-TaskScheduler/Operational"
    jsonPayload.EventID="201"
    jsonPayload.StringInserts="\\FailureTask"
    
    -- Alert on absent metrics
    condition_absent {
        ..
        filter = 'resource.type = "gce_instance" AND metric.type = "logging.googleapis.com/user/${google_logging_metric.failuretask_not_running.name}"'
        duration = "1800s"
        ..
    }
    ```


## Deployment

First, update the [Terraform variables](terraform/variables.tf) to deploy to your project and alert to your email address.

Second, run `terraform apply` to deploy an example VM that runs a failing scheduled task. It takes about 10 minutes before you receive the *Task failed*-alert.

Third, stop the VM to receive the *Task not running*-alert. This takes about 15 minutes.
