{ pkgs, ... }:

{
  # Repo-specific input for the portable web-gate module.
  config._custom.services.web-gate.certificate = pkgs._custom.wochap-ssc;
}
