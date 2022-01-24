## Keybindings

The keybindings for bspwm are controlled by another program called sxhkd.

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Esc</kbd> | Reloads sxhkd |
| <kbd>Super</kbd> + <kbd>v</kbd> | Show clipboard (rofi) |
| <kbd>Super</kbd> + <kbd>c</kbd> | Show calculator (rofi) |
| <kbd>Super</kbd> + <kbd>Enter</kbd> | Opens terminal (kitty) |
| <kbd>Super</kbd> + <kbd>Esc</kbd> | Opens power menu (rofi) |
| <kbd>Super</kbd> + <kbd>Space</kbd> | Opens launcher (rofi) |
| <kbd>Super</kbd> + <kbd>Print</kbd> | Take fullscreen screenshoot (flameshot) |
| <kbd>Super</kbd> + <kbd>w</kbd> | Closes window with focus |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>q</kbd> | Kills window with focus (some times it also kills the session 😐) |
| <kbd>Super</kbd> + <kbd>m</kbd> | Alternate between the tiled and monocle layout |
| <kbd>Super</kbd> + <kbd>/</kbd> | Show available keybindings (rofi) |

Window state and flags

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>y</kbd> | Send the newest marked node to the newest preselected node |
| <kbd>Super</kbd> + <kbd>t</kbd> | Set window state to tiled |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>t</kbd> | Set window state to pseudo-tiled |
| <kbd>Super</kbd> + <kbd>s</kbd> | Set window state to floating |
| <kbd>Super</kbd> + <kbd>f</kbd> | Toggle window fullscreen state |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>m</kbd> | Toggle window flag: "marked" |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>x</kbd> | Toggle window flag: "locked" |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>y</kbd> | Toggle window flag: "sticky" |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>z</kbd> | Toggle window flag: "private" |

Preselection

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>h-j-k-l</kbd> | Preselect left-bottom-top-right positions for new window. |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>1-9</kbd> | Preselect the ratio for new window. |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Space</kbd> | Cancel preselection for the focused window. |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> | Cancel preselection for the focused desktop. |

Focus and swap

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Left Click</kbd> | Swap window |
| <kbd>Super</kbd> + <kbd>`</kbd> | TODO: change, Rotate focused windows |
| <kbd>Super</kbd> + <kbd>p</kbd> | Focus parent window |
| <kbd>Super</kbd> + <kbd>b</kbd> | Focus brother window |
| <kbd>Super</kbd> + <kbd>,</kbd> | Focus first window |
| <kbd>Super</kbd> + <kbd>.</kbd> | Focus second window |
| <kbd>Super</kbd> + <kbd>j</kbd> | Switches focus between windows in the stack, going down |
| <kbd>Super</kbd> + <kbd>k</kbd> | Switches focus between windows in the stack, going up |
| <kbd>Super</kbd> + <kbd>h</kbd> | Switches focus between windows in the stack, going left |
| <kbd>Super</kbd> + <kbd>l</kbd> | Switches focus between windows in the stack, going right |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>j</kbd> | Rotates the windows in the stack, going down|
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>k</kbd> | Rotates the windows in the stack, going up |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>h</kbd> | Rotates the windows in the stack, going left |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>l</kbd> | Rotates the windows in the stack, going right |

Workspaces

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Left</kbd> | Switches to left workspace |
| <kbd>Super</kbd> + <kbd>Right</kbd> | Switches to right workspace |
| <kbd>Super</kbd> + <kbd>o</kbd> | Focus older window in the focus history |
| <kbd>Super</kbd> + <kbd>i</kbd> | Focus newer window in the focus history |
| <kbd>Super</kbd> + <kbd>1-9</kbd> | Switch focus to workspace (1-9) |
| <kbd>Super</kbd> + <kbd>shift</kbd> + <kbd>1-9</kbd> | Send focused window to workspace (1-9) |

Resize windows

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Right Click</kbd> | Resize window |

Apps

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>l</kbd> | Lock screen |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>c</kbd> | Color picker |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>f</kbd> | Opens file manager |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>s</kbd> | Takes screenshoot (flameshot) |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>b</kbd> ; <kbd>f</kbd> | Open firefox |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>b</kbd> ; <kbd>c</kbd> | Open chrome |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>b</kbd> ; <kbd>b</kbd> | Open brave |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>t</kbd> | Opens terminal (kitty) |

Kitty keybindings

| Keybinding | Action |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Enter</kbd> | Opens new window |
| <kbd>Ctrl</kbd> + <kbd>l</kbd> | Cycle layouts (change layout) |
| <kbd>Ctrl</kbd> + <kbd>`</kbd> | Cycle focused window (swap) |
| <kbd>Ctrl</kbd> + <kbd>[</kbd> | Focus next window |
| <kbd>Ctrl</kbd> + <kbd>]</kbd> | Focus previous window |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>k</kbd> | Reset window |
| <kbd>Ctrl</kbd> + <kbd>k</kbd> | Clear window |
| <kbd>Ctrl</kbd> + <kbd>f</kbd> | Search |

Dunst keybindings

| Keybinding | Action |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>Esc</kbd> | Show previous notification |
| <kbd>Ctrl</kbd> + <kbd>Space</kbd> | Close notification |

Firefox keybindings

| Keybinding | Action |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>shift</kbd> + <kbd>1</kbd> | Open google container |
| <kbd>Ctrl</kbd> + <kbd>shift</kbd> + <kbd>2</kbd> | Open work container |


