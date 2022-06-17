#!/usr/bin/env bash

dir=$(pwd)

echo
echo "Current directory $dir"

function switch_to_directory () {
    echo
    echo "Switching to $1 directory"
    cd $dir$1
}

function run_cmd(){
    eval $1 > /dev/null 2>&1
}

# Run
echo "Clean Flutter Project"
run_cmd "flutter clean"

echo "Remove Pub Lock Project"
run_cmd "rm -rf pubspec.lock"

switch_to_directory /ios

echo "Pod deintegrate"
run_cmd "pod deintegrate"

echo "Remove Pod File"
run_cmd "rm -rf Pods"

echo "Remove Cached iOS Flutter Libs"
run_cmd "rm -rf .symlinks"

echo "Remove Podfile.lock"
run_cmd "rm -rf Podfile.lock"

switch_to_directory /

echo "Get flutter packages"
run_cmd "flutter pub get"

switch_to_directory /ios

echo "Pod install & update"
run_cmd "pod install --repo-update"

switch_to_directory /

if [[ -f "l10n.yaml" ]]; then
    echo "Generate L10N"
    run_cmd "flutter gen-l10n"
fi

echo "Generate Freezed Models"
run_cmd "flutter pub run build_runner build --delete-conflicting-outputs"
