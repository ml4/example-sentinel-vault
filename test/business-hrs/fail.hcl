mock "time" {
  data = {
    now = {
      weekday = 0
      hour    = 19
    }
  }
}

test {
  rules = {
    main    = false
  }
}