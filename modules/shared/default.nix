{ ... }:

{
  imports = [
    ./dev/lang-c
    ./dev/lang-go
    ./dev/lang-nix
    ./dev/lang-python
    ./dev/lang-ruby
    ./dev/lang-web
    ./dev/tools

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
    ./programs/gui/foot
    ./programs/gui/kitty
    ./programs/gui/mpv
    ./programs/gui/qutebrowser
    ./programs/gui/vscode

    ./programs/others

    ./programs/tui/amfora
    ./programs/tui/bottom
    ./programs/tui/less
    ./programs/tui/lynx
    ./programs/tui/neovim
    ./programs/tui/newsboat
    ./programs/tui/nnn
    ./programs/tui/presenterm
    ./programs/tui/taskwarrior
    ./programs/tui/tmux
    ./programs/tui/youtube

    ./programs/weeb
  ];

  config._custom.hm.imports = [ ./symlinks ];
}
