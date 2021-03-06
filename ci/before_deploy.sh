#!/bin/bash
# This script takes care of building your crate and packaging it for release

set -ex

main() {
    local src=$(pwd) \
          stage=

    case $TRAVIS_OS_NAME in
        linux)
            stage=$(mktemp -d)
            ;;
        osx)
            stage=$(mktemp -d -t tmp)
            ;;
    esac

    test -f Cargo.lock || cargo generate-lockfile

    if [ -n "$TARGET" ]; then
        cross rustc --bin dness --target $TARGET --release -- -C lto
        if [ "$TARGET" = "x86_64-unknown-linux-musl" ]; then
            cargo install cargo-deb
            cross deb --target "$TARGET" --variant musl --no-build
            cp target/"$TARGET"/debian/dness*.deb $src/.
        fi

        cp target/$TARGET/release/dness $stage/
        cd $stage
        tar czf $src/$CRATE_NAME-$TRAVIS_TAG-$TARGET.tar.gz *
    else
        docker run -ti --rm -v "$(pwd):/source" rust /bin/bash -c "cd /source && cargo install cargo-deb && cargo deb"
        cp target/debian/dness*.deb $src/.
    fi

    cd $src

    rm -rf $stage
}

main
