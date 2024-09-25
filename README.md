# Azure Functions using Rust

You can [develop Azure Functions using Rust](https://learn.microsoft.com/azure/azure-functions/create-first-function-vs-code-other). This repository contains a template using debugging configuration for Visual Studio Code that overrides the executable used when debugging.

## Prerequisites

* [Azure Developer CLI](https://aka.ms/azure-dev)
* [Rust](https://www.rust-lang.org)
  (*Tested against 1.81 but any recent version should work.*)
* (Optional) [Azure Functions CLI](https://learn.microsoft.com/azure/azure-functions/functions-run-local)

## Deployment

To deploy the Azure Functions app:

1. Provision the function app and related resources:

   ```bash
   azd provision
   ```

2. Build a release binary for the x86-64 linux msul target:

   ```bash
   cargo build --release --target x86_64-unknown-linux-musl
   ```

3. Package required files for a custom host. This command may vary depending on what zip application you use:

   ```bash
   zip deploy.zip host.json hello/function.json target/x86_64-unknown-linux-musl/release/handler
   ```

4. Publish the `deploy.zip` created in the previous step using the resource group name and function app name used when provisioning:

   ```bash
   # You can source these variables from the .env file azd created under .azure/{env-name}.
   az functionapp deployment source config-zip -g $AZURE_RESOURCE_GROUP -n $AZURE_FUNCTIONAPP_NAME --src deploy.zip
   ```

5. You can now test that the function was successfully deployed:

   ```bash
   curl $AZURE_FUNCTIONAPP_URL/api/hello
   ```

### Delete

To delete resources created by `azd`, run:

```bash
azd down
```
