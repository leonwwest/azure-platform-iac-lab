# ADR 0001: Enforce portfolio guardrails with Terraform-native policy tests

## Decision

Region, required tags, maximum scale and budget bounds are variable validations. Native
`terraform test` scenarios prove both accepted defaults and actionable rejection paths.

## Consequences

The rules run offline and during normal Terraform verification without a separate policy runtime.
They govern this module, not an Azure management group; organization-wide enforcement would add
Azure Policy assignments at the platform boundary.
