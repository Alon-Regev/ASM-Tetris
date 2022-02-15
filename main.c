#include <X11/Xlib.h>

extern void setup();
extern int checkEvent();
extern XEvent getEvent();
void gameLoop();

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
    // handle events
    while(1)
    {
        if(checkEvent())
        {
            XEvent event = getEvent();
        }
    }
}
