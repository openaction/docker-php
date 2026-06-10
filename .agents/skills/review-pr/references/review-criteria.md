# Review Criteria

Use this checklist while analyzing the PR diff and related context.

## 1. Functional Correctness

- Verify the change solves the stated problem in PR title/body and linked
  Linear issue when present.
- Check control flow, null/empty handling, and boundary conditions.
- Look for regressions in adjacent behavior and call sites.
- Confirm migrations/config changes are safe for existing environments.

## 2. Security and Data Safety

- Identify injection risks, unsafe deserialization, and auth/permission gaps.
- Check handling of secrets, tokens, and PII in code and logs.
- Verify user input is validated and output is escaped where required.
- Flag dangerous defaults, overly broad permissions, and missing safeguards.

## 3. Performance and Scalability

- Check for N+1 queries, unbounded loops, and expensive repeated work.
- Review network/file/database calls inside hot paths.
- Validate caching and pagination strategy when data volume can grow.
- Evaluate algorithmic complexity changes.

## 4. Reliability and Operations

- Verify failure paths, retries, and timeout behavior.
- Check idempotency for jobs/commands that may re-run.
- Validate observability: useful logs, metrics hooks, and error context.
- Confirm health/readiness or background task behavior when relevant.

## 5. Readability and Maintainability

- Ensure naming, structure, and abstractions are clear.
- Detect duplicated logic and hidden coupling.
- Avoid unnecessary few-line private methods; prefer inline logic unless
  extraction clearly improves reuse or readability.
- Check backward compatibility for public contracts and interfaces.
- Verify docs/comments are updated for non-obvious behavior.

## 6. Testing and Validation

- Confirm tests cover happy paths, edge cases, and failure paths.
- Validate assertions are meaningful and not overly implementation-specific.
- Check that missing tests are called out when risk is non-trivial.
- Cross-check CI check results for failing or skipped critical jobs.

## Severity Mapping

- Blocker: must be fixed before merge; risk of bugs, data loss, or security
  issues.
- Important: should be fixed before merge; high-confidence quality risk.
- Nit: optional polish; no material product risk.
- Question: clarification needed before confidence is high.
- Praise: highlight effective design, testing, or clarity choices.
