mock "time" {
  data = {
    now = {
      weekday = 1
      hour    = 7
    }
  }
}

test {
  rules = {
    main    = true
  }
}