{ config, pkgs, lib, inputs, ... }:

let
  hostName = "gmbp";
  userName = "gean";
  hmConfig = config.home-manager.users.${userName};
  configDirectory = "${hmConfig.home.homeDirectory}/nix-config";
  catppuccinMochaTheme = import ../../config/mixins/catppuccin-mocha.nix;
in {
  imports = [
    inputs.nixos-hardware.nixosModules.common-pc-laptop-acpi_call
    inputs.nixos-hardware.nixosModules.apple-macbook-pro-11-5
    inputs.nixos-hardware.nixosModules.common-gpu-amd-southern-islands
    ./hardware-configuration.nix
    ./intel.nix
    ../../config/nixos.nix
  ];

  config = {
    # NOTE: can't get amdvlk working
    hardware.amdgpu.amdvlk = false;
    hardware.amdgpu.loadInInitrd = true;
    hardware.amdgpu.opencl = true;

    _userName = userName;
    _homeDirectory = "/home/${userName}";
    _configDirectory = configDirectory;
    _custom.globals.configDirectory = configDirectory;
    _custom.globals.themeColors = catppuccinMochaTheme;
    _custom.globals.isHidpi = true;

    _custom.cli.bat.enable = true;
    _custom.cli.buku.enable = true;
    _custom.cli.cht.enable = true;
    _custom.cli.git.enable = true;
    _custom.cli.nix-alien.enable = true;
    _custom.cli.nix-direnv.enable = true;
    _custom.cli.ptsh.enable = true;
    _custom.cli.zsh.enable = true;
    _custom.cli.dircolors.enable = true;
    _custom.cli.fzf.enable = true;
    _custom.cli.gpg.enable = true;
    _custom.cli.lsd.enable = true;
    _custom.cli.starship.enable = true;
    _custom.cli.youtube.enable = true;
    _custom.cli.zoxide.enable = true;

    _custom.tui.amfora.enable = true;
    _custom.tui.fontpreview-kik.enable = true;
    _custom.tui.lynx.enable = true;
    _custom.tui.mangadesk.enable = true;
    _custom.tui.mangal.enable = true;
    _custom.tui.neovim.enable = true;
    _custom.tui.newsboat.enable = true;
    _custom.tui.nnn.enable = true;
    _custom.tui.vim.enable = true;
    _custom.tui.wtf.enable = true;
    _custom.tui.bottom.enable = true;
    _custom.tui.htop.enable = true;

    _custom.gui.alacritty.enable = true;
    _custom.gui.discord.enable = true;
    _custom.gui.firefox.enable = true;
    _custom.gui.kitty.enable = true;
    _custom.gui.mpv.enable = true;
    _custom.gui.qutebrowser.enable = true;
    _custom.gui.thunar.enable = true;
    _custom.gui.vscode.enable = true;
    _custom.gui.zathura.enable = true;
    _custom.gui.imv.enable = true;

    _custom.wm.audio.enable = true;
    _custom.wm.backlight.enable = true;
    _custom.wm.bluetooth.enable = true;
    _custom.wm.calendar.enable = true;
    _custom.wm.cursor.enable = true;
    _custom.wm.dbus.enable = true;
    _custom.wm.email.enable = true;
    _custom.wm.fonts.enable = true;
    _custom.wm.gtk.enable = true;
    _custom.wm.music.enable = true;
    _custom.wm.neofetch.enable = true;
    _custom.wm.networking.enable = true;
    _custom.wm.plymouth.enable = false;
    _custom.wm.power-management.enable = true;
    _custom.wm.qt.enable = true;
    _custom.wm.xdg.enable = true;

    _custom.services.android.enable = true;
    _custom.services.android.sdk.enable = false;
    _custom.services.docker.enable = true;
    _custom.services.flatpak.enable = false;
    _custom.services.interception-tools.enable = true;
    _custom.services.ipwebcam.enable = false;
    _custom.services.mbpfan.enable = true;
    _custom.services.mongodb.enable = true;
    _custom.services.ssh.enable = true;
    _custom.services.steam.enable = false;
    _custom.services.virt.enable = true;
    _custom.services.waydroid.enable = false;
    _custom.services.gnome-keyring.enable = true;
    _custom.services.syncthing.enable = true;

    _custom.hardware.amdCpu.enable = false;
    _custom.hardware.amdGpu.enable = false;
    _custom.hardware.amdGpu.enableSouthernIslands = false;

    _custom.dwl.enable = true;
    # _custom.river.enable = true;
    # _custom.hyprland.enable = true;
    # _custom.sway.enable = true;
    _custom.waylandWm.enable = true;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "23.05"; # Did you read the comment?

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    home-manager.users.${userName} = {
      home.stateVersion = "23.05";

      _custom.programs.waybar.settings.mainBar = {
        temperature = {
          hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";
          input-filename = "temp1_input";
        };
        keyboard-state = { device-path = "/dev/input/event25"; };
      };
    };

    boot = {
      # kernel 5.15.119 works with amdgpu driver
      # https://github.com/NixOS/nixpkgs/pull/218437
      # https://github.com/NixOS/nixpkgs/pull/241759
      kernelPackages = pkgs.prevstable-kernel-pkgs.linuxPackages;

      kernelParams = [
        # needed for suspend
        "acpi_osi=Darwin"

        # disable cpu interrupts
        "acpi_mask_gpe=0x06"

        # needed function keys
        "hid_apple.fnmode=2"

        # swap alt and command keys
        "hid_apple.swap_opt_cmd=1"

        # chatgpt suggestions, power optimizations
        "i915.enable_guc=3"
        "i915.enable_fbc=1"
        "i915.enable_psr=1"
        "radeon.dpm=1"
        "radeon.runpm=1"
      ];

      kernelModules = [ "hid-apple" ];
    };

    environment.systemPackages = with pkgs;
      [
        radeontop

        # NOTE: requires installing rEFInd
        # more info on https://github.com/0xbb/gpu-switch
        gpu-switch
      ];

    networking = {
      inherit hostName;
      interfaces.wlp4s0.useDHCP = true;
    };

    services.xserver = {
      # Setup keyboard
      layout = "us";
      xkbModel = "pc104";
      xkbVariant = "";

      # Enable touchpad support (enabled default in most desktopManager).
      libinput.enable = true;
      libinput.touchpad.naturalScrolling = true;
      libinput.touchpad.tapping = false;
    };

    # Enable webcam
    hardware.facetimehd.enable = true;

    # Default cpu cpuFreqGovernor at startup
    powerManagement = {
      cpuFreqGovernor = "performance";
      cpufreq.min = 800000;
      cpufreq.max = 4000000;
    };

    # setup video drivers
    services.xserver = {
      videoDrivers = lib.mkForce [ "amdgpu" "radeon" "intel" "modesetting" ];

      deviceSection = ''
        Option "EnablePageFlip" "off"
        Option "TearFree" "false"
        Option "DRI" "3"
      '';
    };
  };
}
