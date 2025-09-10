// Copyright 2024 Heath Stewart.
// Licensed under the MIT License. See LICENSE.txt in the project root for license information.

use clap::{arg, command};
use handler::default_port;
use std::env;

#[tokio::main]
async fn main() {
    let url: &'static str = Box::leak(Box::new(format!(
        "http://localhost:{}",
        default_port().expect("expected numeric port")
    )));
    let matches = command!()
        .arg(arg!([url] "URL to connect to").default_value(url))
        .arg(arg!(--name <NAME> "Name to say hello to"))
        .get_matches();
    let url = matches.get_one::<String>("url").expect("url required");
    let name = matches.get_one::<String>("name").map(AsRef::as_ref);

    let response = hello_client(url, name)
        .await
        .expect("expected text response");
    println!("{response}");
}

async fn hello_client(url: &str, name: Option<&str>) -> Result<String, Box<dyn std::error::Error>> {
    let mut url: reqwest::Url = format!("{url}/api/hello").parse()?;
    if let Some(name) = name {
        url.query_pairs_mut().append_pair("name", name);
    }
    Ok(reqwest::get(url).await?.text().await?)
}

#[tokio::test]
async fn test_hello_client() {
    let url = format!(
        "http://localhost:{}",
        default_port().expect("expected numeric port")
    );

    let response = hello_client(&url, None)
        .await
        .expect("expected text response");
    assert_eq!(response, "Hello, world!".to_string());
}

#[tokio::test]
async fn test_hello_name() {
    let url = format!(
        "http://localhost:{}",
        default_port().expect("expected numeric port")
    );

    let response = hello_client(&url, Some("Azure"))
        .await
        .expect("expected text response");
    assert_eq!(response, "Hello, Azure!".to_string());
}
