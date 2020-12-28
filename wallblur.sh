#!/usr/bin/env bash

# <Constants>
cache_dir="$HOME/.cache/wallblur"
pid_file="$HOME/.wallblur.pid"
display_resolution=$(echo -n "$(xdpyinfo | grep 'dimensions:')" | awk '{print $2;}')
wallpaper_command="hsetroot -cover"
#wallpaper_command="feh --bg-fill"
# </Constants>

# check if the custom_command variable exists, you can use it to change
# the program used to set the wallpaper, if you don't want to change it in
# the script directly
if [ -n "$custom_command" ]; then
    wallpaper_command="$custom_command"
fi

# <Functions>
print_usage () {
    printf "Usage: wallblur.sh -[i,o] image/directory\n"
    printf "Detail:\n"
    printf "\t-i\tNormal mode;\n"
    printf "\t-o\tOne-shot mode, Wallblur will not close with the terminal,\n"
    printf "\t\tnor will it display messages and will kill any previous instance of this script;"
    printf "\n\n"
}

err() {
    if [ "$silent" != 1 ]; then
        echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*@" >&2
    fi
}

gen_blurred_seq () {
    notify-send "Building wallblur cache for $base_filename "

    clean_cache

    wallpaper_resolution=$(identify -format "%wx%h" "$wallpaper")

    err " Display resolution is: ""$display_resolution"""
    err " Wallpaper resolution is: $wallpaper_resolution"

    if [ "$wallpaper_resolution" != "$display_resolution" ]
    then
        err "Scaling wallpaper to match resolution"
        convert "$wallpaper" -resize "$display_resolution" "$cache_dir"/"$filename""_"0."$extension"
        wallpaper="$cache_dir"/"$filename""_"0."$extension"
        #echo "New wallpaper"
    fi

    for i in $(seq 0 1 5)
    do
        blurred_wallaper="$cache_dir/$filename""_""$i.$extension"
        convert -blur 0x"$i" "$wallpaper" "$blurred_wallaper"
        err " > Generating $(basename "$blurred_wallaper")"
    done
}


do_blur () {
    for i in $(seq 5)
    do
        blurred_wallaper="$cache_dir/$filename""_""$i.$extension"
        eval "$wallpaper_command" "$blurred_wallaper"
    done
}

do_unblur () {
    for i in $(seq 5 -1 0)
    do
        blurred_wallaper="$cache_dir/$filename""_""$i.$extension"
        eval "$wallpaper_command" "$blurred_wallaper"
    done
}

# get random file in dir if passed argument is a dir
get_random() {
    dir="$1"
    if [ ! -d "$dir" ]; then
        i_option="$dir"
        return
    fi
    dir=("$dir"/*)
    dir="${dir[RANDOM % ${#dir[@]}]}"
    get_random "$dir"
}

kill_previous(){
    if [ -e "$pid_file" ]; then
        pid=$(<"$pid_file")
        if [ ! -z "$pid" ] && [ "$pid" != $$ ]; then
            kill -15 "$pid"
        fi
    fi
    touch "$pid_file"
}

clean_cache() {
    if [  "$(ls -A "$cache_dir")" ]; then
        err " * Cleaning existing cache"
        rm -r "${cache_dir:?}"
        mkdir -p "$cache_dir"
    fi
}

main() {
    # Create a cache directory if it doesn't exist
    if [ ! -d "$cache_dir" ]; then
        err "* Creating cache directory"
        mkdir -p "$cache_dir"
    else
        clean_cache
    fi

    blur_cache="$cache_dir/$filename""_"0."$extension"

    # Generate cached images if no cached images are found
    if [ ! -f "$blur_cache" ]
    then
        gen_blurred_seq
    fi

    prev_state="reset"

    while true
    do
        if [ -z "$DISPLAY" ]; then
            exit 1
        fi
        current_workspace="$(xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}')"
        num_windows="$(wmctrl -l | awk -F" " '{print $2}' | grep ^"$current_workspace")"

        # If there are active windows
        if [ -n "$num_windows" ]
        then
            if [ "$prev_state" != "blurred" ];then
                err " ! Blurring"
                do_blur
            fi
            prev_state="blurred"
        else #If there are no active windows
            if [ "$prev_state" != "unblurred" ];then
                err " ! Un-blurring"
                do_unblur
            fi
            prev_state="unblurred"
        fi
        sleep 0.32
    done
}
# </Functions>

# To get the current wallpaper
i_option=''
while getopts "o:i:" flag; do
    case "${flag}" in
        o)  silent=1
            kill_previous
            trap "" 1
            get_random "${OPTARG}";;
        i) get_random "${OPTARG}";;
        :) print_usage
            exit 1;;
        *) print_usage
            exit 1;;
    esac
done

# Prevent multiple instances
if pidof -x "$(basename "$0")" -o $$ >/dev/null; then
    err 'Another instance of wallblur is already running.'
    err 'Please kill it with (pkill wallblur.sh) first.'
    exit 1
fi

# Check to make sure an option is given
if [[ -z "$i_option" ]]; then
    printf "\nPlease specify a wallpaper\n\n"
    print_usage
    exit 1
fi

wallpaper="$i_option"
base_filename=${wallpaper##*/}
extension="${base_filename##*.}"
filename="${base_filename%.*}"

if [ ! -e "$wallpaper" ]; then
    echo "The image was not found, check that the name is correct, or that the path exists "
    exit 1
fi

err "$wallpaper"
err "$cache_dir"


if [ "$silent" == 0 ]; then
    main
else
    main > /dev/null &
    echo $! > "$pid_file"
fi
