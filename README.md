**Steps for project start-up:**
1. Build Caddy from source: https://github.com/mholt/caddy#build
2. Clone new plugins into proper Go Workspace directory (i.e. $GOPATH/src/github.com/fellou89/):
  - https://github.com/fellou89/caddy-awscloudwatch
  - https://github.com/fellou89/caddy-reauth
  - https://github.com/fellou89/caddy-secrets
  - https://github.com/fellou89/caddy-awsdynamodb
3. Modify $GOPATH/src/github.com/mholt/caddy/caddymain/run.go, by adding to the imports (the underscore is necessary):
  - `_ "github.com/fellou89/caddy-awscloudwatch"`
  - `_ "github.com/fellou89/caddy-reauth"`
  - `_ "github.com/fellou89/caddy-secrets"`
  - `_ "github.com/fellou89/caddy-awsdynamodb"`
3. Modify $GOPATH/src/github.com/mholt/caddy/caddyhttp/httpserver/plugin.go, by adding the new directives (line 450):
  - awscloudwatch will post whatever error stops the ServeHTTP filter chain in the middlewares that follow it on the list
  - at the moment we need reauth to be moved after jwt so that the token is first validated agains the secret and then run against the refresh token endpoint
  - secrets needs to go somehwere in the list before the middleware that needs to access the data in the file that was read
  - awsdynamodb can go anywhere on the list at the moment
  - The order of the directives on this list matters, not the order in the Caddyfile
4. cd to $GOPATH/src/github.com/mholt/caddy/caddy and execute `go run build.go`, this has to be done every time a change is made to the middleware plugins
5. Make sure the updated Caddy binary is in your PATH
6. Comment -out or -in directives you want to run in the Caddyfile, and execute caddy from this repo's directory
