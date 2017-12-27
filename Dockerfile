FROM golang:1.8

ADD ./Caddyfile /Caddyfile

RUN go get github.com/aws/aws-sdk-go/aws
RUN go get github.com/aws/aws-sdk-go/aws/awserr
RUN go get github.com/aws/aws-sdk-go/aws/session
RUN go get github.com/aws/aws-sdk-go/service/cloudwatchlogs
RUN go get github.com/aws/aws-sdk-go/service/dynamodb
RUN go get github.com/garyburd/redigo/redis
RUN go get github.com/nicolasazrak/caddy-cache 
RUN go get github.com/nicolasazrak/caddy-cache/storage
RUN go get github.com/BTBurke/caddy-jwt
RUN go get github.com/pkg/errors
RUN go get github.com/sirupsen/logrus
RUN go get github.com/satori/go.uuid

RUN go get github.com/mholt/caddy/caddy
RUN go get github.com/caddyserver/builds

RUN mkdir -p src/github.com/mholt/caddy/vendor/github.com/fellou89
WORKDIR /go/src/github.com/mholt/caddy/vendor/github.com/fellou89
RUN git clone https://github.com/fellou89/caddy-awscloudwatch
RUN git clone https://github.com/fellou89/caddy-reauth
RUN git clone https://github.com/fellou89/caddy-secrets
RUN git clone https://github.com/fellou89/caddy-awsdynamodb
RUN git clone https://github.com/fellou89/caddy-redis

WORKDIR /go/src/github.com/mholt/caddy/caddyhttp/httpserver
RUN sed -i "s#var directives = \[\]string{#var directives = \[\]string{\n        \"awscloudwatch\",\n        \"secrets\",\n#g" plugin.go
RUN sed -i "s#\"restic\",.*github.com/restic/caddy#\"restic\",    // github.com/restic/caddy\n\n        \"awsdynamodb\",\n        \"redis\",#g" plugin.go

WORKDIR /go/src/github.com/mholt/caddy/caddy
RUN sed -i "s#This is where other plugins get plugged in (imported)#This is where other plugins get plugged in (imported)\n\n        _ \"github.com/nicolasazrak/caddy-cache\"\n        _ \"github.com/BTBurke/caddy-jwt\"\n\n        _ \"github.com/fellou89/caddy-awscloudwatch\"\n        _ \"github.com/fellou89/caddy-awsdynamodb\"\n        _ \"github.com/fellou89/caddy-reauth\"\n        _ \"github.com/fellou89/caddy-redis\"\n        _ \"github.com/fellou89/caddy-secrets\"#g" caddymain/run.go

RUN go run build.go; mv caddy /

WORKDIR /

# Using golang-auth mini service until we have an actual auth endpoint
ADD ./golang-auth /golang-auth
CMD cd /golang-auth/main; go run main.go & cd /; ./caddy
