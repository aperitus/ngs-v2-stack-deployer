# Net Guard Deployment Stack — **Stack Deployer** (NGS v2)

> Version **2.1.2** · Author: Andrew Clarke · License: MIT

**BLUF:** This Terraform module wraps your **subscription-scope** network baseline (exported by the NGS v2 Template Exporter) into a **Deployment Stack**. It enforces drift control with **denySettings** and safe lifecycle with **action_on_unmanage=detach**, while keeping the canonical NGS rules: subscription-scope outer template; nested RG deployments with **`resourceGroup` only** (no nested `location`); and no forced writes to omitted/empty properties.

---

## Features

- **Subscription-scope** `Microsoft.Resources/deploymentStacks@2024-03-01` via `azapi_resource`.
- Default **action_on_unmanage = detach** across **managementGroups / resourceGroups / resources**.
- **denySettings**: `none | denyDelete | denyWriteAndDelete`, with:
  - `excluded_principals` (AAD object IDs)  
  - `excluded_actions` (e.g., `Microsoft.Network/virtualNetworks/subnets/join/action`, etc.)
- Inputs accept **file** or **inline** for both template and parameters.
- Providers pinned: `azapi >= 2.0.0`, `azurerm >= 3.114.0`.
- Deterministic behaviour aligned to NGS v2 exporter output.

> **Out of scope:** Policy/Role guard rails (apply your subscription deny wrappers in a separate repo).

---

## Host Requirements

- Terraform ≥ 1.5
- Azure CLI or SP login that can deploy stacks
- **Permissions:** if using `denyDelete` / `denyWriteAndDelete`, your deployer needs  
  `Microsoft.Resources/deploymentStacks/manageDenySetting/action` (built-in **Azure Deployment Stack Owner** includes this).
- **jq 1.6** available in shell (**used by helper scripts, JSON merging, and CI checks**).

### jq 1.6 on Ubuntu 22.04 (WSL)

Ubuntu 22.04’s main repo already ships **jq 1.6**. Choose one of the following:

**Option A — apt (recommended)**
```bash
sudo apt update
sudo apt install -y jq
jq --version   # expect: jq-1.6
```

**Option B — replace a wrong version**
```bash
jq --version
# if not jq-1.6:
sudo apt remove -y jq
sudo apt update
sudo apt install -y jq
jq --version   # jq-1.6
```

**Option C — user-scoped static binary (fallback)**
```bash
mkdir -p ~/.local/bin
curl -L -o ~/.local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x ~/.local/bin/jq
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
jq --version   # jq-1.6
```
This overrides the system jq if `~/.local/bin` appears before `/usr/bin` on your PATH.

---

## Quick Start

```bash
# 1) Prepare variables (example)
cp terraform.tfvars.example terraform.tfvars

# 2) Edit terraform.tfvars
# - subscription_id = "f4fcc361-3c53-4f6a-8481-3cfa654bb1c7"
# - location        = "uksouth"
# - stack_name      = "ds-ngs-v2-demo"
# - template_file   = "./main.subscription.json"   # exported wrapper
# - deny_mode       = "denyWriteAndDelete"         # or "denyDelete" / "none"

terraform init -upgrade
terraform apply
```

**Notes:**
- The **exporter output** should contain RG-scoped nested deployments with `resourceGroup` set and **no nested `location`** — this module assumes that baseline.
- If you need to diagnose permissions, set `deny_mode = "none"` once to verify the template path, then re-enable denies.

---

## Inputs

All variables are multi-line in HCL files (readability rule).

