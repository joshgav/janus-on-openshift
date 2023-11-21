global:
  imagePullSecrets:
  - quay.io-pull-secret 
  # -- Shorthand for users who do not want to specify a custom HOSTNAME. Used ONLY with the DEFAULT upstream.backstage.appConfig value and with OCP Route enabled.
  # clusterRouterBase: apps.example.com
  # -- Custom hostname shorthand, overrides `global.clusterRouterBase`, `upstream.ingress.host`, `route.host`, and url values in `upstream.backstage.appConfig`
  host: backstage-${bs_app_name}.${openshift_ingress_domain}
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
    plugins:
    - package: ./dynamic-plugins/dist/roadiehq-backstage-plugin-argo-cd-backend-dynamic
      disabled: false
    - package: ./dynamic-plugins/dist/roadiehq-scaffolder-backend-argocd-dynamic
      disabled: false
    - package: ./dynamic-plugins/dist/roadiehq-backstage-plugin-argo-cd
      disabled: false
      pluginConfig:
        dynamicPlugins:
          frontend:
            roadiehq.backstage-plugin-argo-cd:
              mountPoints:
                - mountPoint: entity.page.overview/cards
                  importName: EntityArgoCDOverviewCard
                  config:
                    layout:
                      gridColumnEnd:
                        lg: "span 8"
                        xs: "span 12"
                    if:
                      allOf:
                        - isArgocdAvailable
                - mountPoint: entity.page.cd/cards
                  importName: EntityArgoCDHistoryCard
                  config:
                    layout:
                      gridColumn: "1 / -1"
                    if:
                      allOf:
                        - isArgocdAvailable
    - package: ./dynamic-plugins/dist/backstage-plugin-kubernetes-backend-dynamic
      disabled: false
    - package: ./dynamic-plugins/dist/backstage-plugin-kubernetes
      disabled: false
      pluginConfig:
        dynamicPlugins:
          frontend:
            backstage.plugin-kubernetes:
              mountPoints:
                - mountPoint: entity.page.kubernetes/cards
                  importName: EntityKubernetesContent
                  config:
                    layout:
                      gridColumn: "1 / -1"
                    if:
                      anyOf:
                        - hasAnnotation: backstage.io/kubernetes-id
                        - hasAnnotation: backstage.io/kubernetes-namespace

  # -- Enable service authentication within Backstage instance
  auth:
    backend:
      enabled: false
      # -- Instead of generating a secret value, refer to existing secret
      # existingSecret: ""

route:
  enabled: true
