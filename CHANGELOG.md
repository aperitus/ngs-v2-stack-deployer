# Changelog

## 2.1.0
- Pure Terraform distribution (no bash). Root example with variables and `terraform.tfvars.example`.

## 2.1.1
- Add `subscription_id` variable and use `coalesce()` to compute parent subscription.
- Omit `parameters`/`template` keys when unset to satisfy schema (no nulls).
