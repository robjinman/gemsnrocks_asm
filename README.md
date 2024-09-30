Gems'n'Rocks
============

Build
-----

### Prerequisites

Download and build nasm from source and place on your PATH. I use nasm version 2.16.03. There is
a bug in 2.15 that makes debugging difficult.

Remember to `git lfs pull` when checking out the repo.

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

Log in, navigate to the project directory, and run the application

```
    ./build/gems
```

The app is tested on a screen resolution of 1920x1080. It may not work so well on other resolutions.
