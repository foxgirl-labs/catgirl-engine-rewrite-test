name: Build For Linux GNU x86_64 (Deb)
run-name: ${{ github.actor }} is building for Linux GNU x86_64 (Deb)
on: [push]
jobs:
  Build-Linux-GNU-x86-64:
    runs-on: ubuntu-20.04
    environment: Linux
    env:
      CARGO_TERM_COLOR: always
      WORKSPACE: ${{ github.workspace }}
      RUST_BACKTRACE: full
    steps:
      # Setup Build Environment
      - name: 🎉 The job was automatically triggered by a ${{ github.event_name }} event.
        run: echo "🎉 The job was automatically triggered by a ${{ github.event_name }} event."
      - name: 🐧 This job is now running on a ${{ runner.os }} server hosted by GitHub!
        run: echo "🐧 This job is now running on a ${{ runner.os }} server hosted by GitHub!"
      - name: 🔎 The name of your branch is ${{ github.ref }} and your repository is ${{ github.repository }}.
        run: echo "🔎 The name of your branch is ${{ github.ref }} and your repository is ${{ github.repository }}."
      - name: Check out repository code
        uses: actions/checkout@v3
        with:
          submodules: recursive
      - name: 💡 The ${{ github.repository }} repository has been cloned to the runner.
        run: echo "💡 The ${{ github.repository }} repository has been cloned to the runner."

      # Install Dependencies
      - name: Update APT Package Manager
        run: sudo apt update
      - name: Install APT Packages
        run: sudo apt -y install libsdl2-image-dev libsdl2-ttf-dev  # libsdl2-dev 

      # ----------------------------------------
      # Build SDL2
      - name: Deleting Old CMake Cache
        run: rm -rf ${{ github.workspace }}/android/app/jni/SDL/build
      - name: Initialize CMake
        run: cmake -DCMAKE_TOOLCHAIN_FILE=${{ github.workspace }}/.toolchains/TC-gnu-gcc-x86-64.cmake -S ${{ github.workspace }}/android/app/jni/SDL -B ${{ github.workspace }}/android/app/jni/SDL/build -DCMAKE_BUILD_RPATH=/lib/x86_64-linux-gnu # -DSDL_WAYLAND=OFF -DSDL_PULSEAUDIO=OFF -DSDL_IBUS=OFF
      - name: Make SDL2
        run: cmake --build ${{ github.workspace }}/android/app/jni/SDL/build
      # ----------------------------------------

      # Install Rust
      - name: Make Tools Directory
        run: mkdir -p ${{ github.workspace }}/tools
      - name: Download Rust Installer
        run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > ${{ github.workspace }}/tools/rust.sh
      - name: Make Rust Installer Executable
        run: chmod +x ${{ github.workspace }}/tools/rust.sh
      - name: Install Rust
        run: ${{ github.workspace }}/tools/rust.sh -y
      - name: Load Cargo Environment
        run: source "$HOME/.cargo/env"

      # Toml Files Don't Take Variables, So We Have To Hardcode The File
      - name: Setup Config.toml
        run: sed "s:\$WORKSPACE:${{ github.workspace }}:g" ${{ github.workspace }}/.cargo/config.toml.sample > ${{ github.workspace }}/.cargo/config.toml

      - name: Add x86_64 GNU Build Target
        run: $HOME/.cargo/bin/rustup target add x86_64-unknown-linux-gnu

      - name: Copy SDL Libs To Export Directory
        run: |
          mkdir -p ${{ github.workspace }}/target/libs
          cp -av ${{ github.workspace }}/android/app/jni/SDL/build/*.so* ${{ github.workspace }}/target/libs
          ln -s libSDL2-2.0.so ${{ github.workspace }}/target/libs/libSDL2.so
          ls -liallh ${{ github.workspace }}/target/libs

      # Install Deb Packager
      - name: Install Deb Packager
        run: $HOME/.cargo/bin/cargo install cargo-deb

      # Compile Program
      - name: Build Program (Deb)
        run: $HOME/.cargo/bin/cargo deb --target=x86_64-unknown-linux-gnu --variant=gnu

      # Test Program
      - name: Test Program
        run: $HOME/.cargo/bin/cargo test --verbose --target=x86_64-unknown-linux-gnu --bins --tests --benches --examples

      # Display Export Directory
      - name: Display Export Directory
        run: ls -liallh ${{ github.workspace }}/target/x86_64-unknown-linux-gnu/debian

      # Upload Engine
      - name: Upload Engine (Release)
        uses: actions/upload-artifact@v3
        with:
          name: CatgirlEngine-Linux-x86_64-GNU-Deb
          path: ${{ github.workspace }}/target/x86_64-unknown-linux-gnu/debian/*.deb

      # TODO: Upload to Itch.io (and Github Releases) On Reading "Publish" in Commit Message

      # Display Build Status
      - name: 🍏 This job's status is ${{ job.status }}.
        run: echo "🍏 This job's status is ${{ job.status }}."