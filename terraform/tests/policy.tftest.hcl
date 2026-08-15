mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "11111111-2222-3333-4444-555555555555"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      client_id       = "66666666-7777-8888-9999-000000000000"
      object_id       = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    }
  }
}

run "approved_defaults" {
  command = plan

  assert {
    condition     = azurerm_container_app.demo.template[0].max_replicas == 1
    error_message = "Default Container App scale must remain capped at one replica."
  }

  assert {
    condition     = azurerm_resource_group.platform.tags["cost-center"] == "portfolio"
    error_message = "Required cost-center tag was not applied to the resource group."
  }
}

run "reject_unapproved_region" {
  command = plan
  variables { location = "eastus" }
  expect_failures = [var.location]
}

run "reject_missing_governance_tag" {
  command = plan
  variables {
    governance_tags = {
      owner   = "platform-team"
      purpose = "portfolio-lab"
    }
  }
  expect_failures = [var.governance_tags]
}

run "reject_excess_scale" {
  command = plan
  variables { max_replicas = 4 }
  expect_failures = [var.max_replicas]
}

run "reject_excess_budget" {
  command = plan
  variables { monthly_budget_eur = 101 }
  expect_failures = [var.monthly_budget_eur]
}
