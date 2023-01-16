global "request" {
  value = {
    connection = {
      remote_addr = "172.16.0.0/12"
    }
    operation = "create"
    path      = "kv/orders"
  }
}

test {
  rules = {
    main    = true
  }
}