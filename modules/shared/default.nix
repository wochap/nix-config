{ ... }:

{
  imports = [
    ./globals
    ./home
    ./nix

    ./programs/cli/asciinema
    ./programs/cli/bat
    ./programs/cli/buku
    ./programs/cli/cht
    ./programs/cli/dircolors
    ./programs/cli/fzf
    ./programs/cli/git
    ./programs/cli/lsd
    ./programs/cli/nodejs
    ./programs/cli/ptsh
    ./programs/cli/python
    ./programs/cli/starship
    ./programs/cli/zoxide
    ./programs/cli/zsh

    ./programs/gui/alacritty
    ./programs/gui/discord
    ./programs/gui/firefox
    ./programs/gui/kitty
    ./programs/gui/mpv
    ./programs/gui/qutebrowser
    ./programs/gui/retroarch
    ./programs/gui/vscode

    ./programs/suites

    ./programs/tui/amfora
    ./programs/tui/bottom
    ./programs/tui/less
    ./programs/tui/lynx
    ./programs/tui/mangadesk
    ./programs/tui/mangal
    ./programs/tui/neovim
    ./programs/tui/newsboat
    ./programs/tui/nnn
    ./programs/tui/taskwarrior
    ./programs/tui/tmux
    ./programs/tui/youtube
  ];
}
