---
id: debugging-loop
title: Debugging Microservices
sidebar_label: Record/Replay Debugging
---

# Debugging in production with Loop

Debugging with squash like we did in the previous section is powerful and is very useful in local dev-test loops. The problem is, once you get into a shared environment and up to the production-level environments, access levels become more restricted. Not too many organizations will just connect up IDE debuggers to your production environment, so we need to have an alternative way.

![](images/debugging/gloolooplogo.png)

In this section, we're going to use a tool called Gloo Loop to be able to identify when there are issues in our production environment, save off those failed messages, and give us an opportunity to replay the messages in a staging or test environment. Doing this allows us to use the real production messages in a lower environment and observe how our services behave without affecting any live production traffic or users. 

### Getting started

To get started using loop, let's install the loop server:

```shell
kubectl apply -f exercises/debugging-loop/loop.yaml
```

<p>
  <Terminal target="vscode.container.shipyard" shell="/bin/bash" workdir="/work" user="root" expanded/>
</p>

Checking the loop server came up correctly:

```shell
kubectl get pod -n loop-system
```

<p>
  <Terminal target="vscode.container.shipyard" shell="/bin/bash" workdir="/work" user="root" expanded/>
</p>

Lastly, we need to expose the loop server locally for our CLI to connect. We can do that with the following `kubectl` command:

```shell
kubectl port-forward -n loop-system deploy/loop 5678 &
```

<p>
  <Terminal target="vscode.container.shipyard" shell="/bin/bash" workdir="/work" user="root" expanded/>
</p>

### Listing existing loop captures

You can specify what messages or requests Loop should capture using a configuration file (which we'll show in the next section), but to see what requests have already been captured, you can run the following:

```shell
loopctl list

```

<p>
  <Terminal target="vscode.container.shipyard" shell="/bin/bash" workdir="/work" user="root" expanded/>
</p>

You should see an empty list:

```
+----+------+------+--------+-------------+
| ID | PATH | VERB | STATUS | DESTINATION |
+----+------+------+--------+-------------+
+----+------+------+--------+-------------+
```

We see that we don't have any requests captured. Let's explore how loop works and how we can configure it to capture failed requests so we can replay them and debug. 

### How Loop works

Loop is implemented as a server-side controller as well as extensions to Envoy-based proxies through a feature called the ["Tap filter"](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/tap_filter). Using the tap filter in envoy, we have a way to specify a "match" predicate to determine exactly which messages we're interested in, as well as a way to capture them and stream them back. The server-side controller provides a sink for those captured messages to land and uses a CLI to allow users to interact with the system (ie, set configuration, view captures, replay, them, etc). 

In this tutorial, we're going to use the Gloo API Gateway, which is built on Envoy, with Loop enabled to capture any failed messages. Since this functionality is built into Envoy we could technically add this into the service mesh sidecar proxies as well. Check with us at [Solo.io](https://www.solo.io) for more on that as it's still under heavy development -- all Envoy based service meshes, including Consul Service Mesh, are targeted for support.

### Specifying match conditions

Specifying match conditions for the loop functionality (ie, which messages to capture and store for later playback) is done through configuration. Gloo and Loop (and all Solo projects) are configured through a declarative configuration model -- which complements the Kubernetes model very nicely.

For our simple example here, we'll specify a match condition that looks like this:

```yaml
apiVersion: loop.solo.io/v1
kind: TapConfig
metadata:
  name: gloo
  namespace: loop-system
spec:
  match: responseHeaders[":status"] == prefix("5")
```

This `TapConfig` resource says to capture any requests who's status starts with a `5`. For example, any request that results in an HTTP status of `500` would match this predicate. 

Let's apply this configuration to loop:

```shell
kubectl apply -f exercises/debugging-loop/tap.yaml
```

<p>
  <Terminal target="vscode.container.shipyard" shell="/bin/bash" workdir="/work" user="root" expanded/>
</p>

Now we should have our Loop system configured for capture. Next we need to send some requests into the system that fail and observe that loop captures the requests.

### Capturing requests

To exercise this behavior, make sure one of the failing services from the previous section is enabled. When we introduced `payments` service (as a `green` deployment in a `blue-green` scenario), we saw that requests would timeout and an `HTTP 500` status was returned. Let's exercise this request, but the important part is to call this through the API Gateway which has Loop enabled. To do this, we need to expose the API Gateway like we did in the API Gateway section:

Now make a request:

```shell
curl $(glooctl proxy url)
```

<p>
  <Terminal target="vscode.container.shipyard" shell="/bin/bash" workdir="/work" user="root" expanded/>
</p>

When you hit a failed request (HTTP 500), the Loop system should had recorded that. Note, any successful requests (HTTP 200) are NOT captured. To verify we captured a request, let's use loop:

```shell
loopctl list
```

<p>
  <Terminal target="vscode.container.shipyard" shell="/bin/bash" workdir="/work" user="root" expanded/>
</p>

You should  see output similar to:

```
+----+------+------+--------+-------------+
| ID | PATH | VERB | STATUS | DESTINATION |
+----+------+------+--------+-------------+
|  1 | /    | GET  |    500 |             |
+----+------+------+--------+-------------+
```


Yay! We've sorted through the requests and captured only the failing ones. Now let's see how we can replay this in a way that allows us to debug the system. 

### Replaying and debugging captured requests

Now that we've captured our failing requests, we can replay them. In this simplified scenario, we're only going to replay the request back through the `web` service. We can attach out debugger as we did in the previous section, set break points, and step-by-step debug through when we use loop to replay the requests:

```shell
loopctl replay --id 1 --destination web.default:9090
```

NOTE: You may want to adjust the `id` param depending which request you want to send in. 

<p>
  <Terminal target="vscode.container.shipyard" shell="/bin/bash" workdir="/work" user="root" expanded/>
</p>

You should be able to hit the break points from here and replay the requests as many times as you need. 

In this part of the tutorial, we didn't move to a lower environment, but we did replay the requests without having to send them in ourselves. In other words, we _could_ move this to a different environment and replay the traffic, but to keep this tutorial simple enough, we just replayed in the same environment. 
