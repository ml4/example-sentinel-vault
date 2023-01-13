<!--
Enter H1 to top the doc, e.g.:
# Ensure no access to actions when blah approach is used
-->

<!---
Example provider/category table - uncomment, edit, delete this line
| Provider            | Category   |
|---------------------|------------|
| Amazon Web Services | Networking |
-->

## Description
<!--
Enter description here
-->

## Policy Results (Pass)
<!--
Enter codefence to show the example trace expected to pass the policy.
The one below should be removed.  Credits: @rclark @hcrhall
```bash
trace:
      deny-public-ssh-acl-rules.sentinel:85:1 - Rule "main"
        Description:
          --------------------------------------------------------
          Name:        deny-public-ssh-acl-rules.sentinel
          Category:    Networking
          Provider:    hashicorp/aws
          Resource:    aws_security_group
                       aws_security_group_rule
          Check:       cidr_blocks does not contain "0.0.0.0/0"
                       when port is "22" or protocl is "-1"
          --------------------------------------------------------
          Ensure no security groups allow ingress from 0.0.0.0/0
          to port 3389.
          --------------------------------------------------------

        Value:
          true
```
-->
---
