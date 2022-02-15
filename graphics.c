#include <X11/Xlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define WINDOW_WIDTH 300
#define WINDOW_HEIGHT 450

// graphics globals
Atom wmDeleteMessage;
Display *display;
Window window;
int screen;

// method sets up the graphics and creates the window
// input: none
// return: none
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
    XSelectInput(display, window, ExposureMask | KeyPressMask);
    XMapWindow(display, window);

    // prepare for window being closed
    wmDeleteMessage = XInternAtom(display, "WM_DELETE_WINDOW", False);
    XSetWMProtocols(display, window, &wmDeleteMessage, 1);
}

// method checks if there's a pending event
// input: none
// return: true if there's a pending event, false otherwise
int checkEvent()
{
    return XPending(display) > 0;
}

// method gets the next event
// input: none
// return: the next event
XEvent getEvent()
{
    XEvent event;
    XNextEvent(display, &event);
    return event;
}

// method checks if an event is a wm delete event
// input: event - the event to check
// return: true if the event is a wm delete event, false otherwise
int isWmDeleteEvent(XEvent event)
{
    return event.type == ClientMessage &&
           event.xclient.data.l[0] == wmDeleteMessage;
}