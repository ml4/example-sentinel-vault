# Example Sentinel Policy Use With Vault Enterprise

This example uses an HR department policy for KV storage in Vault. You need to test this repo with sentinel0.19.2-rc1. A known issue exists 0.19.1.
This file is an HCL representation of the knowledge expounded in [this HashiCorp tutorial on the subject](https://developer.hashicorp.com/vault/tutorials/policies/sentinel#write-sentinel-policies).
Credence to the HashiCorp Sentinel product, engineering and education teams.

## Unit Test Sentinel Policies Locally

Once you have access to your Vault Enterprise instance (i.e. not an OSS/homebrew etc. deployment), and have instantiated VAULT_TOKEN in your env, from this repo gitroot, install the base HR department example policy and mount the KV secrets engine and write an example kv while logged in with the root or equivalent token somewhere where entites with the hr_policy policy attached to their token will then be able to retrieve:

```bash
cd example-sentinel-vault
$ sentinel0.19.2-rc1 test
PASS - business-hrs.sentinel
  PASS - test/business-hrs/fail.hcl
  PASS - test/business-hrs/success.hcl
PASS - cidr-check.sentinel
  PASS - test/cidr-check/fail.hcl
  PASS - test/cidr-check/success.hcl

## Main EGP Setup For CIDR Checking and business hours guard rails
unset VAULT_TOKEN                                    # this takes precedence over operations below
vault login 		                                     # enter root or equivalent token for your dev instance
vault secrets enable -version=2 kv                   # enable secrets engine at default path and check
vault secrets list

Path          Type         Accessor              Description
----          ----         --------              -----------
cubbyhole/    cubbyhole    cubbyhole_ea86e0c0    per-token private secret storage
identity/     identity     identity_3c08cf50     identity store
kv/           kv           kv_2787f70f           n/a
sys/          system       system_3cde701e       system endpoints used for control, policy and debugging

vault list sys/policies/egp													      # check to see if any policies are in place already
vault policy delete sys/policies/egp/hr_policy			      # if you're tidying up between demos
vault policy delete sys/policies/egp/accounting_policy
```

## SIT CIDR Check Policy

In this README, it might be easier to run through the system integration testing iteratively by policy to prove the usefulness of Vault Sentinel clearly.
This section only deals with the CIDR check policy.  The next section will deal with business hour access management.

### Apply Normal Vault ACL Policy and Test

Go into the Vault ACL policies directory and apply the policy to Vault to allow token-holders to write to the path.

```bash
pushd vault_acl_policies
vault policy write hr_policy ./hr_policy.hcl
vault policy list
vault policy read hr_policy
popd

vault kv put kv/hr/employees/frank social=123-456-789
Success! Data written to: kv/hr/employees/frank

vault kv get kv/hr/employees/frank
===== Data =====
Key       Value
---       -----
social    123-456-789
```

### Apply EGP To Paths In Above Policy

We will then limit this path with an endpoint-governing policy. Next you need to base64 encode the policy file for ingress into Vault:

```bash
pushd example
policy=$(base64 ./cidr-check.sentinel)
vault write sys/policies/egp/hr_policy policy="${policy}" paths="kv/hr/*,kv/data/hr/*" enforcement_level="hard-mandatory"

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
# vault write sys/policies/egp/hr_policy policy="${policy}" paths="kv/hr/*,kv/data/hr/*" enforcement_level="hard-mandatory"
Success! Data written to: sys/policies/egp/hr_policy
```

Now try reading the policy back
```bash
vault read sys/policies/egp/hr_policy
Key                  Value
---                  -----
enforcement_level    hard-mandatory
name                 hr_policy
paths                [kv/hr/* kv/data/hr/*]
policy               import "sockaddr"
import "strings"

# Only care about create, list, update, and delete operations against kv path
precond = rule {
	request.operation in ["create", "list", "update", "delete"] and
	strings.has_prefix(request.path, "kv/")
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

### SIT EGP

Now create a token with the hr_policy attached, login with it and attempt to write to the path:

```bash
vault token create -policy hr_policy

$ vault token create -policy hr_policy
WARNING! The following warnings were returned from Vault:

  * Endpoint ignored these unrecognized parameters: [display_name entity_alias
  explicit_max_ttl num_uses period policies renewable ttl type]

Key                  Value
---                  -----
token                hvs.blah
token_accessor       ua96Doy7WnrCvLDwX48pOpGz
token_duration       768h
token_renewable      true
token_policies       ["default" "hr_policy"]
identity_policies    []
policies             ["default" "hr_policy"]
```

```bash

```


--------------------------------------------------------------




vault policy write accounting_policy ./accounting_policy.hcl
vault policy read accounting_policy

Success! Enabled the kv secrets engine at: kv/


```


```

Repeat the process for the business hours checks:
```bash
policy2=$(base64 business-hrs.sentinel)
vault write sys/policies/egp/business-hrs policy="${policy2}" paths="kv/accounting/*" enforcement_level="soft-mandatory"  # note soft-mandatory on this one
```

Ensure it is accepted OK:
```bash
# vault read sys/policies/egp/business-hrs
Key                  Value
---                  -----
enforcement_level    soft-mandatory
name                 business-hrs
paths                [kv/accounting/*]
policy               import "time"

# Expect requests to only happen during work days (Monday through Friday)
# 0 for Sunday and 6 for Saturday
workdays = rule {
	time.now.weekday > 0 and time.now.weekday < 6
}

# Expect requests to only happen during work hours (7:00 am - 6:00 pm)
workhours = rule {
	time.now.hour > 7 and time.now.hour < 18
}

main = rule {
	workdays and workhours
}
```

Create token with the accounting team policy, login in with the token and attempt to write to the path in your Vault instance with:
```bash
vault token create -policy accounting_policy
WARNING! The following warnings were returned from Vault:

  * Endpoint ignored these unrecognized parameters: [display_name entity_alias
  explicit_max_ttl num_uses period policies renewable ttl type]

Key                  Value
---                  -----
token                hvs.blah
token_accessor       aHQCcNME7ZpuUrvqcH3xWhOV
token_duration       768h
token_renewable      true
token_policies       ["accounting_policy" "default"]
identity_policies    []
policies             ["accounting_policy" "default"]

vault kv put kv/accounting/test acct_no="293472309423"
```

