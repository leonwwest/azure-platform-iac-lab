resource "azurerm_monitor_action_group" "operations" {
  count = var.alert_email == "" ? 0 : 1

  name                = "ag-${local.suffix}"
  resource_group_name = azurerm_resource_group.platform.name
  short_name          = substr("ag-${var.environment}", 0, 12)
  tags                = local.tags

  email_receiver {
    name                    = "platform-owner"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "high_request_volume" {
  count = var.alert_email == "" ? 0 : 1

  name                = "alert-${local.suffix}-requests"
  resource_group_name = azurerm_resource_group.platform.name
  scopes              = [azurerm_container_app.demo.id]
  description         = "Portfolio guardrail for unexpectedly high request volume."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = local.tags

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "Requests"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 1000
  }

  action {
    action_group_id = azurerm_monitor_action_group.operations[0].id
  }
}

resource "azurerm_consumption_budget_resource_group" "platform" {
  count = length(var.budget_contact_emails) == 0 ? 0 : 1

  name              = "budget-${local.suffix}"
  resource_group_id = azurerm_resource_group.platform.id
  amount            = var.monthly_budget_eur
  time_grain        = "Monthly"

  time_period {
    start_date = "${formatdate("YYYY-MM", timestamp())}-01T00:00:00Z"
    end_date   = "2030-01-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = var.budget_contact_emails
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}