```hcl
variable "subscription_id" { type = string }
variable "location"        { type = string }
variable "stack_name"      { type = string }

variable "template_file"    { type = string default = null } # path to exported subscription template
variable "template_content" { type = string default = null } # inline JSON override

variable "parameters_file"  { type = string default = null } # path to ARM params
variable "parameters_json"  { type = string default = null } # inline JSON override

variable "deny_mode"       { type = string default = "denyWriteAndDelete" } # none|denyDelete|denyWriteAndDelete
variable "excluded_principals" { type = list(string) default = [] }        # AAD object IDs (tenant-local)
variable "excluded_actions"    { type = list(string) default = [
  "Microsoft.Network/virtualNetworks/subnets/join/action",
  "Microsoft.Network/virtualNetworks/subnets/joinViaServiceEndpoint/action",
  "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
  "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
]}

variable "tags" { type = map(string) default = {
  project   = "net-guard-stack"
  component = "stack-deployer"
}}

variable "schema_validation_enabled" { type = bool default = false } # azapi schema lint toggle

variable "action_on_unmanage" {
  type = object({
    managementGroups = string
    resourceGroups   = string
    resources        = string
  })
  default = {
    managementGroups = "detach"
    resourceGroups   = "detach"
    resources        = "detach"
  }
}
```

**Tip:** To avoid GUID mistakes, consider adding the `azuread` provider and resolving UPNs/appIds to objectIds via `data.azuread_*` data sources, then pass those IDs into `excluded_principals`.

---

## Expected Behaviour Matrix (ratified)

Assumptions for this matrix: **Incremental** mode; **action_on_unmanage=detach**; **denyWriteAndDelete**; subnets’ `join/*` actions excluded; optionally excluding `Microsoft.Resources/deployments/*` when necessary.

**Legend**
- **Apply** = run the stack again
- **Non-exempt** = identity blocked by stack deny
- **Exempt** = in `excluded_principals` (bypass)
- **RO** = read-only/derived by Azure
- **Omitted** = exporter omitted empty/null properties (won’t be enforced)

| Resource / Property | State change | Before stack created | After stack: changed by **non-exempt** | After stack: changed by **exempt** | On next **Apply** | Notes |
|---|---|---|---|---|---|---|
| **Resource Group** (wrapper nests) | Add/remove RG | N/A | Blocked | Allowed | Only what’s in template is (re)deployed; unmanaged RGs not deleted | Incremental + detach |
| **VNet** (address space, DNS, tags) | Deleted | Re-created by Apply | Delete blocked | Allowed | Re-created (same name/RG) |  |
|  | Config edited | Apply restores exported values | Blocked | Persists | Overwritten to exported values |  |
|  | RO fields (peeringSyncLevel) | Irrelevant | Irrelevant | Irrelevant | Ignored; What-If noise |  |
| **Subnet** (prefix, associations, policies) | Deleted | Re-created under VNet | Delete blocked | Allowed | Re-creates & **re-associates** RT/NSG/NAT if emitted |  |
|  | RT/NSG/NAT association removed/changed | Apply restores associations | Blocked | Persists | Restored to exported IDs |  |
|  | Service Endpoints | Removed/added | Apply sets exported non-empty list | Blocked | Persists | Restored only if emitted; omitted means no repair |
|  | Delegations | Removed/added | Same as endpoints | Blocked | Persists | Restored only if emitted |
|  | `privateEndpointNetworkPolicies` / `privateLinkServiceNetworkPolicies` | Flipped | If emitted, Apply sets; if null at export → omitted | Blocked | Persists | Restored only if emitted |
| **Route Table** (routes, tags) | Deleted | Re-created | Delete blocked | Allowed | Re-created & re-associated via subnets |  |
|  | Routes edited | Apply resets to exported routes | Blocked | Persists | Overwritten to exported |  |
| **NSG** (rules, tags) | Deleted | Re-created | Delete blocked | Allowed | Re-created with exported rules |  |
|  | Rules edited | Apply resets to exported | Blocked | Persists | Overwritten to exported |  |
| **NAT Gateway** (+ PIP/PIPP) | Deleted | Re-created; associations restored if emitted | Delete blocked | Allowed | Re-created; subnets regain NAT association if emitted |  |
|  | PIP/PIPP swapped | Apply restores exported refs | Blocked | Persists | Overwritten to exported refs |  |
| **Public IP / Public IP Prefix** | Deleted | Re-created if in template | Delete blocked | Allowed | Re-created if exported; otherwise unmanaged |  |
| **VNet Gateway** (+ PIP refs, RO status) | Deleted | Re-created with exported config | Delete blocked | Allowed | Re-created; RO diagnostic/status ignored |  |
|  | BGP / connections | Apply restores exported | Blocked | Persists | Overwritten to exported |  |
| **VNet Peering** | Deleted | Re-created from each emitted side | Delete blocked | Allowed | Re-created; RO sync fields ignored |  |
| **Tags** | Changed/removed | Apply resets to exported | Blocked | Persists | Overwritten to exported | Unless you purposely omit tags in exporter |
| **Resources not in template** | Any | N/A | N/A | N/A | Left untouched | Incremental + detach |

