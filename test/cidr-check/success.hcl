global "request" {
  value = {
    connection = {
      remote_addr = "10.0.0.0/8"
    }
    operation = "create"
    path      = "kv/orders"
  }
}

test {
  rules = {
    main = true
  }
}