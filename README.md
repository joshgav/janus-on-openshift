## Janus on OpenShift

Installation of Janus, upstream of Red Hat Developer Hub.

- Set environment variables in `./.env` then deploy with `./deploy/deploy.sh`.
- For the `GITHUB_APP_CLIENT_ID` and `GITHUB_APP_CLIENT_SECRET` env vars, use the values generated for the app in the following step.
- GitHub auth should be enabled. To do so create a GitHub org and app as
  described in [this upstream doc](https://backstage.io/docs/integrations/github/github-apps/) and create a
  file in the `./deploy` directory named `github-app-credentials.yaml` as described in that doc.
- The file `github-app-credentials.yaml.tpl` is provided as an example.


## Tips

- Remove color coding from logs: `kubectl logs -l app.kubernetes.io/instance=rhdh --tail=-1 | sed 's/.\[[0-9]*m//g'`