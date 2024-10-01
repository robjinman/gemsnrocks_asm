Gems'n'Rocks
============

Build
-----

### Prerequisites

You need to have git-lfs installed to get the game's data files. If you installed git-lfs after cloning the repo, make sure to do a `git lfs pull`. The game will crash if the data files aren't present.

Download and build nasm from source and place on your PATH or install globally. I use nasm version 2.16.03. There is
a bug in 2.15 that makes debugging difficult.

### Compile

```
    ./build.sh
```

Run the application
-------------------

The app needs permission to write to /dev/fb0. Add your user to the video group.

```
    sudo adduser $USER video
```

Before running the app, switch to TTY mode with ctrl + alt + f1. You can switch between TTYs with alt + arrow keys.

Run the application from the project directory.

```
    ./build/gems
```

The app works best on a screen resolution of 1920x1080.