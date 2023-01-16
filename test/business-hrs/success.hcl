mock "time" {
  data = {
    now = {
      weekday = 1
      hour    = 12
    }
  }
}

test {
  rules = {
    main    = true
  }
}