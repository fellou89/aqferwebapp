FROM golang:1.8

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
RUN cd src/github.com/mholt/caddy/vendor/github.com/fellou89; git clone https://github.com/fellou89/caddy-awscloudwatch
RUN cd src/github.com/mholt/caddy/vendor/github.com/fellou89; git clone https://github.com/fellou89/caddy-reauth
RUN cd src/github.com/mholt/caddy/vendor/github.com/fellou89; git clone https://github.com/fellou89/caddy-secrets
RUN cd src/github.com/mholt/caddy/vendor/github.com/fellou89; git clone https://github.com/fellou89/caddy-awsdynamodb
RUN cd src/github.com/mholt/caddy/vendor/github.com/fellou89; git clone https://github.com/fellou89/caddy-redis

RUN cat src/github.com/mholt/caddy/caddy/caddymain/run.go | sed "s#This is where other plugins get plugged in (imported)#This is where other plugins get plugged in (imported)\n\n        _ \"github.com/nicolasazrak/caddy-cache\"\n        _ \"github.com/BTBurke/caddy-jwt\"\n\n        _ \"github.com/fellou89/caddy-awscloudwatch\"\n        _ \"github.com/fellou89/caddy-awsdynamodb\"\n        _ \"github.com/fellou89/caddy-reauth\"\n        _ \"github.com/fellou89/caddy-redis\"\n        _ \"github.com/fellou89/caddy-secrets\"#" > src/github.com/mholt/caddy/caddy/caddymain/run.go

RUN cat src/github.com/mholt/caddy/caddyhttp/httpserver/plugin.go | sed "s#var directives = \[\]string{#var directives = \[\]string{\n        \"awscloudwatch\",\n        \"secrets\",\n#g" > src/github.com/mholt/caddy/caddyhttp/httpserver/plugin.go
RUN cat src/github.com/mholt/caddy/caddyhttp/httpserver/plugin.go | sed "s#\"restic\",.*github.com/restic/caddy#\"restic\",    // github.com/restic/caddy\n\n        \"awsdynamodb\",\n        \"redis\",#g" > src/github.com/mholt/caddy/caddyhttp/httpserver/plugin.go

RUN cd src/github.com/mholt/caddy/caddy/; go run build.go; mv caddy /

ADD ./Caddyfile /Caddyfile

WORKDIR /

# Using golang-auth mini service until we have an actual auth endpoint
ADD ./golang-auth /golang-auth
CMD cd /golang-auth/main; go run main.go & cd /; ./caddy
