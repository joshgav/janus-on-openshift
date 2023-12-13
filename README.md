## Janus on OpenShift

Installation of Janus, upstream of Red Hat Developer Hub.

- Set environment variables in `./.env` then deploy with `./deploy/deploy.sh`.
- For the `GITHUB_APP_CLIENT_ID`, `GITHUB_APP_CLIENT_SECRET` and other
  `GITHUB_APP_*` env vars, use the values generated in the following step.
- GitHub auth should be enabled. To do so create a GitHub org and app as
  described in [this upstream doc](https://backstage.io/docs/integrations/github/github-apps/) and create a
  file in the `./deploy` directory named `github-app-credentials.yaml` as described in that doc.
  Alternatively, set the values from the generated doc as env vars in `./.env`

## Use

- To modify the app-config.yaml file for the instance modify `deploy/app-config.yaml` and redeploy.
- To modify the list of dynamic plugins to enable, modify `deploy/chart-values/chart-values-janus.yaml.tpl`
- Configuration for Backstage is in `deploy/chart-values/chart-values-backstage.yaml.tpl`

## Tips

- Remove color coding from logs: `kubectl logs -l app.kubernetes.io/instance=rhdh --tail=-1 | sed 's/.\[[0-9]*m//g'`