#!/bin/bash -ex

version=${1/%.?.?/}

if hash brew 2>/dev/null; then
    brew_llvm_config="$(brew --cellar)"/llvm*/${version}*/bin/llvm-config
fi

shopt -s nullglob
for llvm_config in llvm-config-$version llvm-config-${version}.0 llvm-config${version}0 llvm-config-mp-$version llvm-config-mp-${version}.0 llvm${version}-config llvm-config-${version}-32 llvm-config-${version}-64 llvm-config $brew_llvm_config; do
    llvm_version="`$llvm_config --version 2> /dev/null`" || true
    case $llvm_version in
    $version*)
        echo $($llvm_config --cxxflags)
        exit 0;;
    *)
        continue;;
    esac
done

echo "Error: LLVM ${version} is not installed."
exit 1
