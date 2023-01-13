global "request" {
  value = {
    connection = {
      remote_addr = "122.22.3.10"
    }
    operation = "create"
    path      = "secret/orders"
  }
}

test {
  rules = {
    main    = false
  }
}
