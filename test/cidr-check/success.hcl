global "request" {
  value = {
    connection = {
      remote_addr = ""
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