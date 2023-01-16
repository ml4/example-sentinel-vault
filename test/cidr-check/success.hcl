global "request" {
  value = {
    connection = {
      remote_addr = "10.10.10.10/32"
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