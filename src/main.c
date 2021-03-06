#include <X11/Xlib.h>
#include <sys/time.h>
#include <unistd.h>
#include <signal.h>
#include <stdio.h>

#define FRAME_TIME_MICROSECONDS 25000

// external functions
extern void setup();
extern int checkEvent();
extern XEvent getEvent();
extern int isWmDeleteEvent(XEvent);
extern int getScore();
// event handlers
extern int update();
extern void handleKeyPress(uint keyCode);
extern void init();

void copyArea(int src_x, int src_y, int dst_x, int dst_y, int w, int h);

void gameLoop();
void waitForNextFrame();
void startMusic();
void *playMusic(void *);

pid_t music_pid;

int main()
{
    setup();
    startMusic();
    gameLoop();
    kill(music_pid, SIGTERM);
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
            running = update();
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

    // print final score
    printf("Final score: %d points\n", getScore());
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

// function starts playing game's music in a new thread
// input: none
// return: none
void startMusic()
{
    // create process
    music_pid = fork();
    if (music_pid == 0)
    {
        // play music
        char *args[] = {NULL};
        execv("./playMusic.sh", args);
    }
}
