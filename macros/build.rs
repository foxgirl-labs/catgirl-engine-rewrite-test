//! Build script for crate

use build_info_build::DependencyDepth;
use std::env;

/// Main function
fn main() {
    // Debug environment
    // print_environment_vars();

    // Generate build info
    generate_build_info();
}

/// Generate build info
fn generate_build_info() {
    let mut depth: DependencyDepth = DependencyDepth::Depth(0);

    // Track environment for rebuilds
    println!("cargo:rerun-if-env-changed=SOURCE_DATE_EPOCH");
    println!("cargo:rerun-if-env-changed=RUST_ANALYZER");
    println!("cargo:rerun-if-env-changed=DOCS_RS");

    // Custom environment variable to speed up writing code
    let rust_analyzer: bool = env::var("RUST_ANALYZER").is_ok();
    let docs_rs: bool = env::var("DOCS_RS").is_ok();
    if rust_analyzer || docs_rs {
        depth = DependencyDepth::None;
    }

    build_info_build::build_script().collect_runtime_dependencies(depth);
}

/// Print all environment variables
#[allow(dead_code)]
fn print_environment_vars() {
    let vars: std::env::Vars = std::env::vars();

    println!("Environment Variables:");
    for (key, var) in vars {
        if is_likely_secret(key.clone()) {
            println!("cargo:warning=Env: {key}: {}", mask_string(var));
        } else {
            println!("cargo:warning=Env: {key}: {var}");
        }
    }
}

/// Determines if string represents a secret
fn is_likely_secret(key: String) -> bool {
    match key.to_lowercase() {
        // Very Likely
        s if s.contains("password") => true,
        s if s.contains("secret") => true,
        s if s.contains("token") => true,

        // Kinda Iffy
        s if s.contains("ssh") => true,
        s if s.contains("webhook") => true,
        s if s.contains("release_key") => true,
        s if s.contains("release_store") => true,

        // Iffy
        s if s.contains("account") => true,
        _ => false,
    }
}

/// Repeats a string an arbitrary number of times
fn repeat_string(repetitions: usize, value: &str) -> String {
    let mut buffer: Vec<&str> = Vec::new();

    for _ in 0..repetitions {
        buffer.push(value);
    }

    buffer.join("")
}

/// Masks a secret
fn mask_string(value: String) -> String {
    let size: usize = value.chars().count();
    repeat_string(size, "*")
}