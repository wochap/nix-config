# qt

> NOTE: some kde apps require restart (e.g. Dolphin)

```sh
# switch to light theme
$ ln -sf ~/.config/kdeglobals-light ~/.config/kdeglobals
$ crudini --set ~/.config/qt6ct/qt6ct.conf Appearance color_scheme_path "/home/gean/.config/qt6ct/colors/catppuccin-latte-lavender.conf"
$ crudini --set ~/.config/qt6ct/qt6ct.conf Appearance icon_theme "Tela-catppuccin_mocha_lavender-light"
$ crudini --set ~/.config/qt5ct/qt5ct.conf Appearance color_scheme_path "/home/gean/.config/qt5ct/colors/catppuccin-latte-lavender.conf"
$ crudini --set ~/.config/qt5ct/qt5ct.conf Appearance icon_theme "Tela-catppuccin_mocha_lavender-light"

# switch to dark theme
$ ln -sf ~/.config/kdeglobals-dark ~/.config/kdeglobals
$ crudini --set ~/.config/qt6ct/qt6ct.conf Appearance color_scheme_path "/home/gean/.config/qt6ct/colors/catppuccin-mocha-lavender.conf"
$ crudini --set ~/.config/qt6ct/qt6ct.conf Appearance icon_theme "Tela-catppuccin_mocha_lavender-dark"
$ crudini --set ~/.config/qt5ct/qt5ct.conf Appearance color_scheme_path "/home/gean/.config/qt5ct/colors/catppuccin-mocha-lavender.conf"
$ crudini --set ~/.config/qt5ct/qt5ct.conf Appearance icon_theme "Tela-catppuccin_mocha_lavender-dark"
```

## Doesn't work

```sh
# switch to light theme
$ kwriteconfig6 --notify --file ~/.config/kdeglobals --group General --key ColorScheme --type string CatppuccinLatteLavender.colors

# switch to dark theme
$ kwriteconfig6 --notify --file ~/.config/kdeglobals --group General --key ColorScheme --type string CatppuccinMochaLavender.colors
```
