#!/bin/bash

# kill music player
end_program () {
    kill $(jobs -p)
    exit
}

# handle terminate signal
trap end_program TERM

# play until terminated
while [ true ]; do
    paplay Tetris.wav &
    wait
done
