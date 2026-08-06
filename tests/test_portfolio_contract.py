from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]


class PortfolioContractTests(unittest.TestCase):
    def read(self, relative_path: str) -> str:
        return (ROOT / relative_path).read_text(encoding="utf-8")

    def test_platform_resources_are_present(self) -> None:
        terraform = self.read("terraform/main.tf") + self.read("terraform/monitoring.tf")
        expected = {
            "azurerm_container_app",
            "azurerm_key_vault",
            "azurerm_log_analytics_workspace",
            "azurerm_user_assigned_identity",
            "azurerm_consumption_budget_resource_group",
            "azurerm_private_endpoint",
            "azurerm_private_dns_zone",
            "azurerm_network_security_group",
            "azurerm_subnet_network_security_group_association",
        }
        for resource in expected:
            self.assertRegex(terraform, rf'resource\s+"{resource}"')

    def test_workload_is_small_and_scales_to_zero(self) -> None:
        main = self.read("terraform/main.tf")
        self.assertIn("min_replicas = 0", main)
        self.assertIn("max_replicas = 1", main)
        self.assertIn("cpu    = 0.25", main)
        self.assertIn('memory = "0.5Gi"', main)

    def test_production_rejects_latest_image_tag(self) -> None:
        main = self.read("terraform/main.tf")
        self.assertIn('var.environment != "prod"', main)
        self.assertIn('!endswith(var.container_image, ":latest")', main)

    def test_key_vault_has_no_public_network_path(self) -> None:
        main = self.read("terraform/main.tf")
        self.assertIn("public_network_access_enabled = false", main)
        self.assertIn('default_action = "Deny"', main)
        self.assertIn('name                = "privatelink.vaultcore.azure.net"', main)

    def test_apply_requires_oidc_and_explicit_confirmation(self) -> None:
        workflow = self.read(".github/workflows/terraform-apply.yml")
        self.assertRegex(workflow, r"id-token:\s*write")
        self.assertIn("environment: production", workflow)
        self.assertIn("inputs.confirmation == 'apply'", workflow)
        self.assertNotIn("client-secret", workflow.lower())

    def test_no_secret_values_are_committed(self) -> None:
        allowed = {"tests/test_portfolio_contract.py"}
        suspicious = re.compile(r"(?i)(client_secret|password)\s*=\s*\"[^\"]+\"")
        for path in ROOT.rglob("*"):
            if not path.is_file() or ".git" in path.parts or str(path.relative_to(ROOT)) in allowed:
                continue
            if path.suffix.lower() not in {".tf", ".yml", ".yaml", ".md", ".sh"}:
                continue
            self.assertIsNone(suspicious.search(path.read_text(encoding="utf-8")), path)


if __name__ == "__main__":
    unittest.main()
