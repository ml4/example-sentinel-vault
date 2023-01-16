mock "time" {
  data = {
    now = {
      weekday = 1
      hour    = 8
    }
  }
}

test {
  rules = {
    main    = true
  }
}