{
  inputs.nixpkgs.url =
    "github:nixos/nixpkgs?rev=b2a3852bd078e68dd2b3dfa8c00c67af1f0a7d20"; # nixos-25.05 (21 sep 2025)

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      sys = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/netboot/netboot-minimal.nix"
          ./netboot-config.nix
        ];
      };
      build = sys.config.system.build;
      netboot-artifacts = pkgs.runCommand "netboot-artifacts" { } ''
        mkdir -p $out
        ln -s ${build.kernel}/${sys.config.system.boot.loader.kernelFile} $out/bzImage
        ln -s ${build.netbootRamdisk}/initrd $out/initrd
        echo "init=${build.toplevel}/init" > $out/init_path
      '';
      start-pxe = pkgs.writeShellScriptBin "start-pxe" ''
        ARTIFACTS="${netboot-artifacts}"
        INIT_PATH=$(cat $ARTIFACTS/init_path)

        echo "=> Starting Pixiecore on port 8086..."
        echo "=> Boot your device to UEFI IP4 now!"
        echo "=> Press Ctrl+C to stop the server."

        # Run pixiecore using the absolute path from the nix store
        ${pkgs.pixiecore}/bin/pixiecore boot $ARTIFACTS/bzImage $ARTIFACTS/initrd --port 8086 --cmdline "$INIT_PATH loglevel=4"
      '';
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ pixiecore nixos-anywhere start-pxe ];
        shellHook = ''
          echo "🚀 PXE Server Environment Loaded!"
          echo "   Run 'sudo start-pxe' to instantly provision the network boot environment."
        '';
      };
    };
}
