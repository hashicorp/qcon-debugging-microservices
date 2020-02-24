# qcon-debugging-microservices

To build locally, make sure you have access to Docker and you've downloaded the [Shipyard](https://github.com/shipyard-run/shipyard) tool.

To build, run:

```shell
shipyard run ./stack
```

This will bootstrap the environment. Once completed, it will open up local browser tabs to the following:


`http://localhost:18500` to access the Consul UI
`http://localhost:8080` to run VSCode in your browser
`http://localhost:8081` to see the documentation
`http://localhost:19090` to access the web service

You can also run without opening the browser tabs automatically:

```shell
shipyard run ./stack --no-browser
```