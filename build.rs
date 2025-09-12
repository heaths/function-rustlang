// Copyright 2024 Heath Stewart.
// Licensed under the MIT License. See LICENSE.txt in the project root for license information.

// cspell:ignore splitn
use std::{env, fs, path::Path, process::Command};

fn main() {
    // Get the rustc version.
    println!("cargo::rerun-if-env-changed=RUSTC");
    println!(
        "cargo::rustc-env=RUSTC_VERSION={}",
        rustc_version().expect("expected `rustc -vV`")
    );

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

fn rustc_version() -> Option<String> {
    let path = env::var("RUSTC").ok()?;
    let stdout = String::from_utf8(Command::new(path).arg("-vV").output().ok()?.stdout).ok()?;
    for line in stdout.lines() {
        let mut iter = line.splitn(2, ":");
        if let Some("release") = iter.next() {
            return iter.next().map(|s| s.trim().to_string());
        }
    }

    None
}
