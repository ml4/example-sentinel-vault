global "request" {
  value = {
    connection = {
      remote_addr = "172.20.10.2"
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