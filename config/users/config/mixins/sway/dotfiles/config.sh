# Set sway font
# font pango:Iosevka Nerd Font 10

### Variables
#
# Logo key. Use Mod1 for Alt.
set $mod Mod4
# Home row direction keys, like vim
set $left h
set $down j
set $up k
set $right l
# Your preferred terminal emulator
set $term kitty
# Your preferred application launcher
# Note: pass the final command to swaymsg so that the resulting window can be opened
# on the original workspace that the command was run on.
set $menu dmenu_path | dmenu | xargs swaymsg exec --

### Output configuration
#
# Default wallpaper (more resolutions are available in @datadir@/backgrounds/sway/)
# output * bg @datadir@/backgrounds/sway/Sway_Wallpaper_Blue_1920x1080.png fill
#
# Example configuration:
#
#   output HDMI-A-1 resolution 1920x1080 position 1920,0
#
# You can get the names of your outputs by running: swaymsg -t get_outputs
output eDP scale 2
output DisplayPort-0 scale 1.5
output * bg /home/gean/Pictures/backgrounds/default.jpg fill

### Idle configuration
#
# Example configuration:
#
# exec swayidle -w \
#          timeout 300 'bash /etc/scripts/sway-lock.sh' \
#          timeout 600 'swaymsg "output * dpms off"' resume 'swaymsg "output * dpms on"' \
#          before-sleep 'bash /etc/scripts/sway-lock.sh'
#
# This will lock your screen after 300 seconds of inactivity, then turn off
# your displays after another 300 seconds, and turn your screens back on when
# resumed. It will also lock your screen before your computer goes to sleep.

# exec blueberry-tray
# exec volumeicon

### Configuration
default_border pixel 8
for_window [class=".*"] border pixel 8
gaps inner 32
gaps outer 10
focus_follows_mouse no
client.focused        	 	#12151d    #12151d    #abb2bf    #c678dd    #12151d
client.unfocused        	#1e222a    #1e222a    #abb2bf	 #282c34    #282c34
client.focused_inactive 	#1e222a    #1e222a    #abb2bf    #282c34    #282c34
client.urgent	          	#e06c75    #1e222a    #abb2bf    #e06c75    #e06c75
# client.focused #4DD0E1 #285577 #ffffff #2e9ef4 #285577
# client.focused_inactive #4DD0E1
# client.placeholder #4DD0E1
# client.unfocused #00000000 #222222 #888888 #292D2E #222222
# client.urgent #DC322F #900000 #ffffff #900000 #900000
# border_images.focused /etc/sway/borders/dropShadowDark.png
# border_images.focused_inactive /etc/sway/borders/dropShadowDark.png
# border_images.unfocused /etc/sway/borders/dropShadowDark.png
# border_images.urgent /etc/sway/borders/dropShadowDark.png

### Input configuration
#
# Example configuration:
#
#   input "2:14:SynPS/2_Synaptics_TouchPad" {
#       dwt enabled
#       tap enabled
#       natural_scroll enabled
#       middle_emulation enabled
#   }
#
# You can get the names of your inputs by running: swaymsg -t get_inputs
# Read `man 5 sway-input` for more information about this section.

### Key bindings
#
# Basics:
#
    # bindsym XF86AudioRaiseVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ +1%'
    # bindsym XF86AudioLowerVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ -1%'
    # bindsym XF86AudioMute exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle'

    # Start a terminal
    bindsym $mod+Return exec $term

    # Kill focused window
    bindsym $mod+Shift+q kill

    # Start your launcher
    bindsym $mod+space exec $menu

    # Drag floating windows by holding down $mod and left mouse button.
    # Resize them with right mouse button + $mod.
    # Despite the name, also works for non-floating windows.
    # Change normal to inverse to use left mouse button for resizing and right
    # mouse button for dragging.
    floating_modifier $mod normal

    # Reload the configuration file
    bindsym $mod+Ctrl+Escape reload

    # Exit sway (logs you out of your Wayland session)
    # bindsym $mod+Escape exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'
