{ ... }:

{
  imports = [
    ./dev/lang-c
    ./dev/lang-python
    ./dev/lang-web

    ./globals
    ./home
    ./nix

    ./programs/cli/bat
    ./programs/cli/buku
    ./programs/cli/cht
    ./programs/cli/dircolors
    ./programs/cli/fzf
    ./programs/cli/git
    ./programs/cli/lsd
    ./programs/cli/nix-direnv
    ./programs/cli/ptsh
    ./programs/cli/zoxide
    ./programs/cli/zsh

    ./programs/gui/alacritty
    ./programs/gui/discord
    ./programs/gui/firefox
    ./programs/gui/kitty
    ./programs/gui/mpv
    ./programs/gui/qutebrowser
    ./programs/gui/vscode

    ./programs/others

    ./programs/tui/amfora
    ./programs/tui/bottom
    ./programs/tui/less
    ./programs/tui/lynx
    ./programs/tui/mangadesk
    ./programs/tui/mangal
    ./programs/tui/neovim
    ./programs/tui/newsboat
    ./programs/tui/nnn
    ./programs/tui/presenterm
    ./programs/tui/taskwarrior
    ./programs/tui/tmux
    ./programs/tui/youtube
  ];

  config._custom.hm.imports = [ ./symlinks ];
}
