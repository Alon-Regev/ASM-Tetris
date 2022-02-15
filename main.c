#include <X11/Xlib.h>
#include <sys/time.h>

extern void drawSquare(int x, int y, const char *rgb);

#define FRAME_TIME_MICROSECONDS 25000

extern void setup();
extern int checkEvent();
extern XEvent getEvent();
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
        //printf("hi");
        if (checkEvent())
        {
            XEvent event = getEvent();
        }
        else
        {
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
