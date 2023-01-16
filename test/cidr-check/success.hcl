global "request" {
  value = {
    connection = {
      remote_addr = "192.168.0.1/24"
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