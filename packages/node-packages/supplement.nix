# This file has been generated by node2nix 1.11.1. Do not edit!

{nodeEnv, fetchurl, fetchgit, nix-gitignore, stdenv, lib, globalBuildInputs ? []}:

let
  sources = {};
in
{
  node-gyp-build = nodeEnv.buildNodePackage {
    name = "node-gyp-build";
    packageName = "node-gyp-build";
    version = "4.7.0";
    src = fetchurl {
      url = "https://registry.npmjs.org/node-gyp-build/-/node-gyp-build-4.7.0.tgz";
      sha512 = "PbZERfeFdrHQOOXiAKOY0VPbykZy90ndPKk0d+CFDegTKmWp1VgOTz2xACVbr1BjCWxrQp68CXtvNsveFhqDJg==";
    };
    buildInputs = globalBuildInputs;
    meta = {
      description = "Build tool and bindings loader for node-gyp that supports prebuilds";
      homepage = "https://github.com/prebuild/node-gyp-build";
      license = "MIT";
    };
    production = true;
    bypassCache = true;
    reconstructLock = true;
  };
}
