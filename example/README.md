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

If you get the error
```
Error writing data to sys/policies/egp/hr_policy: Error making API request.

URL: PUT https://eun1.dev-vault-pipe.pi-ccn.org:8200/v1/sys/policies/egp/hr_policy
Code: 401. Errors:

* 1 error occurred:
	* Feature Not Enabled
```

it is because you need to purchase the Vault Enterprise Plus module to get access to Sentinel policy-as-code.  Once you have an upodated licence in place, rerun the command to write the EGP.

