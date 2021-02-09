set fish_greeting

# set -U fish_color_autosuggestion      brblack
# set -U fish_color_cancel              -r
# set -U fish_color_command             brgreen
# set -U fish_color_comment             brmagenta
# set -U fish_color_cwd                 green
# set -U fish_color_cwd_root            red
# set -U fish_color_end                 brmagenta
# set -U fish_color_error               brred
# set -U fish_color_escape              brcyan
# set -U fish_color_history_current     --bold
# set -U fish_color_host                normal
# set -U fish_color_match               --background=brblue
# set -U fish_color_normal              normal
# set -U fish_color_operator            cyan
# set -U fish_color_param               brblue
# set -U fish_color_quote               yellow
# set -U fish_color_redirection         bryellow
# set -U fish_color_search_match        'bryellow' '--background=brblack'
# set -U fish_color_selection           'white' '--bold' '--background=brblack'
# set -U fish_color_status              red
# set -U fish_color_user                brgreen
# set -U fish_color_valid_path          --underline
# set -U fish_pager_color_completion    normal
# set -U fish_pager_color_description   yellow
# set -U fish_pager_color_prefix        'white' '--bold' '--underline'
# set -U fish_pager_color_progress      'brwhite' '--background=cyan'

set nord0 2e3440
set nord1 3b4252
set nord2 434c5e
set nord3 4c566a
set nord4 d8dee9
set nord5 e5e9f0
set nord6 eceff4
set nord7 8fbcbb
set nord8 88c0d0
set nord9 81a1c1
set nord10 5e81ac
set nord11 bf616a
set nord12 d08770
set nord13 ebcb8b
set nord14 a3be8c
set nord15 b48ead

set fish_color_normal $nord4
set fish_color_command $nord9
set fish_color_quote $nord14
set fish_color_redirection $nord9
set fish_color_end $nord6
set fish_color_error $nord11
set fish_color_param $nord4
set fish_color_comment $nord3
set fish_color_match $nord8
set fish_color_search_match $nord8
set fish_color_operator $nord9
set fish_color_escape $nord13
set fish_color_cwd $nord8
set fish_color_autosuggestion $nord6
set fish_color_user $nord4
set fish_color_host $nord9
set fish_color_cancel $nord15
set fish_pager_color_prefix $nord13
set fish_pager_color_completion $nord6
set fish_pager_color_description $nord10
set fish_pager_color_progress $nord12
set fish_pager_color_secondary $nord1

function print_fish_colors --description 'Shows the various fish colors being used'
  set -l clr_list (set -n | grep fish | grep color | grep -v __)
  if test -n "$clr_list"
    set -l bclr (set_color normal)
    set -l bold (set_color --bold)
    printf "\n| %-38s | %-38s |\n" Variable Definition
    echo '|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|'
    for var in $clr_list
      set -l def $$var
      set -l clr (set_color $def ^/dev/null)
      or begin
        printf "| %-38s | %s%-38s$bclr |\n" "$var" (set_color --bold white --background=red) "$def"
        continue
      end
      printf "| $clr%-38s$bclr | $bold%-38s$bclr |\n" "$var" "$def"
    end
    echo '|________________________________________|________________________________________|'\n
  end
end
