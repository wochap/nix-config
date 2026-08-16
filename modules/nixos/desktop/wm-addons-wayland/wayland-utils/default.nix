{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config._custom.desktop.wayland-utils;
  inherit (config._custom.globals) isSandbox;

  wayfreeze = inputs.wayfreeze.packages.${pkgs.stdenv.hostPlatform.system}.wayfreeze;
  hyprpicker = inputs.hyprpicker.packages.${pkgs.stdenv.hostPlatform.system}.hyprpicker;
  play-notification-sound = pkgs.writeScriptBin "play-notification-sound" (
    builtins.readFile ./scripts/play-notification-sound.sh
  );
  color-picker = pkgs.writeScriptBin "color-picker" (builtins.readFile ./scripts/color-picker.sh);
  ruler = pkgs.writeScriptBin "ruler" (builtins.readFile ./scripts/ruler.sh);
  takeshot = pkgs.writeScriptBin "takeshot" (builtins.readFile ./scripts/takeshot.sh);
  ocr = pkgs.writeScriptBin "ocr" (builtins.readFile ./scripts/ocr.sh);
  ocr-math = pkgs.writeScriptBin "ocr-math" (builtins.readFile ./scripts/ocr-math.sh);
  recorder = pkgs.writeScriptBin "recorder" (builtins.readFile ./scripts/recorder.sh);
  tui-bookmarks = pkgs.writeScriptBin "tui-bookmarks" (builtins.readFile ./scripts/tui-bookmarks.sh);
  tui-calendar = pkgs.writeScriptBin "tui-calendar" (builtins.readFile ./scripts/tui-calendar.sh);
  tui-email = pkgs.writeScriptBin "tui-email" (builtins.readFile ./scripts/tui-email.sh);
  tui-monitor = pkgs.writeScriptBin "tui-monitor" (builtins.readFile ./scripts/tui-monitor.sh);
  tui-music = pkgs.writeScriptBin "tui-music" (builtins.readFile ./scripts/tui-music.sh);
  tui-notes = pkgs.writeScriptBin "tui-notes" (builtins.readFile ./scripts/tui-notes.sh);
  tui-notes-obsidian = pkgs.writeScriptBin "tui-notes-obsidian" (
    builtins.readFile ./scripts/tui-notes-obsidian.sh
  );
  tui-rss = pkgs.writeScriptBin "tui-rss" (builtins.readFile ./scripts/tui-rss.sh);
  theme-switch = pkgs.writeScriptBin "theme-switch" (builtins.readFile ./scripts/theme-switch.sh);
  color-scheme = pkgs.writeScriptBin "color-scheme" (builtins.readFile ./scripts/color-scheme.sh);
  tts-clipboard = pkgs.writeScriptBin "tts-clipboard" (builtins.readFile ./scripts/tts-clipboard.sh);
  voice-clean = pkgs.writeScriptBin "voice-clean" (builtins.readFile ./scripts/voice-clean.sh);
in
{
  options._custom.desktop.wayland-utils = {
    enable = lib.mkEnableOption { };
    enableTts = lib.mkEnableOption "the local Supertonic text-to-speech service";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      _custom.hm = {
        home.packages = with pkgs; [
          libnotify # send notifications
          wl-clipboard
          theme-switch
          color-scheme
        ];

        home.shellAliases = {
          "cpi" = ''wl-copy -t text/uri-list <<<file:/"$@"'';
          "cpt" = ''wl-copy --trim-newline "$@"'';
        };
      };
    })

    (lib.mkIf (cfg.enable && (!isSandbox)) {
      nixpkgs.overlays = [
        (final: prev: {
          showmethekey = prev.showmethekey.overrideAttrs (oldAttrs: rec {
            version = "v1.15.1+g${inputs.showmethekey.shortRev or "dirty"}";
            src = inputs.showmethekey;
            patches = [ ./patches/showmethekey-remove-header.patch ];
          });
        })
      ];

      # allow gpu-screen-recorder to run as root
      security.wrappers.gsr-kms-server = {
        source = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
        capabilities = "cap_sys_admin+ep";
        owner = "root";
        group = "root";
        setuid = false;
      };

      _custom.hm = {
        home.packages =
          with pkgs;
          [
            mpvpaper # mpv as wallpaper
            grim # screenshoot utility
            hyprpicker # color picker
            showmethekey
            slurp # screenshoot utility
            satty # image editor
            swaybg
            wayfreeze # freeze display, only works on hyprland
            wdisplays # control display outputs
            wf-recorder # screen recorder utility
            wl-mirror # mirror outputs
            wl-screenrec # screen recorder utility (faster)
            gpu-screen-recorder # screen recorder
            wlr-randr
            wlrctl # control keyboard, mouse and wm from cli
            tesseract5 # ocr
            cage # wm

            play-notification-sound
            color-picker
            ruler
            recorder
            takeshot
            ocr
            ocr-math

            tui-bookmarks
            tui-calendar
            tui-email
            tui-monitor
            tui-music
            tui-notes
            tui-notes-obsidian
            tui-rss
            voice-clean
          ]
          ++ lib.optionals (config._custom.programs.ai-agents.enableHandy) [ voice-clean ];

        xdg.configFile."satty/config.toml".source = ./dotfiles/satty-config.toml;
        xdg.dataFile."assets/notification.flac".source = ./assets/notification.flac;
      };
    })

    (lib.mkIf (cfg.enable && cfg.enableTts) {
      _custom.hm = {
        home.packages = [
          pkgs._custom.supertonic
          tts-clipboard
        ];

        systemd.user.services.supertonic = {
          Unit = {
            Description = "Supertonic text-to-speech service";
            Documentation = "https://supertone-inc.github.io/supertonic-py/quickstart/#local-server";
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${lib.getExe pkgs._custom.supertonic} serve --host 127.0.0.1 --port 7788";
            Restart = "on-failure";
            RestartSec = 2;
            # PERF: test those env vars
            # "SUPERTONIC_INTRA_OP_THREADS=8"
            # "SUPERTONIC_INTER_OP_THREADS=8"
            Environment = [ "HF_HUB_DISABLE_TELEMETRY=1" ];
          }
          // lib._custom.userServiceHardening
          // {
            ProtectHome = "tmpfs";
            BindPaths = [
              "%h/.cache/supertonic3"
              "%h/.cache/huggingface"
            ];
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
              "AF_UNIX"
            ];
          };
        };
      };
    })
  ];
}
