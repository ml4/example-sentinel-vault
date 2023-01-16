global "request" {
  value = {
    connection = {
      remote_addr = "10.0.13.29"
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