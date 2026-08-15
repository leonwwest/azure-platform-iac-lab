# ADR 0002: Separate plan and apply identities

## Decision

GitHub OIDC uses distinct environment identities for planning and applying. Apply is a manual
workflow with an exact confirmation input and a protected `production` environment.

## Consequences

Pull-request verification does not require a stored client secret or standing write credential.
The apply identity still needs carefully scoped Azure roles and its federated trust must be
reviewed as part of platform onboarding.
