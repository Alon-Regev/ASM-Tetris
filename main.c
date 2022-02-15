#include <X11/Xlib.h>
#include <sys/time.h>
#include <unistd.h>

extern void drawSquare(int x, int y, const char *rgb);

#define FRAME_TIME_MICROSECONDS 25000

// external functions
extern void setup();
extern int checkEvent();
extern XEvent getEvent();
// event handlers
extern void update();
extern void handleKeyPress(uint keyCode);

void gameLoop();
void waitForNextFrame();

int main()
{
    setup();
    gameLoop();
    return 0;
}

// method manages the game loop
// input: none
// return: none
void gameLoop()
{
    int frame = 0;
    // handle events
    while(1)
    {
        if (checkEvent())
        {
            XEvent event = getEvent();
            // handle events
            switch (event.type)
            {
                case KeyPress:
                    handleKeyPress(event.xkey.keycode);
                    break;
                default:
                    break;
            }
        }
        else
        {
            update();
            waitForNextFrame();
        }
    }
}

// method waits until next frame
// input: none
// return: none
void waitForNextFrame()
{
    struct timeval time = {0};
    gettimeofday(&time, NULL);
    uint timeSinceLastFrame = time.tv_usec % FRAME_TIME_MICROSECONDS;
    usleep(FRAME_TIME_MICROSECONDS - timeSinceLastFrame);
}
