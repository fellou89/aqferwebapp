FROM golang:1.8

ADD ./go /go

RUN mkdir -p $GOPATH/src/github.com/caddyserver/builds
RUN cp -r /go/caddyserver $GOPATH/src/github.com/

RUN mkdir -p $GOPATH/src/github.com/mholt/caddy
RUN cp -r /go/caddy $GOPATH/src/github.com/mholt/

WORKDIR $GOPATH/src/github.com/mholt/caddy/caddy/
CMD go run build.go
