global "request" {
  value = {
    connection = {
      remote_addr = "127.0.0.1"
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