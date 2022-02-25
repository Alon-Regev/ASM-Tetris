#include <X11/Xlib.h>
#include <sys/time.h>
#include <unistd.h>

#define FRAME_TIME_MICROSECONDS 25000

// external functions
extern void setup();
extern int checkEvent();
extern XEvent getEvent();
extern int isWmDeleteEvent(XEvent);
// event handlers
extern void update();
extern void handleKeyPress(uint keyCode);
extern void init();

void gameLoop();
void waitForNextFrame();

int main()
{
    setup();
    gameLoop();
    return 0;
}

// function manages the game loop
// input: none
// return: none
void gameLoop()
{
    XEvent event;
    int running = 1;

    // call initialize event
    init();

    // handle events until window closed
    while (running)
    {
        // if not events wait until next frame
        if (!checkEvent())
        {
            update();
            waitForNextFrame();
            continue;
        }

        // handle events
        event = getEvent();
        // handle events
        switch (event.type)
        {
        // key press event
        case KeyPress:
            handleKeyPress(event.xkey.keycode);
            break;
        // check window close event
        case ClientMessage:
            if (isWmDeleteEvent(event))
            { // end game loop
                running = 0;
            }
            break;
        // other
        default:
            break;
        }
    }
}

// function waits until next frame
// input: none
// return: none
void waitForNextFrame()
{
    struct timeval time = {0};
    gettimeofday(&time, NULL);
    uint timeSinceLastFrame = time.tv_usec % FRAME_TIME_MICROSECONDS;
    usleep(FRAME_TIME_MICROSECONDS - timeSinceLastFrame);
}
