// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

package main

import (
	"fmt"
	"net/http"
	"os"

	"github.com/nicholasjackson/sleepy-client"
	"github.com/opentracing/opentracing-go"
	"github.com/opentracing/opentracing-go/ext"
)

func handler(rw http.ResponseWriter, r *http.Request) {
	logger.Info("Handling request")

	wireContext, err := opentracing.GlobalTracer().Extract(
		opentracing.HTTPHeaders,
		opentracing.HTTPHeadersCarrier(r.Header),
	)
	if err != nil {
		logger.Debug("Unable to create context", "error", err)
	}

	serverSpan := opentracing.StartSpan(
		"handle_request",
		ext.RPCServerOption(wireContext),
	)

	defer serverSpan.Finish()

	// create the request
	req, err := http.NewRequest(http.MethodGet, os.Getenv("CURRENCY_ADDR"), nil)
	if err != nil {
		logger.Error("Error creating request", "error", err)
		rw.WriteHeader(http.StatusInternalServerError)
		return
	}

	childSpan := opentracing.StartSpan(
		"call_currency",
		opentracing.ChildOf(serverSpan.Context()),
	)

	ext.SpanKindRPCClient.Set(childSpan)
	ext.HTTPUrl.Set(childSpan, req.URL.String())
	ext.HTTPMethod.Set(childSpan, req.Method)

	opentracing.GlobalTracer().Inject(
		childSpan.Context(),
		opentracing.HTTPHeaders,
		opentracing.HTTPHeadersCarrier(req.Header),
	)

	// execute the request
	c := &sleepy.HTTP{}
	resp, err := c.Do(req)
	//resp, err := http.DefaultClient.Do(req)
	if err != nil {
		logger.Error("Error calling upstream", "error", err)
		rw.WriteHeader(http.StatusInternalServerError)
		return
	}

	if resp.StatusCode != http.StatusOK {
		logger.Error("Expected status OK, got", "status", resp.StatusCode)
		rw.WriteHeader(http.StatusInternalServerError)
		return
	}

	fmt.Fprint(rw, "Hello World")
}
