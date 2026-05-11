# Copyright IBM Corp. 2020, 2026

kind = "service-splitter",
name = "payment"

splits = [
  {
    weight = 90,
    service_subset = "blue"
  },
  {
    weight = 10,
    service_subset = "green"
  }
]
