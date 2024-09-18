// Copyright 2024 Heath Stewart.
// Licensed under the MIT License. See LICENSE.txt in the project root for license information.

use std::{env, num::ParseIntError};

pub fn hello(name: Option<&str>) -> String {
    let name = name.unwrap_or("world");
    format!("Hello, {name}!").to_string()
}

#[test]
fn test_hello() {
    assert_eq!(hello(Some("everyone")), String::from("Hello, everyone!"));
    assert_eq!(hello(None), String::from("Hello, world!"));
}

/// Gets the configured Azure Functions port from environment variable `FUNCTIONS_CUSTOMHANDLER_PORT`
/// or returns the [default port number 7071](https://learn.microsoft.com/azure/azure-functions/functions-core-tools-reference#func-start).
pub fn default_port() -> Result<u16, ParseIntError> {
    // `func host --help` documents 7071 as the default port.
    env::var("FUNCTIONS_CUSTOMHANDLER_PORT").map_or_else(|_| Ok(7071), |val| val.parse())
}
