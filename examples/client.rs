// Copyright 2024 Heath Stewart.
// Licensed under the MIT License. See LICENSE.txt in the project root for license information.

use handler::default_port;
use std::env;

#[tokio::main]
async fn main() {
    let url = env::args().nth(1).unwrap_or_else(|| {
        format!(
            "http://localhost:{}",
            default_port().expect("expected numeric port")
        )
    });

    let response = hello_client(&url).await.expect("expected text response");
    println!("{response}");
}

async fn hello_client(url: &str) -> reqwest::Result<String> {
    reqwest::get(format!("{url}/api/hello")).await?.text().await
}

#[tokio::test]
async fn test_hello_client() {
    let url = format!(
        "http://localhost:{}",
        default_port().expect("expected numeric port")
    );

    let response = hello_client(&url).await.expect("expected text response");
    assert_eq!(response, "Hello, world!".to_string());
}
