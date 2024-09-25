// Copyright 2024 Heath Stewart.
// Licensed under the MIT License. See LICENSE.txt in the project root for license information.

use std::{fs, path::Path};

fn main() {
    // Create initial local.settings.json - which should not be committed - to support local hosting.
    let path = Path::new("local.settings.json");
    if !path.exists() {
        fs::write(
            path,
            r#"{
  "IsEncrypted": false,
  "Values": {
    "AzureFunctionsJobHost__customHandler__description__defaultExecutablePath": "target/debug/handler",
    "AzureWebJobsStorage": "",
    "FUNCTIONS_WORKER_RUNTIME": "custom"
  }
}
"#,
        )
        .expect("write local.settings.json");
    }
}
