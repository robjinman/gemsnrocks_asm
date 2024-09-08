cleanbmp
========

Converts bmp file into a bmp that is compatible with gemsnrocks_asm.

gemsnrocks_asm assumes that the pixel data immediately follows the 54 byte header and is compacted,
with no padding at the end of each row. It also assumes the image is stored top-down, rather than
bottom-up, i.e. the first row of pixels in the file should correspond to the top of the image.

This program loads the bitmap, flips it vertically, and re-saves it.

The input image should have 4 bytes per pixel.

Build and run
-------------

```
    mkdir -p build && cd -
    cmake -G "Unix Makefiles" ..
    make -j8
```

Run from the build directory

```
    ./cleanbmp ./input.bmp ./output.bmp
```
