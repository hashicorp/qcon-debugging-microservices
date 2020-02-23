---
id: apigateway
title: Loop with Gloo API Gateway
sidebar_label: Loop with Gloo API Gateway
---

## Expose services through a Kubernetes API Gateway

We use an edge gateway/ingress called [Gloo which is an open-source API Gateway](https://docs.solo.io/gloo/latest/) built on [Envoy Proxy](https://docs.solo.io/gloo/latest/) to handle routing into the cluster. Gloo also enables some other features like debugging which we'll dive into later in the tutorial. To get started with Gloo, let's install the proxy and its control plane into the `gloo-system` namespace.


### Getting the Gloo Pods

```shell
$  kubectl get po -n gloo-system

NAME                                READY   STATUS      RESTARTS   AGE
svclb-gateway-proxy-v2-l6tnc        2/2     Running     0          4m39s
redis-5bbc7747dd-lxp9f              1/1     Running     0          4m39s
discovery-5fc6c7dfbc-bmq6w          1/1     Running     0          4m39s
rate-limit-cd84768fb-gmsnj          1/1     Running     0          4m38s
extauth-86d884fc95-kwnb4            1/1     Running     0          4m38s
gloo-7464b858c9-zdr4g               1/1     Running     0          4m39s
gateway-certgen-7q2qx               0/1     Completed   0          4m38s
api-server-67d4686ff4-ffz87         3/3     Running     0          4m38s
gateway-proxy-v2-7bc7fcd6bb-swfw2   1/1     Running     0          4m39s
gateway-v2-b79ff6f74-4xhb7          1/1     Running     0          4m39s
```

Gloo routes to an abstraction called an `upstream` which can be a Kubernetes service, or a service defined in Consul, or even a cloud function like an AWS Lambda. Gloo has a function discovery component (cleverly called `discovery`) in the control plane that will automatically discover these services or functions. Let's list the `upstreams` Gloo discovered and verify that our `web` service is there.

### Check for the web upstream

```shell
$ glooctl get upstream | grep web

| default-web-9090         | Kubernetes | Accepted | svc name:      web 
```

Gloo exposes APIs and services through the proxy using an API called the `VirtualService` resource. Let's create a `default` `VirtualService` and add a route to Gloo's routing table which takes traffic from the edge of the cluster and routes to the `web` service.

### Create a default VirtualService
```shell
$  glooctl create vs default

+-----------------+--------------+---------+------+---------+-----------------+--------+
| VIRTUAL SERVICE | DISPLAY NAME | DOMAINS | SSL  | STATUS  | LISTENERPLUGINS | ROUTES |
+-----------------+--------------+---------+------+---------+-----------------+--------+
| default         | default      | *       | none | Pending |                 |        |
+-----------------+--------------+---------+------+---------+-----------------+--------+
```

### Create a route in Gloo to the web service

```shell
$  glooctl add route --path-prefix / --dest-name default-web-9090

+-----------------+--------------+---------+------+----------+-----------------+--------------------------------+
| VIRTUAL SERVICE | DISPLAY NAME | DOMAINS | SSL  |  STATUS  | LISTENERPLUGINS |             ROUTES             |
+-----------------+--------------+---------+------+----------+-----------------+--------------------------------+
| default         | default      | *       | none | Accepted |                 | / ->                           |
|                 |              |         |      |          |                 | gloo-system.default-web-9090   |
|                 |              |         |      |          |                 | (upstream)                     |
+-----------------+--------------+---------+------+----------+-----------------+--------------------------------+
```

From within the VSCode terminal, we should be able to call the service through the Gloo API Gateway.

### Calling the API Gateway

```shell
$  curl -v $(glooctl proxy url)

{
  "name": "web",
  "uri": "/",
  "type": "HTTP",
  "start_time": "2019-11-19T21:53:52.000362",
  "end_time": "2019-11-19T21:53:52.029295",
  "duration": "28.9323ms",
  "body": "Hello World",
  "upstream_calls": [
    {
      "name": "api-v1",
      "uri": "http://localhost:9091",
      "type": "HTTP",
      "start_time": "2019-11-19T21:53:52.001320",
      "end_time": "2019-11-19T21:53:52.028111",
      "duration": "26.7908ms",
      "body": "Response from API v1",
      "upstream_calls": [
        {
          "uri": "http://localhost:9091",
          "code": 200
        }
      ],
      "code": 200
    }
  ],
  "code": 200
}
```