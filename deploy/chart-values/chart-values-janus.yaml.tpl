global:
  imagePullSecrets:
  - quay.io-pull-secret 
  dynamic:
    # -- Array of YAML files listing dynamic plugins to include with those listed in the `plugins` field.
    # Relative paths are resolved from the working directory of the initContainer that will install the plugins (`/opt/app-root/src`).
    includes:
      # -- List of dynamic plugins included inside the `janus-idp/backstage-showcase` container image, some of which are disabled by default.
      # This file ONLY works with the `janus-idp/backstage-showcase` container image.
      - 'dynamic-plugins.default.yaml'

    # -- List of dynamic plugins, possibly overriding the plugins listed in `includes` files.
    # Every item defines the plugin `package` as a [NPM package spec](https://docs.npmjs.com/cli/v10/using-npm/package-spec),
    # an optional `pluginConfig` with plugin-specific backstage configuration, and an optional `disabled` flag to disable/enable a plugin
    # listed in `includes` files. It also includes an `integrity` field that is used to verify the plugin package [integrity](https://w3c.github.io/webappsec-subresource-integrity/#integrity-metadata-description).
    plugins: []

  # -- Shorthand for users who do not want to specify a custom HOSTNAME. Used ONLY with the DEFAULT upstream.backstage.appConfig value and with OCP Route enabled.
  clusterRouterBase: apps.example.com
  # -- Custom hostname shorthand, overrides `global.clusterRouterBase`, `upstream.ingress.host`, `route.host`, and url values in `upstream.backstage.appConfig`
  host: backstage-${bs_app_name}.${openshift_ingress_domain}
  # -- Enable service authentication within Backstage instance
  auth:
    # -- Backend service to service authentication
    # <br /> Ref: https://backstage.io/docs/auth/service-to-service-auth/
    backend:
      # -- Enable backend service to service authentication, unless configured otherwise it generates a secret value
      enabled: true
      # -- Instead of generating a secret value, refer to existing secret
      existingSecret: ""
      # -- Instead of generating a secret value, use following value
      value: "replacewithbase64secret"

# -- OpenShift Route parameters
route:
  annotations: {}
  enabled: true
  host: "{{ .Values.global.host }}"
  path: "/"
  wildcardPolicy: None
  tls:
    enabled: true
    termination: "edge"
    insecureEdgeTerminationPolicy: "Redirect"
