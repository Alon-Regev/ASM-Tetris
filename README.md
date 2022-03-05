# ASM-Tetris
<img src="https://user-images.githubusercontent.com/71284855/156880870-4b1e18cf-0930-402e-86fb-47793cd0d533.png" align="right"/>

## About
This is a small (4 week) project, building a low-level tetris game. 
It's main goal was getting familiar and comfortable with writing assembly code, and learning about new concepts along the way.

## Links
- [Planning Document](https://docs.google.com/document/d/197SnN1NuWaHP_1JR7hvm7B-I_1kc-xScFedeBzi-VZM/edit?usp=sharing) (docs)
- [Video Presentation]() _TODO_

## How It Works
The code was written mostly with NASM (~1250 lines of code), and the rest with C (~250 lines). <br/>
It was written for linux OS, Using XLib for graphics and ALSA for music.

The first part of the project was the graphics interface, written with C. It used XLib to create a window and to draw on it, and it implements simple functions (drawRect, drawText...). It uses an event based system to run the game. <br/>
The second part was the game logic, written in assembly. It Used the previously implemented event system to work.


## Usage
The project can be compiled with `$ make`, which produces a single executable called `Tetris`. <br/>
You can also run it directly using `$ make run`.
