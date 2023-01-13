# Example

This example uses an HR department policy for KV storage in Vault.

Once you have access to your Vault Enterprise instance (i.e. not an OSS/homebrew etc deployment), and have instantiated VAULT_TOKEN in your env, run

```bash
vault policy write hr_policy ./hr_policy.hcl
vault policy list


```

which provides the policy to Vault. Next you need to base64 encode the policy file for ingress
into vault.  Do this with:

```bash
policy=$(base64 ./cidr_check.sentinel)
vault write sys/policies/egp/hr_policy policy="${policy}" paths="secret/hr/*,secret/data/hr/*" enforcement_level="hard-mandatory"


```

