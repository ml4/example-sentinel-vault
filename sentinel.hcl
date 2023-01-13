# Sentinel policy file
policy "deny-example-action-rules" {
  source = "./policies/deny-example-action-rules/deny-example-action-rules.sentinel"
  enforcement_level = "advisory"
}
