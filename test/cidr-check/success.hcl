global "request" {
  value = {
    connection = {
      remote_addr = "192.168."
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