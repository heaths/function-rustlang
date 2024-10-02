# Azure Functions using Rust

You can [develop Azure Functions using Rust](https://learn.microsoft.com/azure/azure-functions/create-first-function-vs-code-other). This repository contains a template using debugging configuration for Visual Studio Code that overrides the executable used when debugging.

## Prerequisites

* [Azure Developer CLI][azd]
* [Rust](https://www.rust-lang.org)
  (*Tested against 1.81 but any recent version should work.*)
* (Optional) [Azure Functions CLI][func]

## Deployment

This repository is configured to support both continuous deployment using [GitHub Actions] and manual deployment using [azd].

To support either scenario, you can provision resources using `azd`:

```bash
azd provision
```

### Continuous

The [GitHub Actions] workflows in `.github/workflows` are defined as follows:

* [`pr.yml`](.github/workflows/pr.yml): Lints and tests pull requests before they can be merged to `main`.
* [`cd.yml`](.github/workflows/cd.yml): Builds a release binary to run natively on an Azure Functions host.

#### Environments

We'll create two environments: "test" and "production" to match our provisioned slot names.

1. In your project settings, click **Environments**.
2. Create an environment named "production". Set the **Deployment branch and tags** to `main`. I recommend you also set required reviewers accordingly.
3. Repeat the previous step to create an environment named "test". You do not need to set required reviewers.

With your resources provisioned, you can set up [OpenID Connect][OIDC] to deploy to staging and production environments:

1. [Register an application](https://learn.microsoft.com/entra/identity-platform/howto-create-service-principal-portal) to log in from GitHub Actions. You can leave the redirect URL blank.
2. [Harden access](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#configuring-the-oidc-trust-with-the-cloud) when adding new client secrets:
   1. Under **Managed**, click on **Certificates and secrets**.
   2. Click **Federated credentials**.
   3. Click **Add credential**.
   4. Select the **GitHub Actions deploying Azure resources** scenario.
   5. Fill in the information requested including the environment name e.g., "test" we created above.
   6. Name your credential to identify which environment will require it e.g., "test".
   7. Click **Add**.
   8. Repeat the previous steps for the "production" environment.
3. For each environment created above, add the following [environment secrets][GitHub secrets]:

   Variable | Description
   --- | ---
   `AZURE_SUBSCRIPTION_ID` | The subscription ID to which you registered the application above.
   `AZURE_TENANT_ID` | The tenant ID of the application.
   `AZURE_CLIENT_ID` | The client ID of the application.

   Alternatively, you could set these once as repository secrets if they have the same value. This example demonstrates configuration in case different environments are in different subscriptions.
4. Add [GitHub secrets] for your provisioned `AZURE_RESOURCE_GROUP` and `AZURE_FUNCTIONAPP_NAME`. These were output when you ran `azd provision`.

Now when you merge to `main` the Azure Functions app will deploy first to your test (staging) environment, test that the application is running and responds with the expected text, then deploys to your production environment.

### Manual

You can provision resource and deploy the app with a single [azd] command:

```bash
azd up
```

If you would like to better understand the process to adapt to your situation, you can use the following steps instead:

1. Provision the function app and related resources:

   ```bash
   azd provision
   ```

   You can also deploy the `infra/main.bicep` template directly using the `az` CLI but `azd` handles authentication, if necessary, as well as reading any environment variables already set from previous deployments or by the host process.

2. Build a release binary for the Functions linux runtime host image:

   ```bash
   cargo build --release --target x86_64-unknown-linux-musl
   ```

3. Package required files for a custom host. This command may vary depending on what zip application you use:

   ```bash
   zip deploy.zip host.json hello/function.json target/x86_64-unknown-linux-musl/release/handler
   ```

4. Publish the `deploy.zip` created in the previous step using the resource group name and function app name used when provisioning:

   ```bash
   eval $(azd env get-values) # or source from .env file for environment under .azure/
   az functionapp deployment source config-zip -g $AZURE_RESOURCE_GROUP -n $AZURE_FUNCTIONAPP_NAME --src deploy.zip
   ```

5. You can now test that the function was successfully deployed:

   ```bash
   curl $AZURE_FUNCTIONAPP_URL/api/hello
   ```

#### Delete

To delete resources created by `azd`, run:

```bash
azd down
```

[azd]: https://aka.ms/azure-dev
[func]: https://learn.microsoft.com/azure/azure-functions/functions-run-local
[GitHub Actions]: https://docs.github.com/actions
[GitHub secrets]: https://docs.github.com/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions
[OIDC]: https://docs.github.com/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-azure
