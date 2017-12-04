**Steps for project start-up:**
1. Build Caddy from source: https://github.com/mholt/caddy#build
2. Clone new plugins into proper Go Workspace directory (i.e. $GOPATH/src/github.com/fellou89/):
  - https://github.com/fellou89/caddy-secrets
  - https://github.com/fellou89/caddy-awsdynamodb
  - https://github.com/fellou89/caddy-awscloudwatch
3. Modify $GOPATH/src/github.com/mholt/caddy/caddymain/run.go, by adding to the imports (the underscore is necessary):
  - `_ "github.com/fellou89/caddy-secrets"`
  - `_ "github.com/fellou89/caddy-awsdynamodb"`
  - `_ "github.com/fellou89/caddy-awscloudwatch"`
3. Modify $GOPATH/src/github.com/mholt/caddy/caddyhttp/httpserver/plugin.go, by adding the new directives (line 450):
  - secrets has to go first on the list to make sure it's always the first middleware on the stack
  - awsdynamodb and awscloudwatch can go anywhere on the list at the moment
  - The order of the directives on this list matters, not the order in the Caddyfile
4. cd to $GOPATH/src/github.com/mholt/caddy/caddy and run go run build.go, this command needs to be run every time a change is made to the middleware plugins
5. Make sure the updated Caddy binary is in your PATH
6. Comment -out or -in directives you want to run in the Caddyfile, and execute caddy from this repo's directory
