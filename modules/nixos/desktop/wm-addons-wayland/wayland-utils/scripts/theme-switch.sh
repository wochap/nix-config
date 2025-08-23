#!/usr/bin/env bash

set_light_theme() {
  echo "☀️ Switching to Light Theme..."
  # GTK / GNOME
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
  gsettings set org.gnome.desktop.interface color-scheme 'default'
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' # NOTE: some apps don't recognize `default` value
  gsettings set org.gnome.desktop.interface icon-theme 'Tela-catppuccin_mocha_blue-light'

  # KDE
  ln -sf ~/.config/kdeglobals-light ~/.config/kdeglobals

  # Qt6
  crudini --set ~/.config/qt6ct/qt6ct.conf Appearance color_scheme_path "$HOME/.config/qt6ct/colors/catppuccin-latte-lavender.conf"
  crudini --set ~/.config/qt6ct/qt6ct.conf Appearance icon_theme "Tela-catppuccin_mocha_lavender-light"

  # Qt5
  crudini --set ~/.config/qt5ct/qt5ct.conf Appearance color_scheme_path "$HOME/.config/qt5ct/colors/catppuccin-latte-lavender.conf"
  crudini --set ~/.config/qt5ct/qt5ct.conf Appearance icon_theme "Tela-catppuccin_mocha_blue-light"

  # Foot
  killall -SIGUSR2 foot

  # lsd
  ln -sf ~/.config/lsd/light.yaml ~/.config/lsd/colors.yaml

  # khal
  ln -sf ~/.config/khal/config-light ~/.config/khal/config

  # cava
  ln -sf ~/.config/cava/config-light ~/.config/cava/config
  pkill -USR2 cava

  # bottom
  ln -sf ~/.config/bottom/bottom-light.toml ~/.config/bottom/bottom.toml

  # newsboat
  ln -sf ~/.config/newsboat/theme-light ~/.config/newsboat/theme

  # tofi
  ln -sf ~/.config/tofi/one-line-theme-light ~/.config/tofi/one-line-theme

  # dunst
  ln -sf ~/.config/dunst/dunstrc-light ~/.config/dunst/dunstrc
  pkill -u "$USER" dunst

  # dircolors
  ln -sf ~/.dir_colors-light ~/.dir_colors

  # presenterm
  ln -sf ~/.config/presenterm/config-light.yaml ~/.config/presenterm/config.yaml

  # quickshell
  rm -rf ~/.config/quickshell/theme.json
  cp -L ~/.config/quickshell/theme-light.json ~/.config/quickshell/theme.json

  if [[ "$XDG_CURRENT_DESKTOP" == "Hyprland" ]]; then
    # Hyprland
    ln -sf ~/.config/hypr/colors-light.conf ~/.config/hypr/colors.conf
    hyprctl reload

    hyprshade on oled-saver

    hyprctl hyprsunset temperature 4000
  fi
}

set_dark_theme() {
  echo "🎨 Switching to Dark Theme..."
  # GTK / GNOME
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  gsettings set org.gnome.desktop.interface icon-theme 'Tela-catppuccin_mocha_blue-dark'

  # KDE
  ln -sf ~/.config/kdeglobals-dark ~/.config/kdeglobals

  # Qt6
  crudini --set ~/.config/qt6ct/qt6ct.conf Appearance color_scheme_path "$HOME/.config/qt6ct/colors/catppuccin-mocha-lavender.conf"
  crudini --set ~/.config/qt6ct/qt6t.conf Appearance icon_theme "Tela-catppuccin_mocha_lavender-dark"

  # Qt5
  crudini --set ~/.config/qt5ct/qt5ct.conf Appearance color_scheme_path "$HOME/.config/qt5ct/colors/catppuccin-mocha-lavender.conf"
  crudini --set ~/.config/qt5ct/qt5ct.conf Appearance icon_theme "Tela-catppuccin_mocha_blue-dark"

  # Foot
  killall -SIGUSR1 foot

  # lsd
  ln -sf ~/.config/lsd/dark.yaml ~/.config/lsd/colors.yaml

  # khal
  ln -sf ~/.config/khal/config-dark ~/.config/khal/config

  # cava
  ln -sf ~/.config/cava/config-dark ~/.config/cava/config
  pkill -USR2 cava

  # bottom
  ln -sf ~/.config/bottom/bottom-dark.toml ~/.config/bottom/bottom.toml

  # newsboat
  ln -sf ~/.config/newsboat/theme-dark ~/.config/newsboat/theme

  # tofi
  ln -sf ~/.config/tofi/one-line-theme-dark ~/.config/tofi/one-line-theme

  # dunst
  ln -sf ~/.config/dunst/dunstrc-dark ~/.config/dunst/dunstrc
  pkill -u "$USER" dunst

  # dircolors
  ln -sf ~/.dir_colors-dark ~/.dir_colors

  # presenterm
  ln -sf ~/.config/presenterm/config-dark.yaml ~/.config/presenterm/config.yaml

  # quickshell
  rm -rf ~/.config/quickshell/theme.json
  cp -L ~/.config/quickshell/theme-dark.json ~/.config/quickshell/theme.json

  # Hyprland
  if [[ "$XDG_CURRENT_DESKTOP" == "Hyprland" ]]; then
    ln -sf ~/.config/hypr/colors-dark.conf ~/.config/hypr/colors.conf
    hyprctl reload
  fi
}

# Check for command-line arguments (e.g., ./script.sh dark)
case "$1" in
dark)
  set_dark_theme
  ;;
light)
  set_light_theme
  ;;
*)
  # If no argument, toggle the theme automatically
  echo "🤔 Checking current theme to toggle..."
  CURRENT_SCHEME=$(color-scheme print)

  if [[ "$CURRENT_SCHEME" == "dark" ]]; then
    # If currently dark, switch to light
    set_light_theme
  else
    # Otherwise, switch to dark
    set_dark_theme
  fi
  ;;
esac

echo "✅ Done."
