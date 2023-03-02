mock "time" {
  data = {
    now = {
      weekday = 1
      hour    = 4
    }
  }
}

test {
  rules = {
    main    = true
  }
}
