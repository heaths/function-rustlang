# Contributing guide

You can make and test changes to this template repo. Make sure you have the prerequisites from the [README](README.md) including the [Azure Functions CLI](https://learn.microsoft.com/azure/azure-functions/functions-run-local) and use one of the following for the best experience:

* Open the repo directly in [Visual Studio Code](https://code.visualstudio.com)
* Open in a [devcontainer](https://containers.dev) within Visual Studio Code
* Open the [repo](https://github.com/heaths/function-rustlang) in [GitHub Codespaces](https://github.com/features/codespaces)

## Building

You can run `cargo build`. By default, a `local.settings.json` file is created (if absent) referencing the debug target. You can change this file as needed but should not commit it. To avoid accidental commits, this file is ignored by `.gitignore`.

You can also change the path to the handler by either:

1. Setting the `AzureFunctionsJobHost__customHandler__description__defaultExecutablePath` environment variable e.g.:

   ```bash
   AzureFunctionsJobHost__customHandler__description__defaultExecutablePath=target/release/handler func start
   ```

2. Changing the `AzureFunctionsJobHost__customHandler__description__defaultExecutablePath` variable in `local.settings.json`.

When running `func start`, the host will first use an environment variable with this name before checking for a local configuration variable with the same name.

## Debugging

Visual Studio Code and Codespaces are configured to automatically debug the `target/debug/handler` when you press F5. This will start the function host and attach to the default `target/debug/handler` application.

This is accomplished by setting the `AzureFunctionsJobHost__customHandler__description__defaultExecutablePath` environment variable to the default application path in `.vscode/tasks.json` when starting the host and attaching to the same application path in `.vscode/launch.json`.

You can run `curl` against the default `http://localhost:7071/api/hello` endpoint, or run the `client` example:

```bash
cargo run --example client
```
