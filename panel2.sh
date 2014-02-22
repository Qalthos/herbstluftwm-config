#!/bin/bash
# vim: set fileencoding=utf-8 ts=4 sts=4 sw=4 tw=80 expandtab :
# Florian Bruhin <me@the-compiler.org>

monitor=$1
geometry=( $(herbstclient monitor_rect $monitor) )
x=${geometry[0]}
y=${geometry[1]}
width=${geometry[2]}

[[ $0 == /* ]] && script="$0" || script="${PWD}/${0#./}"
panelfolder=${script%/*}
trap 'herbstclient emit_hook quit_panel' TERM
herbstclient pad $monitor 16
herbstclient emit_hook quit_panel


dzen_fg="#d0d0d0"
dzen_bg="#1c1c1c"
normal_fg=""
normal_bg=
viewed_fg="#000000"
viewed_bg="#afdf87"
urgent_fg=
urgent_bg="#df8787"
used_fg="#afdf87"
used_bg=

herbstclient --idle 2>/dev/null | {
    tags=( $(herbstclient tag_status) )
    windowtitle=""
    while true; do
        for tag in "${tags[@]}" ; do
            case ${tag:0:1} in
                '#') cstart="^fg($viewed_fg)^bg($viewed_bg)" ;;
                '+') cstart="^fg($viewed_fg)^bg($viewed_bg)" ;;
                ':') cstart="^fg($used_fg)^bg($used_bg)"     ;;
                '!') cstart="^fg($urgent_fg)^bg($urgent_bg)" ;;
                *)   cstart=''                               ;;
            esac
            dzenstring="${cstart}^ca(1,herbstclient use ${tag:1}) ${tag:1} "
            dzenstring+="^ca()^fg()^bg()"
            echo -n "$dzenstring"
        done
        echo "| $windowtitle"

        # Update tags and title
        read line || exit
        hook=( $line )
        case "${hook[0]}" in
            tag*) tags=( $(herbstclient tag_status) ) ;;
            quit_panel*) exit ;;
            focus_changed|window_title_changed)
                windowtitle="^fg($dzen_fg)^bg($used_bg)${hook[@]:2}^fg()^bg()"
                ;;
        esac
    done
} | dzen2 -h 16 -fn 'DejaVu Sans Mono:size=6' -ta l -sa l \
          -x $x -y $y -w $(($width-500)) \
          -fg "$dzen_fg" -bg "$dzen_bg" &
pids+=($!)

CONKY_PIPE=/tmp/conky-pipe
if [ ! -p $CONKY_PIPE ]; then
    if [ -e $CONKY_PIPE ]; then
        rm -r $CONKY_PIPE
    fi
    mkfifo -m 600 $CONKY_PIPE
    conky -c "$panelfolder/conkyrc" > $CONKY_PIPE &
    pids+=($!)
fi
dzen2 -h 16 -fn 'DejaVu Sans Mono:size=6' -ta l -sa l \
      -x $(($x+$width-500)) -y $y -w 450 \
      -fg "$dzen_fg" -bg "$dzen_bg" < $CONKY_PIPE &
pids+=($!)

if [ $1 == 0 ]; then
    stalonetray --grow-gravity E --icon-gravity NE --kludges=force_icons_size\
                --icon-size 16 --geometry 1x1+$(($x+$width-16))+$y \
                --background '#222222' &
    pids+=($!)
fi

herbstclient --wait '^(quit_panel|reload).*'
kill -TERM "${pids[@]}" >/dev/null 2>&1
rm -f $CONKY_PIPE
exit 0
