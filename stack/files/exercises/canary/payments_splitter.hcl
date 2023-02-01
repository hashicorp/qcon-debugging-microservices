# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

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
