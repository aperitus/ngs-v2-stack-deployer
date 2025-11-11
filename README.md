# Net Guard Deployment Stack – Terraform Wrapper (NGS v2 · Application 2)

**Version:** 2.1.1  
**Author:** Andrew Clarke

## Pure Terraform usage
1. Copy the example tfvars and edit values:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # edit terraform.tfvars to point at your template file
   ```
2. Run:
   ```bash
   terraform init -upgrade
   terraform apply
   ```

## Notes
- Module targets `Microsoft.Resources/deploymentStacks@2024-03-01` with `schema_validation_enabled = false` by default.
- `action_on_unmanage` is an object with `managementGroups`, `resourceGroups`, `resources` each `detach|delete`.
- Keep exported subscription template aligned with NGS v2 baselines: RG-scoped nested deployments with `resourceGroup` set, inner resources with `location`, subnets use `addressPrefix`, cross-RG associations via fully-qualified `resourceId()`.

Files:
```
modules/stack-deployer/
  main.tf
  variables.tf
  locals.tf
  versions.tf
  outputs.tf
main.tf
variables.tf
terraform.tfvars.example
version.txt
CHANGELOG.md
README.md
```


### v2.1.1 – Subscription override & null-safe template/parameters
- **New:** `subscription_id` variable (root + module). If set, used for `parent_id`; else uses the provider’s active subscription.
- **Fix:** `parameters`/`template` are now **omitted** when unset (no `null`), via a `merge` of optional maps. This resolves
  `Invalid type. Expected Object but got Null` errors from the Deployment Stack schema.
