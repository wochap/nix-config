{
  config,
  lib,
  ...
}:

let
  cfg = config._custom.services.local-oci-images;
  ociBackend = config.virtualisation.oci-containers.backend;
  ociPackage =
    if ociBackend == "podman" then
      config.virtualisation.podman.package
    else
      config.virtualisation.docker.package;
  ociExecutable = lib.getExe ociPackage;

  imageReference = image: "localhost/${image.imageName}:${image.tag}";
  ensureServiceName = name: "local-oci-image-${name}";

  buildServices = lib.mapAttrs' (
    name: image:
    let
      reference = imageReference image;
      contextPath =
        if image.context == "." then toString image.source else "${image.source}/${image.context}";
    in
    lib.nameValuePair (ensureServiceName name) {
      description = "Ensure the local ${image.imageName} OCI image exists";
      wants = [ "network-online.target" ];
      requires = lib.optionals (ociBackend == "docker") [ "docker.service" ];
      after = [ "network-online.target" ] ++ lib.optionals (ociBackend == "docker") [ "docker.service" ];
      path = [ ociPackage ];
      script = ''
        if ${ociExecutable} image inspect ${lib.escapeShellArg reference} >/dev/null 2>&1; then
          exit 0
        fi

        exec ${ociExecutable} build \
          --tag ${lib.escapeShellArg reference} \
          --file ${lib.escapeShellArg "${contextPath}/${image.dockerfile}"} \
          ${lib.escapeShellArg contextPath}
      '';
      # Do not remain active: every container start must recheck the image
      # store so a manually pruned image is rebuilt.
      serviceConfig = {
        Type = "oneshot";
        TimeoutStartSec = "infinity";
      };
    }
  ) cfg;

  containerServices = lib.mapAttrs' (
    name: _:
    let
      serviceName = config.virtualisation.oci-containers.containers.${name}.serviceName;
      buildUnit = "${ensureServiceName name}.service";
    in
    lib.nameValuePair serviceName {
      requires = [ buildUnit ];
      after = [ buildUnit ];
    }
  ) cfg;
in
{
  options._custom.services.local-oci-images = lib.mkOption {
    default = { };
    description = "OCI images built locally from immutable source paths before their containers start.";
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            source = lib.mkOption {
              type = lib.types.path;
              description = "Immutable source path containing the image build context.";
            };

            tag = lib.mkOption {
              type = lib.types.str;
              description = "Tag used for the locally built image.";
            };

            imageName = lib.mkOption {
              type = lib.types.str;
              default = name;
              description = "Image name below the localhost registry namespace.";
            };

            context = lib.mkOption {
              type = lib.types.str;
              default = ".";
              description = "Build context relative to source.";
            };

            dockerfile = lib.mkOption {
              type = lib.types.str;
              default = "Dockerfile";
              description = "Dockerfile path relative to the build context.";
            };
          };
        }
      )
    );
  };

  config = lib.mkIf (cfg != { }) {
    virtualisation.oci-containers.containers = lib.mapAttrs (_: image: {
      image = imageReference image;
      pull = "never";
    }) cfg;

    systemd.services = buildServices // containerServices;
  };
}
