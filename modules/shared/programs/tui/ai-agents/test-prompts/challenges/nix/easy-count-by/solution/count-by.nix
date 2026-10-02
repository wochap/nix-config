{ lib }:
f: list:
lib.foldl' (
  acc: x:
  let
    k = f x;
  in
  acc // { ${k} = (acc.${k} or 0) + 1; }
) { } list
