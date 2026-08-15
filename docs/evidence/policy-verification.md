# Policy verification evidence

This is static, subscription-free evidence. The CI workflow executes `terraform test` against
mocked AzureRM resources and proves these policy outcomes:

| Scenario | Expected result |
|---|---|
| `germanywestcentral`, complete tags, one replica, EUR 25 budget | plan accepted |
| unapproved region | rejected at `var.location` |
| missing `cost-center` tag | rejected at `var.governance_tags` |
| four replicas | rejected at `var.max_replicas` |
| EUR 101 monthly budget | rejected at `var.monthly_budget_eur` |

This file does not claim an Azure deployment. Live evidence is generated separately by the
read-only `scripts/demo.sh` after an explicitly approved deployment.
