{ callPackage, fetchFromGitHub, makeRustPlatform }:

{ date, channel }:

let
  mozillaOverlay = fetchFromGitHub {
    owner = "mozilla";
    repo = "nixpkgs-mozilla";
    rev = "0510159186dd2ef46e5464484fbdf119393afa58";
    sha256 = "1c6r5ldkh71v6acsfhni7f9sxvi7xrqzshcwd8w0hl2rrqyzi58w";
  };
  mozilla = callPackage "${mozillaOverlay.out}/package-set.nix" {};
  rustSpecific = (mozilla.rustChannelOf { inherit date channel; }).rust;
in makeRustPlatform
{
  cargo = rustSpecific;
  rustc = rustSpecific;
}
