global "request" {
  value = {
    connection = {
      remote_addr = "172.0..10/32"
    }
    operation = "create"
    path = "kv/orders"
  }
}

test {
  rules = {
    main    = true
  }
}