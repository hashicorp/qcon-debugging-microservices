---
id: index
title: Welcome to Debugging Microservices Workshop
sidebar_label: Welcome
---

# Getting Started

Welcome to the Debugging Microservices Workshop. You have two options for accessing the workshop. The primary (and recommended) way when doing the workshop in person is to use the Instruqt environment. 

* [Launch Instruqt Environment](https://play.instruqt.com/hashicorp/tracks/debugging-microservices)

## Running locally 

Alternatively, you can download the Docker-based workshop source code. For that, you'll need Docker and Shipyard:

* Docker - [https://docs.docker.com/install/](https://docs.docker.com/install/)
* Shipyard - [https://github.com/shipyard-run/shipyard](https://github.com/shipyard-run/shipyard)


The code repository has source files and examples which will be used by this workshop, before continuing clone this repo.

```shell
git clone https://github.com/hashicorp/qcon-debugging-microservices.git
cd qcon-debugging-microservices
shipyard run ./stack
```

This will bring up the environment locally. The Consul, Gateway, and Jaeger tabs will open automatically.

## Understanding the workshop tabs

### Consul UI

![](images/getting_started/consul_ui.png)

### Jeager UI

![](images/getting_started/jaeger.png)

### Docs

You would see these docs in the Docs tab.


## Development Environment

This workshop comes bundled with a built-in development environment. You can of course use your own IDE and terminal if you have the tools installed but for the purposes of this workshop we are going to be using the built in tools like Go, KubeCtl, Consul, etc.


![](images/getting_started/vscode.png)

### The demo application

Now that Kubernetes and Consul are running, you can install the example application.

Open a new terminal in the IDE ``Ctrl-Shift-` ``

The settings for `kubectl` and `consul` are already configured for you, give this a quick test.

### Getting all running pods `kubectl get pods`

```shell
kubectl get pods
NAME                                                              READY   STATUS    RESTARTS   AGE
consul-consul-connect-injector-webhook-deployment-866c55c88bjh7   1/1     Running   0          45m
consul-consul-server-0                                            1/1     Running   0          45m
consul-consul-fqn7l                                               1/1     Running   0          45m
```

### Display Consul members `consul members`
```shell
consul members
Node                    Address         Status  Type    Build  Protocol  DC   Segment
consul-consul-server-0  10.42.0.9:8301  alive   server  1.6.1  2         dc1  <all>
k3d-shipyard-server     10.42.0.6:8301  alive   client  1.6.1  2         dc1  <default>
```

When you now view the web service in your browser at [http://localhost:9090/ui](http://localhost:9090/ui), you will see the UI for `Fake Service`. Fake Service simulates complex service topologies. In this example, you have two tier system, `Web` calls an upstream service `API`. All of this traffic is flowing over the service mesh.

![](images/getting_started/web.png)

Fake Service is not that fake though, it also emits metrics and tracing data which is capture by `Jaeger`. We will learn more about how tracing works inside your application and in the service mesh in the next section. For now you can look at the dashboard by pointing your browser at [http://localhost:16686/search](http://localhost:16686/search)


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


## Summary

In this section you have learned how to set up a simple application in a development environment. In the next section we will start to investigate how Envoy and Service Mesh technology can be used to troubleshoot and debug cloud-native applications.