## Janus on OpenShift

Installation of Janus, upstream of Red Hat Developer Hub.

Set environment variables in `./.env` then deploy with `./deploy/deploy.sh`.

Because the GitHub modules are enabled you'll need to enable GitHub auth. To do
so create a GitHub app as described in [this upstream
doc](https://backstage.io/docs/integrations/github/github-apps/) and create a
file in this directory named `github-app-credentials.yaml` as described in that
doc.

The file `github-app-credentials.yaml.tpl` is meant as an example at the moment.


## Tips

- Remove color coding from logs: `kubectl logs -l app.kubernetes.io/instance=rhdh --tail=-1 | sed 's/.\[[0-9]*m//g'`