**Cross-RG & special cases**

- **Cross-RG dependencies** (peerings, NAT/VNetGW→PIP/PIPP): template `dependsOn` enforces order. If a **remote RG/ID** was renamed post-export, Apply will fail resolving the ID → re-export or fix IDs.
- **Managed RGs** (AKS `MC_*`, platform RGs): platform deny assignments can block nested RG deployments. Exclude such RGs from export/deploy.
- **Denies vs Apply**:  
  - **Non-exempt** actors cannot write/delete protected resources.  
  - **Exempt** actors can drift; next **Apply** will restore the exported state **if** names/RGs still match and wrapper has rights.
- **Omitted properties**: exporter intentionally omits empty/null values; Apply will **not** enforce those. To enforce later, ensure property is **non-empty at export time**.

---

## Example Usage (module)

```hcl
module "stack_deployer" {
  source          = "./modules/stack-deployer"

  subscription_id = var.subscription_id
  location        = var.location
  stack_name      = var.stack_name

  template_file   = var.template_file         # or template_content
  parameters_file = var.parameters_file       # or parameters_json

  deny_mode            = var.deny_mode        # none | denyDelete | denyWriteAndDelete
  excluded_principals  = var.excluded_principals
  excluded_actions     = var.excluded_actions

  tags                      = var.tags
  schema_validation_enabled = var.schema_validation_enabled

  action_on_unmanage = var.action_on_unmanage
}
```

---

## Troubleshooting

**`DeploymentStackDenyAssignmentFailure`**
- Ensure deployer has **Azure Deployment Stack Owner** (or a custom role including `Microsoft.Resources/deploymentStacks/manageDenySetting/action`).
- Verify **every** GUID in `excluded_principals` exists in **this tenant**; bad GUIDs cause `InvalidCreateDenyAssignmentRequest`.
- Temporarily set `deny_mode = "none"` to prove the template path; then re-enable.

**Policy conflicts**
- If you run a subscription policy that denies stack operations, add an **exemption** for your deployer during stack lifecycle.

**What-If noise on RO fields**
- Safe to ignore; Azure reports but won’t apply changes to RO properties.

---

## Logging & Debug

- Terraform: `TF_LOG=INFO|DEBUG`
- azapi schema lint: toggle `schema_validation_enabled` (default `false`)

---

## Versioning

- Semantic: **major.minor.build** (this module starts at **2.0.0**; current **2.1.2**).
- Track changes in `CHANGELOG.md`.

---

## Security Notes

- No credentials stored. Uses provider auth context.
- `excluded_principals` are **tenant-scoped** AAD object IDs; keep them current.
- Prefer re-exporting before roll-forward if an exempt actor made approved changes.

---

## FAQ

**Q:** Do nested RG deployments set `location`?  
**A:** No. The exporter emits RG-scoped `Microsoft.Resources/deployments` with **only `resourceGroup`**; nested `location` is omitted by design.

**Q:** Will unmanaged resources be deleted?  
**A:** No. Mode is **Incremental**, and `action_on_unmanage=detach`.

**Q:** Can I keep denies off?  
**A:** Yes, set `deny_mode = "none"` (useful for diagnostics). For protection, prefer `denyDelete` or `denyWriteAndDelete`.
