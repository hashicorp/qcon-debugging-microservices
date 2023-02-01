# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

docs "docs" {
  path  = "./_docs"
  port  = 8081

  network {
    name = "network.cloud"
  }
}