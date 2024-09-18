// Copyright 2024 Heath Stewart.
// Licensed under the MIT License. See LICENSE.txt in the project root for license information.

use std::{collections::HashMap, env, net::Ipv4Addr};
use warp::{http::Response, Filter};

#[tokio::main]
async fn main() {
    let hello_endpoint = warp::get()
        .and(warp::path("api"))
        .and(warp::path("hello"))
        .and(warp::query::<HashMap<String, String>>())
        .map(|p: HashMap<String, String>| {
            let response = Response::builder().header("content-type", "text/plain");
            if let Some(name) = p.get("name") {
                response.body(format!("Hello, {}!", name))
            } else {
                response.body(String::from("Hello, world!"))
            }
        });

    // cspell:ignore customhandler
    let port: u16 = env::var("FUNCTIONS_CUSTOMHANDLER_PORT").map_or_else(
        |_| 3000,
        |val| val.parse().expect("custom handler port number"),
    );

    warp::serve(hello_endpoint)
        .run((Ipv4Addr::LOCALHOST, port))
        .await
}
