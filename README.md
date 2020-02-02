# wallblur

wallblur is a simple shell script that creates a faux blurred background effect for your linux desktop without needing a compositor.

![demo](demo.gif)

## Getting Started

### Dependencies

In order to use the script, you will need to make sure you have imagemagick, [hsetroot](https://github.com/himdel/hsetroot) (or any command line program that sets a wallpaper, such as [feh](https://github.com/derf/feh)) and wmctrl installed.

### Note

Make sure that you stop any existing application that is responsible for setting your wallpaper.

The script will automatically resize your wallpaper while maintaining aspect ratio so that it fits your display's resolution. Don't worry, it will not modify the original file.

## Running wallblur

### the manual way

You can run wallblur by running the following command:

```
path/to/wallblur.sh -i 'path/to/wallpaper.jpeg' &
```

If you are copying and pasting the script instead of downloading the script. Make sure you make it executable by using the following command:

```
chmod +x path/to/wallblur.sh
```

### automatically start wallblur on startup

If you would like to start wallblur on startup automatically, assuming you are on an X11 windowing system, add the following line to your **.xprofile** file:

```
path/to/wallblur.sh -i 'path/to/wallpaper.jpeg' &
```

Replacing ***path/to/*** with the actual path where the script is residing.

And if you are using **i3wm**, you can add this line to your config:

```
exec --no-startup-id sh -c "path/to/wallblur.sh &"
```
