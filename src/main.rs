// Copyright 2024 Heath Stewart.
// Licensed under the MIT License. See LICENSE.txt in the project root for license information.

use handler::{default_port, hello};
use std::{collections::HashMap, net::Ipv4Addr};
use warp::{http::Response, Filter};

#[tokio::main]
async fn main() {
    let hello_endpoint = warp::get()
        .and(warp::path("api"))
        .and(warp::path("hello"))
        .and(warp::query::<HashMap<String, String>>())
        .map(|p: HashMap<String, String>| {
            let body = hello(p.get("name").map(|name| name.as_str()));
            Response::builder()
                .header("content-type", "text/plain")
                .body(body)
        });

    let port = default_port().expect("custom handler port number");
    warp::serve(hello_endpoint)
        .run((Ipv4Addr::LOCALHOST, port))
        .await
}
