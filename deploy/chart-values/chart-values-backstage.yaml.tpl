upstream:
  postgresql:
    enabled: false
  commonAnnotations:
    app.openshift.io/connects-to: >-
      [{"apiVersion":"postgresql.cnpg.io/v1","kind":"Cluster","name":"backstage-pgcluster"}]
    app.openshift.io/vcs-uri: 'https://github.com/joshgav/janus-on-openshift'
  commonLabels:
    app: janus
    app.kubernetes.io/name: janus
  backstage:
    installDir: /opt/app-root/src
    ## HACK: attempt to override upstream (see also end of deploy.sh)
    appConfig: {}
    image:
      registry: ${registry_hostname}
      repository: ${image_url_path}
      tag: ${image_tag}
    podAnnotations:
      instrumentation.opentelemetry.io/inject-nodejs: "true"
      checksum/dynamic-plugins: >-
        {{- include "common.tplvalues.render" ( dict "value" .Values.global.dynamic "context" $) | sha256sum }}
    extraAppConfig:
    - configMapRef: custom-backstage-app-config
      filename: app-config.yaml
    extraVolumes:
    - name: backstage-pgcluster-ca
      secret:
        secretName: backstage-pgcluster-ca
        items:
        - key: ca.crt
          path: ca.crt
    - name: github-app-credentials
      secret:
        secretName: github-app-credentials
        items:
        - key: github-app-credentials.yaml
          path: github-app-credentials.yaml
    # Ephemeral volume that will contain the dynamic plugins installed by the initContainer below at start.
    - name: dynamic-plugins-root
      ephemeral:
        volumeClaimTemplate:
          spec:
            accessModes:
            - ReadWriteOnce
            resources:
              requests:
                storage: 1Gi
    # Volume that will expose the `dynamic-plugins.yaml` file from the `dynamic-plugins` config map.
    # The `dynamic-plugins` config map is created by the helm chart from the content of the `global.dynamic` field.
    - name: dynamic-plugins
      configMap:
        defaultMode: 420
        name: dynamic-plugins
        optional: true
    # Optional volume that allows exposing the `.npmrc` file (through a `dynamic-plugins-npmrc` secret)
    # to be used when running `npm pack` during the dynamic plugins installation by the initContainer.
    - name: dynamic-plugins-npmrc
      secret:
        defaultMode: 420
        optional: true
        secretName: dynamic-plugins-npmrc
    extraVolumeMounts:
    - name: backstage-pgcluster-ca
      mountPath: /var/run/secrets/backstage-pgcluster-ca
      subPath: ca.crt 
    - name: github-app-credentials
      mountPath: /opt/app-root/src/github-app-credentials.yaml
      subPath: github-app-credentials.yaml
    - name: dynamic-plugins-root
      mountPath: /opt/app-root/src/dynamic-plugins-root
    extraEnvVarsSecrets:
    - backstage-pgcluster-superuser
    - github-token
    - argocd-token
    - quay-token
    extraEnvVars:
    - name: PGSSLMODE
      value: "require"
    readinessProbe:
      failureThreshold: 3
      httpGet:
        path: /healthcheck
        port: 7007
        scheme: HTTP
      initialDelaySeconds: 30
      periodSeconds: 10
      successThreshold: 2
      timeoutSeconds: 2
    livenessProbe:
      failureThreshold: 3
      httpGet:
        path: /healthcheck
        port: 7007
        scheme: HTTP
      initialDelaySeconds: 60
      periodSeconds: 10
      successThreshold: 1
      timeoutSeconds: 2
