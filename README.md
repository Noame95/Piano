# Piano 🎹
A piano I made in ASMx86 back in 2023. I wrote the code in NP++ and ran it on TASM. It's using an external asm file used for presenting BMP photos in graphic modes.
The project requires TASM, TLINK and DOSBox.
It's using PIT to generate sound, BMP files as pictures for situational events for the piano (Only one key can be pressed at a time) and notes can also play while the buttons are being held.


White keys: `1 2 3 4 5 6 7 8 9 0`
Black keys: `W E R T Y U I`
Quit: `Q`

Compile:
tasm piano.asm
tlink piano.obj
piano.exe

For easier compilation I made a build.bat

- The piano is called a secret piano because I once wanted to add it to another project when pressing a single button. I moved on from this idea and made a regular piano like that.
- In case there's a problem importing the assets, put all of the bmp files in the same directory as piano.asm and photo.asm then remove the assets folder.
