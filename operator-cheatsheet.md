# NGS v2 — Stack Deployer Operator Cheat‑Sheet (One Page)

**Scope:** Subscription-scope Deployment Stack for Net Guard (v2.1.2).  
**Defaults:** Incremental mode · `action_on_unmanage=detach` · `denyWriteAndDelete` · subnet `join/*` actions excluded.

---

## Day‑0 (once per machine)
- Terraform ≥ 1.5  
- `jq 1.6` installed (Ubuntu 22.04/WSL: `sudo apt install -y jq` → expect `jq-1.6`)  
- az login or SP credentials ready

## Deploy
```bash
cp terraform.tfvars.example terraform.tfvars
# edit subscription_id, location, stack_name, template_file

terraform init -upgrade
terraform apply
```

## Common Ops
- **What changed?** – `terraform plan`
- **Update denies mode** – set `deny_mode = "none" | "denyDelete" | "denyWriteAndDelete"` → `terraform apply`
- **Rotate bypass** – update `excluded_principals` (valid AAD **objectIds** only), `terraform apply`
- **Remove stack** – `terraform destroy` (resources remain due to Incremental + detach)

## Expected Behaviour (essentials)
- Non‑exempt actors **cannot** write/delete protected resources (denies).  
- Exempt actors **can** drift/delete; next **Apply** restores exported state (name/RG must still match).
- Properties **omitted** by exporter are **not enforced** by Apply.
- Unmanaged resources are **left alone** (Incremental + detach).

## Quick Fixes
**Deny failure:**  
- Ensure deployer has permission `Microsoft.Resources/deploymentStacks/manageDenySetting/action` (role: **Azure Deployment Stack Owner**).  
- Bad `excluded_principals` GUID → fix to valid tenant objectIds.  
- For diagnosis: set `deny_mode = "none"` → apply → then re‑enable.

**Cross‑RG ID failures:**  
- Re‑export or correct hardcoded IDs if target RG/name changed since export.

**What‑If noise on RO fields:**  
- Ignore (Azure will not apply RO changes).

## jq 1.6 quick check (WSL Ubuntu 22.04)
```bash
jq --version          # expect jq-1.6
sudo apt update && sudo apt install -y jq
# Fallback (user-scoped):
# mkdir -p ~/.local/bin && curl -L -o ~/.local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && chmod +x ~/.local/bin/jq
```

---

**Tip:** To avoid GUID errors, resolve UPNs/appIds → objectIds with `azuread` data sources in TF and feed those into `excluded_principals`.
