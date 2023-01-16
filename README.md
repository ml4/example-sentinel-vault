# Example Sentinel Policy Use With Vault Enterprise

This example uses fictitious HR and Accounting department policy for KV storage access in Vault and provides step-by-step instructions on how to use Sentinel Endpoint Governing Policies with Vault Enterprise Plus to extend the standard Vault ACL policy engine weith applied examples from the documentation in [this HashiCorp tutorial on the subject](https://developer.hashicorp.com/vault/tutorials/policies/sentinel#write-sentinel-policies).

You current are recommended to test this repo with Sentinel 0.18.x or Sentinel 0.19.2-rc1. A known issue exists 0.19.1.  Credence to the HashiCorp Sentinel product, engineering and education teams.

## Unit Test Sentinel Policies Locally

Once you have access to your Vault Enterprise instance (i.e. not an OSS/homebrew etc. deployment), and have _unset_ VAULT_TOKEN in your env, from this repo gitroot, install the base example policies and mount the KV secrets engine while logged in with a privileged token as below.  We do not recommend keeping the root token once you have set up a Vault instance.

```bash
$ cd example-sentinel-vault
$ sentinel0.19.2-rc1 test
PASS - business-hrs.sentinel
  PASS - test/business-hrs/fail.hcl
  PASS - test/business-hrs/success.hcl
PASS - cidr-check.sentinel
  PASS - test/cidr-check/fail.hcl
  PASS - test/cidr-check/success.hcl

## Main EGP Setup For CIDR Checking and business hours guard rails
$ unset VAULT_TOKEN                        # this takes precedence over operations below
$ vault login                              # enter root or equivalent token for your dev instance
$ vault secrets enable -version=2 kv       # enable secrets engine at default path and check
$ vault secrets list

Path          Type         Accessor              Description
----          ----         --------              -----------
cubbyhole/    cubbyhole    cubbyhole_ea86e0c0    per-token private secret storage
identity/     identity     identity_3c08cf50     identity store
kv/           kv           kv_2787f70f           n/a
sys/          system       system_3cde701e       system endpoints used for control, policy and debugging

## if you are using this repo for demo, check what EGPs are in place and tidy
$ vault list sys/policies/egp
$ vault policy delete sys/policies/egp/hr_policy
$ vault policy delete sys/policies/egp/accounting_policy
```

## SIT CIDR Check Policy

In this README, it will be easier to run through the system integration testing iteratively by policy to prove the usefulness of Vault Sentinel clearly.
This section only deals with the CIDR check policy.  The next section will deal with business hour access management.

### Apply Normal Vault ACL Policy and Test

Go into the Vault ACL policies directory and apply the basic ACL policy to Vault to allow token-holders to write to the path.  Most command line responses are not shown for brevity.

```bash
$ pushd vault_acl_policies
$ vault policy write hr_policy ./hr_policy.hcl
$ vault policy list
$ vault policy read hr_policy
$ popd

$ vault kv put kv/hr/employees/frank social=123-456-789
======= Secret Path =======
kv/data/hr/employees/frank

======= Metadata =======
Key                Value
---                -----
created_time       2023-01-16T18:43:11.942514716Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
#
## writing to path OK
```

### Apply EGP to HR Policy

We will then limit this path with an endpoint-governing policy in this repo. First, base64 encode the policy file then write to Vault:

```bash
$ policy=$(base64 ./cidr-check.sentinel)
$ vault write sys/policies/egp/hr_policy policy="${policy}" \
  paths="kv/hr/*,kv/data/hr/*"                              \
  enforcement_level="hard-mandatory"

Success! Data written to: sys/policies/egp/hr_policy
```

Note governed paths match those in the [policy file](vault_acl_policies/hr_policy.hcl).
Read the Sentinel policy back to check:

```bash
$ vault read sys/policies/egp/hr_policy
Key                  Value
---                  -----
enforcement_level    hard-mandatory
name                 hr_policy
paths                [kv/hr/* kv/data/hr/*]
policy               import "sockaddr"
import "strings"

# Requests to come only from our private IP range
cidrcheck = rule {
	sockaddr.is_contained(request.connection.remote_addr, "192.168.10.10/24")
}

main = rule {
	cidrcheck
}
#
## OK
```

### SIT HR CIDR Check EGP

Now create a token with the `hr_policy` attached, login with it and attempt to read the path to Frank's information:

```bash
$ vault token create -policy hr_policy
WARNING! The following warnings were returned from Vault:

  * Endpoint ignored these unrecognized parameters: [display_name entity_alias
  explicit_max_ttl num_uses period policies renewable ttl type]

Key                  Value
---                  -----
token                hvs.snip
token_accessor       UtCsU8wZiSxAS75em3Fu2503
token_duration       768h
token_renewable      true
token_policies       ["default" "hr_policy"]
identity_policies    []
policies             ["default" "hr_policy"]
```

Now login with the token and confirm the policy attached is the hr_policy:

```bash
$ vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                hvs.snip
token_accessor       UtCsU8wZiSxAS75em3Fu2503
token_duration       767h59m41s
token_renewable      true
token_policies       ["default" "hr_policy"]
identity_policies    []
policies             ["default" "hr_policy"]
```

Now attempt to read from the path now managed by both normal Vault ACL policy and also the EGP:

```bash
ip-10-0-13-29$ vault kv get kv/hr/employees/frank
Error reading kv/data/hr/employees/frank: Error making API request.

URL: GET https://my-vault.com:8200/v1/kv/data/hr/employees/frank
Code: 403. Errors:

* 2 errors occurred:
	* egp standard policy "root/hr_policy" evaluation resulted in denial.

The specific error was:
<nil>

A trace of the execution for policy "root/hr_policy" is available:

Result: false

Description: <none>

Rule "main" (root/hr_policy:9:1) = false
Rule "cidrcheck" (root/hr_policy:5:1) = false
	* permission denied
```

Now the EGP is in place, Vault will use Sentinel to manage requests to the paths specified in the EGP to further scope access based on criteria which normal Vault ACL policy cannot manage.

## SIT Business Hours Policy

This section only deals with the business hours checking EGP policy.  The EGP checks to see what time it is, and if the time is outside the time specified in the EGP, the attempt to access the endpoint fails.

### Apply Normal Vault ACL Policy and Test

If following this whole README, go into the Vault ACL policies directory and _log back in with a privileged token_. Apply the `accounting_policy` to Vault to allow token-holders to read from an Accounting team path. Write such a path:

```bash
$ pushd vault_acl_policies
$ vault login
Token (will be hidden):
Success! You are now authenticated.
...
$ vault policy write accounting_policy ./accounting_policy.hcl
$ vault policy list	                                                 # ensure accounting_policy is present
$ vault policy read accounting_policy
path "kv/accounting/*" {
  capabilities = ["read", "update", "list", "delete"]
}

path "kv/data/accounting/*" {
  capabilities = ["read", "update", "list", "delete"]
}
$ popd

$ vault kv put kv/accounting/general/sally social=987-654-abc				# write the endpoint while logged in with a privileged token
========== Secret Path ==========
kv/data/accounting/general/sally

======= Metadata =======
Key                Value
---                -----
created_time       2023-01-16T19:49:49.081462414Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
```

### Apply EGP to Accounting Policy

This EGP will restrict access based on hours. Apply the same method as before, but using a soft-mandatory rather than a hard mandatory:

```bash
$ policy2=$(base64 ./business-hrs.sentinel)
$ vault write sys/policies/egp/accounting_policy policy="${policy2}" paths="kv/accounting/*,kv/data/accounting/*" enforcement_level="soft-mandatory"

Success! Data written to: sys/policies/egp/hr_policy
```

Now try reading the policy back

```bash
$ vault read sys/policies/egp/accounting_policy
Key                  Value
---                  -----
enforcement_level    soft-mandatory
name                 accounting_policy
paths                [kv/accounting/* kv/data/accounting/*]
policy               import "time"

# Expect requests to only happen during work days (Monday through Friday)
# 0 for Sunday and 6 for Saturday
workdays = rule {
	time.now.weekday > 0 and time.now.weekday < 6
}

# Expect requests to only happen in the hour before work hours (7:00 am - 8:00 am) - useful for demonstration of limiting capabilities of Sentinel for Vault
workhours = rule {
	time.now.hour > 7 and time.now.hour < 8
}

main = rule {
	workdays and workhours
}
```

Great.

### SIT Accounting Business Hours Check EGP

Now create a token with the accounting_policy attached, login with it and attempt to read the path to Sally's information:

```bash
$ vault token create -policy accounting_policy
WARNING! The following warnings were returned from Vault:

  * Endpoint ignored these unrecognized parameters: [display_name entity_alias
  explicit_max_ttl num_uses period policies renewable ttl type]

Key                  Value
---                  -----
token                hvs.CAESIMScZkhavZB3mpm1fc7ZdIQ-IjrWahlnFlJhfQQMZNngGiAKHGh2cy5zZG1TaVBVb3pBVEV6b2wzaE9wUGg3bVQQfg
token_accessor       8CAgAtcjosoKqARekxgWErjY
token_duration       768h
token_renewable      true
token_policies       ["accounting_policy" "default"]
identity_policies    []
policies             ["accounting_policy" "default"]
```

Now login with the token and confirm the policy attached is the accounting_policy:

```bash
$ vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                hvs.CAESIMScZkhavZB3mpm1fc7ZdIQ-IjrWahlnFlJhfQQMZNngGiAKHGh2cy5zZG1TaVBVb3pBVEV6b2wzaE9wUGg3bVQQfg
token_accessor       8CAgAtcjosoKqARekxgWErjY
token_duration       767h59m40s
token_renewable      true
token_policies       ["accounting_policy" "default"]
identity_policies    []
policies             ["accounting_policy" "default"]
```

Now attempt to read from the path now managed by both normal Vault ACL policy and also the EGP:

```bash
$ vault kv get kv/accounting/general/sally
Error reading kv/data/accounting/general/sally: Error making API request.

URL: GET https://my-vault.com:8200/v1/kv/data/accounting/general/sally
Code: 403. Errors:

* 2 errors occurred:
	* egp standard policy "root/accounting_policy" evaluation resulted in denial.

The specific error was:
<nil>

A trace of the execution for policy "root/accounting_policy" is available:

Result: false

Description: <none>

Rule "main" (root/accounting_policy:14:1) = false
Rule "workdays" (root/accounting_policy:5:1) = true
Rule "workhours" (root/accounting_policy:10:1) = false

Note: specifying an override of the operation would have succeeded.
	* permission denied
```


## Troubleshooting

If you get the error
```
Error writing data to sys/policies/egp/hr_policy: Error making API request.

URL: PUT https://my-vault.com:8200/v1/sys/policies/egp/hr_policy
Code: 401. Errors:

* 1 error occurred:
	* Feature Not Enabled
```

it is because you need to purchase the Vault Enterprise Plus module to get access to Sentinel policy-as-code.  Once you have an upodated licence in place, rerun the command to write the EGP.

Retrying:

```
# vault write sys/policies/egp/hr_policy policy="${policy}" paths="kv/hr/*,kv/data/hr/*" enforcement_level="hard-mandatory"
Success! Data written to: sys/policies/egp/hr_policy
```
