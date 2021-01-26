# docker-registry-mirror

The repository automates the deployment of a protected docker registry mirror cache (https://docs.docker.com/registry/recipes/mirror/) deployed to cloud.gov. We use this mirror to reduce our number of pulls from docker hub.


## Mirror

The docker registry mirror is deployed as a docker image to cloud.gov (see [deployment manifest](registry/manifest.yml)). The registry uses an S3 bucket for caching images. It is configured as a pull through mirror, with push to the registry disabled. 

- Docker image: https://hub.docker.com/_/registry
- More information: https://docs.docker.com/registry/recipes/mirror/

The mirror is deployed with no security enabled. Basic authentication does not suffice as we have more complicated security rules. Instead, we protect access to the registry using an Nginx proxy.

## Nginx

Nginx is deployed as a security proxy (see [deployment manifest](proxy/manifest.yml)). All traffic to the mirror is routed through Nginx. Because our `nginx.conf` contains security rules, it is not stored in this repo. 

## Deployment topology

The mirror is deployed to cloud.gov on the `apps.internal` domain. This domain is routable _only_ from within cloud.gov by authorized applications. A network policy allows nginx to communicate with the mirror via the container to container networking feature of Cloud Foundry. 

- Internal routes: https://docs.cloudfoundry.org/devguide/deploy-apps/routes-domains.html#internal-routes
- Network policies: https://docs.cloudfoundry.org/concepts/understand-cf-networking.html#policies
- Container to container networking: https://docs.cloudfoundry.org/concepts/understand-cf-networking.html

Nginx is deployed to the publicly routeable `app.cloud.gov` domain. It is configured as a security proxy for the mirror and is authorized to connect via a network policy. Users of the mirror only know about the proxy url.

You can see this by running `cf apps` (redacted info in `<>`):

```
cf apps
Getting apps in org <org> / space <space> as <user>...

name                     requested state   processes   routes
docker-registry-mirror   started           web:4/4     <hostname>.apps.internal
docker-registry-proxy    started           web:4/4     <hostname>.app.cloud.gov
```


### Advantages

This pattern of using the internal network (`apps.internal`) with an nginx proxy can be used to:

- Protect any application through allow and deny capabilities of [nginx](https://nginx.org) without modifying application code. The `apps.internal` domain combined with `network policies` provides multiple layers of security for your applications when compared to using publicly routable domains.

- Deploy http(s)-based applications which require ports other than 443 or 80. The docker registry mirror runs on port 5000 by default. Using the `apps.internal`, this is allowed. Nginx still exposes ports 80 and 443.

### Disadvantages

This methodology requires two components, nginx and the app it is proxying for. This does mean more deployments and more system components need to be running.

However, for many customers this is an acceptable trade off. It should be noted the same nginx instances can be used to proxy
requests to multiple applications on internal domains.

### Sample nginx configuration

Because we use nginx for security filtering, we do not include our nginx configuration in this repository. However, for those looking to deploy nginx in a similar fashion, we include a sample, non-sensitive example below. Comments and substitutions denoted by `< >` are included in the file.

```
worker_processes 1;
daemon off;

error_log stderr;
events { worker_connections 1024; }

http {
  charset utf-8;
  log_format cloudfoundry 'NginxLog "$http_x_forwarded_for" "$request" $status $body_bytes_sent';
  access_log /dev/stdout cloudfoundry;
  default_type application/octet-stream;
  sendfile on;

  tcp_nopush on;
  keepalive_timeout 30;
  port_in_redirect off;

  # See http://nginx.org/en/docs/http/ngx_http_realip_module.html. You might need to tweak these values
  # if you plan to use ip-based allow rules.
  set_real_ip_from <something> 
  set_real_ip_from 127.0.0.1;

  real_ip_header X-Forwarded-For;
  real_ip_recursive on;

  resolver {{nameservers}} ipv6=off valid=1s;

  server {
    listen {{port}};
    
    allow <ip or ip range>

    deny all;
    location / {
      # MIRROR_ROUTE is an environment variable with the value of
      # the mirror app on the `apps.internal` domain. This should be
      # the route of the app you are proxying.
      set $backend_servers {{ env "MIRROR_ROUTE" }};
      # In our case, the port is 5000 as this is the port the mirror 
      # runs on. Your port will likely vary.
      proxy_pass http://$backend_servers:<port>;
    }
  }
}
```

## Pipeline notes