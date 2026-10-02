{ lib }:
f: list:
# TODO: count how many elements map to each key
lib.listToAttrs (map (x: lib.nameValuePair (f x) 0) list)
