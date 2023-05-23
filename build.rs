extern crate cbindgen;

use std::env::{self, Vars};
use std::path::PathBuf;
use cbindgen::{Config, Language};

fn main() {
    // For some reason, the cfg!() macros won't cooperate, so Alexis is doing this herself
    let target_arch: String = env::var("CARGO_CFG_TARGET_ARCH").unwrap();
    let target_os: String = env::var("CARGO_CFG_TARGET_OS").unwrap();

    // Only Emscripten builds need the javascript generation flag set
    if (target_arch == "wasm32" || target_arch == "wasm64") && target_os == "emscripten" {
        create_emscripten_wasm();
    }

    // Bindings are only usable when building libs
    create_bindings();
}

fn create_emscripten_wasm() {
    // This is only to run for the wasm32-unknown-emscripten target
    // println!("cargo:warning=Building Emscripten Wasm");
    let output_file: String = target_dir()
    .join("wasm")
    .join(format!("{}.{}", "main", "js"))
    .display()
    .to_string();

    println!("cargo:rustc-env=EMCC_CFLAGS=-s ERROR_ON_UNDEFINED_SYMBOLS=0 --no-entry");
    println!("cargo:rustc-link-arg=-o{output_file}");
}

fn create_bindings() {
    let crate_directory: String = env::var("CARGO_MANIFEST_DIR").unwrap();
    let package_name: String = env::var("CARGO_PKG_NAME").unwrap();

    create_binding("h", Language::C, &package_name, &crate_directory);
    create_binding("hpp", Language::Cxx, &package_name, &crate_directory);
    create_binding("pyx", Language::Cython, &package_name.replace("-", "_"), &crate_directory);
}

fn create_binding(extension: &str, language: Language, package_name: &String, crate_directory: &String) {
    let output_file: String = target_dir()
    .join("binding")
    .join(format!("{}.{}", package_name, extension))
    .display()
    .to_string();

    let config: Config = Config {
        namespace: Some(String::from("ffi")),
        language: language,
        ..Default::default()
    };

    cbindgen::generate_with_config(&crate_directory, config)
        .unwrap()
        .write_to_file(&output_file);
}

/// Find the location of the `target/` directory. Note that this may be 
/// overridden by `cmake`, so we also need to check the `CARGO_TARGET_DIR` 
/// variable.
fn target_dir() -> PathBuf {
    if let Ok(target) = env::var("CARGO_TARGET_DIR") {
        PathBuf::from(target)
    } else {
        PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap()).join("target")
    }
}

#[allow(dead_code)]
fn print_environment_vars() {
    let vars: Vars = std::env::vars();

    for (key, var) in vars {
        println!("cargo:warning=EV: {key}: {var}");
    }
}