#!/bin/bash
# vim: set fileencoding=utf-8 ts=4 sts=4 sw=4 tw=80 expandtab :
# Florian Bruhin <me@the-compiler.org>

[[ $0 == /* ]] && script="$0" || script="${PWD}/${0#./}"
panelfolder=${script%/*}
trap 'herbstclient emit_hook quit_panel' TERM
herbstclient pad 0 24
herbstclient emit_hook quit_panel

dzen2 -p -h 1 -w 1600 -x 0 -y 23 -bg '#afdf87' &
pids+=($!)

conky -c "$panelfolder/conkyrc" &
pids+=($!)

"$panelfolder/tags.sh" &
pids+=($!)

trayer --edge top --align right --widthtype request --heighttype pixel --height 12\
       --expand true --tint 0x222222 --transparent true --alpha 0 &
pids+=($!)

herbstclient --wait '^(quit_panel|reload).*'
kill -TERM "${pids[@]}" >/dev/null 2>&1
exit 0