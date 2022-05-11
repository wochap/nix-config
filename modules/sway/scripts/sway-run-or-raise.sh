#!/usr/bin/env bash
# https://gitlab.com/wef/dotfiles/-/blob/master/bin/sway-run-or-raise

TIME_STAMP="20211102.175352"

# Copyright (C) 2020-2021 Bob Hepple <bob dot hepple at gmail dot com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

PROG=$(basename $0)

case "$1" in
-h | --help)
  echo "Usage: $PROG jump to a running program and focus it - else start it"
  exit 0
  ;;
esac

target="$1"
class="$2"
runstring="$3"

[[ "$class" ]] || class="$target"
[[ "$runstring" ]] || runstring="$target"

pkill -0 $target || {
  eval $runstring &
  exit 0
}

swaymsg "[app_id=$target] focus" &>/dev/null || {
  # could be Xwayland app:
  swaymsg "[class=$class] focus" &>/dev/null
}

exit 0

# Local Variables:
# mode: shell-script
# time-stamp-pattern: "4/TIME_STAMP=\"%:y%02m%02d.%02H%02M%02S\""
# eval: (add-hook 'before-save-hook 'time-stamp)
# End:
