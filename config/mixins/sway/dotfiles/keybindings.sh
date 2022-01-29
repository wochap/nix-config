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
