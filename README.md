
![screenshot](https://jmclia.bn.files.1drv.com/y4mkN4wV2XNEeiGPqQoe6WoTuTN5egcyHQ1b-vxfZE_yuHYYo9gg4ef4v1_yiHR6Xul70_VbDrctVBiuhi-3Ld0cBhaZhWsiflhYrp78_d-lG0KN5wkGVCHVVRLMF2qtiYjjsTjRGsdv31wD7lyh8yql-yStV1Irc-xDywa7Yx_g-n-SeDilMF1iu-FBY2feTHN8KFumPg1uaBPJ-zJF4K4Rw/Video_1523264210.gif?psid=1)

# Godot CHIP-8 Emulator


[CHIP-8](https://en.wikipedia.org/wiki/CHIP-8) is an interpreted programming language, developed by Joseph Weisbecker. It was initially used on the COSMAC VIP and Telmac 1800 8-bit microcomputers in the mid-1970s. CHIP-8 programs are run on a CHIP-8 virtual machine. It was made to allow video games to be more easily programmed for said computers.

[Godot](https://godotengine.org) is a full featured, multi-platform, 2D and 3D open source game engine. It uses, among other languages, a scripting language called (GDScript)[http://docs.godotengine.org/en/3.0/getting_started/scripting/gdscript/gdscript_basics.html].

There is a CHIP-8 implementation for almost every platform, as well as some development tools. This is an attempt to see what is possible within the limits of GDScript and Godot (it is a port to GDScript of a CHIP-8 emulator written originally in Java; the original Java emulator was created by [Johan](https://github.com/Johnnei/) based on his [YouTube](https://www.youtube.com/playlist?list=PL5PyurErl12czoLyYD8za68d61T_OZsP2) tutorials).

## Download

Click download now to get access to the following files:

[![Linux](https://qilscg.bn.files.1drv.com/y4mh10zOBDKUBvq8yWVVWzTMcBcYhI4oJIc92YXf200CQo6joaaNHGgayws8T_Wcdcni1Rjn9lqTkwc-QQ16jX3gn7gHFBjiSSh0xBprH2vjqCxaJ0Lkxz6Of6XEIx3w1Act86NmJRhb03-d_OHHI85a-McgKBYNPsWTFTBRVMJPtEt5KjUnDDA7pfuiNBhAFa5V7SehivatQUKZe5rhaI-Kg/download-Linux.png?psid=1)](https://1drv.ms/u/s!Ao1E4OCcZiFLjoNWPbe1nCmfRbyhtw)

[![Windows](https://51jm5q.bn.files.1drv.com/y4m3P1qFAHU-3g7IcPTz33zQZveFlUgeFwNGjGPIAcjPnHqLrfqd1p47mNpm-5_EI4pO47JDFhpP-RrZVRFq5agUcYh2erBNl21raiAD7bMxyHPiA7IqovE520lUTssRn-GI-sngpM4yzHjYdZ62gRs-0Sg3STeGXoYMHFdOOhxlxhnPBeafGIi1hqbuVIyHBUtIDbspRBOO8jcbDvWO_LaAQ/download-WindowsZip.png?psid=1)](https://1drv.ms/u/s!Ao1E4OCcZiFLjoNVfqGpwV2QCK6m3A)

[![Mac](https://tn6pqg.bn.files.1drv.com/y4mMyij-w2xWQmsk967PXd9CH5Mbp6Jde0naNgqfpUAXq11ilMIsjbLS87i12CxTrbHzJHfoiQJX6m3DGlw_NoYCfGefhtwKuXQr0Rtx6E8Npbxe1AWUaqbSvuO0IY3hv9tXkWBhzgXpl5uxevAD83Sw3_jUpI9PSGgyBnHaDp6B3UjehgZvIXGsEPcRUS1CtIgb-IKIf-qAlo85DXMmTVW5Q/download-OSXZip.png?psid=1)](https://1drv.ms/u/s!Ao1E4OCcZiFLjoNXEcl_77pH0frnKA)


Older binaries for 2.x versions are still online:

* [Linux](https://1drv.ms/u/s!Ao1E4OCcZiFLjbMFKweFLqk-9yLpfQ): Linux binary
* [Windows](https://1drv.ms/u/s!Ao1E4OCcZiFLjbMGziMPz4i-YY2KSQ): Windows binary
* [Mac OSX](https://1drv.ms/u/s!Ao1E4OCcZiFLjbMEEnr2vz1lBNwGaQ): Mac OSX binary


## Controlling the games

The keyboard input is a 16-key keyboard with keys 0 − 9, A − F:

![input](https://tclpcg.bn.files.1drv.com/y4m-pfUs2mkwidxbnkTyerPFqFk8O42OMClHLNZ7DUyTm3igqvuI0_3RzTJAnafB0BcM1TX4O4mTAmrqZetSCxNAM-p5xBme7pZBijG9H1_4yJXqWkJR2Tj2rLKri0CWQBL8lHqKKXrES3mSqAIBj5xN3MeqsPTTPg-MmcvoDQKxoCxuRksT8FvsVn3Sw8sdKgvw8TPmABng2ZZw6GU9NPtAw/input.png?psid=1)

The '8', '4', '6', and '2' keys are typically used for directional input (for convenience, keyboard arrow keys are mapped too).

The current implementation maps these keys to its correspondents in the keyboard: 1-9 and A-F.


## Built With

* [Godot](https://godotengine.org/) - Godot is an advanced, feature-packed, multi-platform 2D and 3D open source game engine
* [CRT Shader](https://github.com/henriquelalves/SimpleGodotCRTShader) - A simple Godot shader that simulates CRT Displays
* [Java CHIP-8 Emulator](https://github.com/Johnnei/Youtube-Tutorials/tree/master/emulator_chip8) - Original CHIP-8 Emulator Java code developed by Johan 


## Authors

* **Johan** - *Original Java code* - [CHIP-8 Java](https://github.com/Johnnei/Youtube-Tutorials/tree/master/emulator_chip8)
* **Vitor Almeida da Silva** - *Port to Godot* - [Godot CHIP-8 Emulator](https://github.com/vitoralmeidasilva)


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