#
# Moving around:
#
    # Move your focus around
    bindsym $mod+$left focus left
    bindsym $mod+$down focus down
    bindsym $mod+$up focus up
    bindsym $mod+$right focus right

    # Move the focused window with the same, but add Shift
    bindsym $mod+Shift+$left move left
    bindsym $mod+Shift+$down move down
    bindsym $mod+Shift+$up move up
    bindsym $mod+Shift+$right move right
#
# Workspaces:
#
    # Switch to workspace
    bindsym $mod+1 workspace number 1
    bindsym $mod+2 workspace number 2
    bindsym $mod+3 workspace number 3
    bindsym $mod+4 workspace number 4
    bindsym $mod+5 workspace number 5
    bindsym $mod+6 workspace number 6
    bindsym $mod+7 workspace number 7
    bindsym $mod+8 workspace number 8
    bindsym $mod+9 workspace number 9
    bindsym $mod+0 workspace number 10
    bindsym $mod+F1 workspace number 5
    bindsym $mod+F2 workspace number 6
    bindsym $mod+F3 workspace number 7
    bindsym $mod+F4 workspace number 8
    # Move focused container to workspace
    bindsym $mod+Shift+1 move container to workspace number 1
    bindsym $mod+Shift+2 move container to workspace number 2
    bindsym $mod+Shift+3 move container to workspace number 3
    bindsym $mod+Shift+4 move container to workspace number 4
    bindsym $mod+Shift+5 move container to workspace number 5
    bindsym $mod+Shift+6 move container to workspace number 6
    bindsym $mod+Shift+7 move container to workspace number 7
    bindsym $mod+Shift+8 move container to workspace number 8
    bindsym $mod+Shift+9 move container to workspace number 9
    bindsym $mod+Shift+0 move container to workspace number 10
    bindsym $mod+Shift+F1 move container to workspace number 5
    bindsym $mod+Shift+F2 move container to workspace number 6
    bindsym $mod+Shift+F3 move container to workspace number 7
    bindsym $mod+Shift+F4 move container to workspace number 8
    # Note: workspaces can have any name you want, not just numbers.
    # We just use 1-10 as the default.
#
# Layout stuff:
#
    # You can "split" the current object of your focus with
    # $mod+b or $mod+v, for horizontal and vertical splits
    # respectively.
    bindsym $mod+b splith
    bindsym $mod+v splitv

    # Switch the current container between different layout styles
    bindsym $mod+t layout stacking
    bindsym $mod+m layout tabbed
    bindsym $mod+i layout toggle split

    # Make the current focus fullscreen
    bindsym $mod+f fullscreen

    # Toggle the current focus between tiling and floating mode
    bindsym $mod+s floating toggle

    # Swap focus between the tiling area and the floating area
    # bindsym $mod+space focus mode_toggle

    # Move focus to the parent container
    # bindsym $mod+a focus parent
#
# Scratchpad:
#
    # Sway has a "scratchpad", which is a bag of holding for windows.
    # You can send windows there and get them back later.

    # Move the currently focused window to the scratchpad
    bindsym $mod+Shift+minus move scratchpad

    # Show the next scratchpad window or hide the focused scratchpad window.
    # If there are multiple scratchpad windows, this command cycles through them.
    bindsym $mod+minus scratchpad show
#
# Resizing containers:
#
mode "resize" {
    # left will shrink the containers width
    # right will grow the containers width
    # up will shrink the containers height
    # down will grow the containers height
    # bindsym $left resize shrink width 10px
    # bindsym $down resize grow height 10px
    # bindsym $up resize shrink height 10px
    # bindsym $right resize grow width 10px

    # Return to default mode
    # bindsym Return mode "default"
    # bindsym Escape mode "default"
}
# bindsym $mod+r mode "resize"

#
# Status Bar:
#
# Read `man 5 sway-bar` for more information about this section.
# bar {
    # swaybar_command waybar
#     position top
#
#     # When the status_command prints a new line to stdout, swaybar updates.
#     # The default just shows the current date and time.
#     status_command while date +'%Y-%m-%d %l:%M:%S %p'; do sleep 1; done
#
#     colors {
#         statusline #ffffff
#         background #323232
#         inactive_workspace #32323200 #32323200 #5c5c5c
#     }
# }

include @sysconfdir@/sway/config.d/*
