# URL: https://github.com/apps/${app_name}
appId: ${GITHUB_APP_ID}
clientId: ${GITHUB_APP_CLIENT_ID}
clientSecret: ${GITHUB_APP_CLIENT_SECRET}
webhookUrl: ${GITHUB_APP_WEBHOOK_URL}
webhookSecret: ${GITHUB_APP_WEBHOOK_SECRET}
privateKey: |
  -----BEGIN RSA PRIVATE KEY-----
${GITHUB_APP_PRIVATE_KEY}
  -----END RSA PRIVATE KEY-----
