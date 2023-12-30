# Generative and Interactive ChucK Instrument
# Description
This instrument, written in [ChucK](https://chuck.cs.princeton.edu/), is an arpeggiated synth with both a generative and interactive component. When its file is executed, an arpeggiated pattern is generated within the constraints specified by command line arguments. This is done with randomizing algorithms that affect note order and rhythm, so calling the file again with the same command line input will produce a different pattern. Once the pattern has been generated, the user can modify various parameters and effects by moving their mouse on the screen or pressing certain keys (inspired by code from the [S.M.E.L.T.](https://smelt.cs.princeton.edu/) toolkit). [Here](https://youtu.be/MYS8Z1cxozc) is a demonstration of the instrument, done in VS Code.
# Instructions
## COMMAND LINE ARGUMENTS - Enter When Executing File

    1. Filename
    2. BPM
    3. Notes (White Keys CDEFGAB: asdfghj, Black Keys C#D#F#G#A#: wetyu)
    4. Length of Pattern in Measures
    5. Number of Accents per Measure

    Command Line Example:
    chuck arp.ck:130:asegy:1:3

## INTERACTIVE PARAMETERS - Adjust While File is Running
note: click out of terminal to prevent pressed keys from showing up in terminal

MOVE MOUSE:

    Mouse X - Filter Cutoff
    Mouse Y - Filter Resonance

PRESS ONCE:

    Up Arrow - Increase Octave
    Down Arrow - Decrease Octave

    Right Arrow - Increase Octave Range
    Left Arrow - Decrease Octave Range

PRESS AND HOLD:

    1 - Increase Saw Mix
    2 - Decrease Saw Mix

    3 - Increase Square Mix
    4 - Decrease Square Mix

    5 - Increase Noise Mix
    6 - Decrease Noise Mix

    q - Increase Reverb
    a - Decrease Reverb

    w - Increase Delay Mix
    s - Decrease Delay Mix

    e - Increase Delay Feedback
    d - Decrease Delay Feedback

    r - Increase Detune Amount
    f - Decrease Detune Amount

    t - Increase Detune Blend
    g - Decrease Detune Blend

    y - Increase ADSR Decay Time
    h - Decrease ADSR Decay Time

    u - Increase Filter Envelope Amount
    j - Decrease Filter Envelope Amount

