# Copyright IBM Corp. 2020, 2026

docs "docs" {
  path  = "./_docs"
  port  = 8081

  network {
    name = "network.cloud"
  }
}