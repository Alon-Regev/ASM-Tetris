#include <X11/Xlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define WINDOW_WIDTH 300
#define WINDOW_HEIGHT 450

// graphics globals
Display *display;
Window window;
int screen;

// method sets up the graphics and creates the window
void setup()
{
    // connect to X server
    display = XOpenDisplay(NULL);
    if (display == NULL)
    {
        printf("Error: could not open display\n");
        exit(1);
    }

    // get screen number
    screen = DefaultScreen(display);

    // create window
    window = XCreateSimpleWindow(display, RootWindow(display, screen), 0, 0,
                                 WINDOW_WIDTH, WINDOW_HEIGHT, 0,
                                 BlackPixel(display, screen),   // border
                                 BlackPixel(display, screen));  // background

    // set window title
    XStoreName(display, window, "Tetris");

    // set window to be displayed on screen
    XMapWindow(display, window);
}
