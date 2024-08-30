{ ... }:

{
  imports = [
    ./globals
    ./home
    ./nix

    ./programs/cli/bat
    ./programs/cli/buku
    ./programs/cli/cht
    ./programs/cli/core-utils
    ./programs/cli/core-utils-extra
    ./programs/cli/dircolors
    ./programs/cli/fzf
    ./programs/cli/git
    ./programs/cli/lsd
    ./programs/cli/nix-direnv
    ./programs/cli/ptsh
    ./programs/cli/texlive
    ./programs/cli/zk
    ./programs/cli/zoxide
    ./programs/cli/zsh

    ./programs/dev/lang-c
    ./programs/dev/lang-go
    ./programs/dev/lang-lua
    ./programs/dev/lang-nix
    ./programs/dev/lang-python
    ./programs/dev/lang-ruby
    ./programs/dev/lang-web
    ./programs/dev/tools

    ./programs/gui/alacritty
    ./programs/gui/discord
    ./programs/gui/firefox
    ./programs/gui/foot
    ./programs/gui/kitty
    ./programs/gui/mpv
    ./programs/gui/qutebrowser
    ./programs/gui/vscode

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
    ./programs/tui/urlscan
    ./programs/tui/youtube

    ./programs/weeb
  ];

  config._custom.hm.imports = [ ./symlinks ];
}
