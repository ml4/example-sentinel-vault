# Example Sentinel Policy Use With Vault Enterprise

This example uses an HR department policy for KV storage in Vault.

Once you have access to your Vault Enterprise instance (i.e. not an OSS/homebrew etc. deployment), and have instantiated VAULT_TOKEN in your env, from this repo gitroot, install the base HR department example policy and mount the KV secrets engine and write an example kv while logged in with the root or equivalent token somewhere where entites with the hr_policy policy attached to their token will then be able to retrieve:

```bash
sentinel test
PASS - cidr-check.sentinel
  PASS - test/cidr-check/fail.hcl
  PASS - test/cidr-check/success.hcl

unset VAULT_TOKEN                                    # this takes precedence over operations below
pushd vault_acl_policies
vault policy write hr_policy ./hr_policy.hcl
vault policy list
vault policy read hr_policy
popd

vault secrets enable -path=secret kv
Success! Enabled the kv secrets engine at: secret/

vault kv put secret/hr/employees/frank social=123-456-789
Success! Data written to: secret/hr/employees/frank

vault secrets list

Path          Type         Accessor              Description
----          ----         --------              -----------
cubbyhole/    cubbyhole    cubbyhole_ea86e0c0    per-token private secret storage
identity/     identity     identity_3c08cf50     identity store
secret/       kv           kv_9227c0a3           n/a
sys/          system       system_3cde701e       system endpoints used for control, policy and debugging

vault kv get secret/hr/employees/frank
===== Data =====
Key       Value
---       -----
social    123-456-789

```

We will then limit this path with an endpoint-governing policy. Next you need to base64 encode the policy file for ingress into vault.  Do this with:

```bash
pushd example
policy=$(base64 ./cidr-check.sentinel)
vault write sys/policies/egp/hr_policy policy="${policy}" paths="secret/hr/*,secret/data/hr/*" enforcement_level="hard-mandatory"

Success! Data written to: sys/policies/egp/hr_policy
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

Retrying:

```
# vault write sys/policies/egp/hr_policy policy="${policy}" paths="secret/hr/*,secret/data/hr/*" enforcement_level="hard-mandatory"
Success! Data written to: sys/policies/egp/hr_policy
```

Now try reading the policy back
```bash
vault read sys/policies/egp/hr_policy
Key                  Value
---                  -----
enforcement_level    hard-mandatory
name                 hr_policy
paths                [secret/hr/* secret/data/hr/*]
policy               import "sockaddr"
import "strings"

# Only care about create, list, update, and delete operations against secret path
precond = rule {
	request.operation in ["create", "list", "update", "delete"] and
	strings.has_prefix(request.path, "secret/")
}

# Requests to come only from our private IP range
cidrcheck = rule {
	sockaddr.is_contained(request.connection.remote_addr, "122.22.3.4/32")
}

# Check the precondition before execute the cidrcheck
main = rule when precond {
	cidrcheck
}

```

Now create a token with the hr_policy attached:
```bash
vault token create policy hr_policy

$ vault token create -policy hr_policy
WARNING! The following warnings were returned from Vault:

  * Endpoint ignored these unrecognized parameters: [display_name entity_alias
  explicit_max_ttl num_uses period policies renewable ttl type]

Key                  Value
---                  -----
token                hvs.CAESIFYhaz65JXwkEUoUo-XL0v7N54JC7E3B_xYzgLQKpu-sGiAKHGh2cy52ajV3c1ZLeGRqeGFqM0tZNVVRb0pBMWUQKA
token_accessor       ua96Doy7WnrCvLDwX48pOpGz
token_duration       768h
token_renewable      true
token_policies       ["default" "hr_policy"]
identity_policies    []
policies             ["default" "hr_policy"]
```

Now login to Vault using the above token
```bash
vault login
Token (will be hidden):
WARNING! The VAULT_TOKEN environment variable is set! The value of this
variable will take precedence; if this is unwanted please unset VAULT_TOKEN or
update its value accordingly.

Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                hvs.CAESIFYhaz65JXwkEUoUo-XL0v7N54JC7E3B_xYzgLQKpu-sGiAKHGh2cy52ajV3c1ZLeGRqeGFqM0tZNVVRb0pBMWUQKA
token_accessor       ua96Doy7WnrCvLDwX48pOpGz
token_duration       767h58m59s
token_renewable      true
token_policies       ["default" "hr_policy"]
identity_policies    []
policies             ["default" "hr_policy"]
```


