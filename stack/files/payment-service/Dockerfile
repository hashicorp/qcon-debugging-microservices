FROM golang:alpine

COPY . /go/src/github.com/hashicorp/debugging-microservices/payment-service

# Build with debug flags
WORKDIR /go/src/github.com/hashicorp/debugging-microservices/payment-service
RUN go mod init
RUN CGO_ENABLED=0 GOOS=linux go build -tags prod -gcflags "-N -l" -o ./bin/payment-service ./*.go

FROM alpine:latest

RUN mkdir /service
COPY --from=0 /go/src/github.com/hashicorp/debugging-microservices/payment-service/bin/payment-service /app/payment-service

WORKDIR /tmp

ENTRYPOINT ["/app/payment-service"]
