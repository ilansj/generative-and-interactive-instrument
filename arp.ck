
//read in command line args
Std.atof(me.arg(0)) => float bpm;
me.arg(1) => string notes;
Std.atoi(me.arg(2)) => int arpLength;
Std.atoi(me.arg(3)) => int accents;

//set bpm
1/(bpm/60.0) * 4::second => dur bar;

//ascii to MIDI helper function
fun int itom(int a) {
    if (a == 97) {return 60;}
    if (a == 119) {return 61;}
    if (a == 115) {return 62;}
    if (a == 101) {return 63;}
    if (a == 100) {return 64;}
    if (a == 102) {return 65;}
    if (a == 116) {return 66;}
    if (a == 103) {return 67;}
    if (a == 121) {return 68;}
    if (a == 104) {return 69;}
    if (a == 117) {return 70;}
    if (a == 106) {return 71;}
    return 0;
}

class keyPressed {int value;}
//helper function that senses if a key is actively being pressed and held
fun void keyHelper(int key, keyPressed k) {
    0 => int deviceNum;
    Hid hi;
    HidMsg msg;
    if( !hi.openKeyboard(deviceNum)) me.exit();
    while (true) {
        hi => now;
        while(hi.recv(msg)) {
            if(msg.isButtonDown() && msg.which == key) {
                1 => k.value;
            } else {
                0 => k.value;
            }
        }
    }
}

class Mouse {float value;}
Mouse x;
Mouse y;
//helper function that returns the x and y value of the mouse
fun void updateMouse(Mouse x, Mouse y) {
    0 => int deviceNum;
    Hid hi;
    HidMsg msg;
    if (!hi.openMouse(deviceNum)) me.exit();
    while (true) {
        hi => now;
        while(hi.recv(msg)) {
            //divides by screen bounds to return a value between 0 and 1
            msg.cursorX/1511.0 => x.value;
            msg.cursorY/981.0 => y.value;
        }
    }
}

//increases a parameter when a key is held
fun void keyIncrease(int key, Parameter p, string name) {
    keyPressed k;
    spork ~keyHelper(key, k);
    while (true) {
        if (k.value == 1) {
            if (p.amt < 0.9995) {
                0.0005 +=> p.amt;
                // <<< p.amt >>>;
            } else {
                <<< name, "MAX" >>>;
                1::second => now; //message will only repeat if key is held for longer than a second
            }
        }
        1::ms => now;
    }
}

//decreases a parameter when a key is held
fun void keyDecrease(int key, Parameter p, string name) {
    keyPressed k;
    spork ~keyHelper(key, k);
    while (true) {
        if (k.value == 1) {
            if (p.amt > 0.0005) {
                0.0005 -=> p.amt;
                // <<< p.amt >>>;
            } else {
                <<< name, "MIN" >>>;
                1::second => now;
            }
        }
        1::ms => now;
    }
}

//increases a parameter when a key is pressed
fun void arrowIncrease(int key, Toggle t, int max, string name) {
    0 => int deviceNum;
    Hid hi;
    HidMsg msg;
    if( !hi.openKeyboard(deviceNum)) me.exit();
    while (true) {
        hi => now;
        while(hi.recv(msg)) {
            if(msg.isButtonDown() && msg.which == key && t.val < max) {
                t.val++;
                <<< name, t.val >>>;
            }
        }
    }
}

//increases a parameter when a key is pressed
fun void arrowDecrease(int key, Toggle t, int min, string name) {
    0 => int deviceNum;
    Hid hi;
    HidMsg msg;
    if( !hi.openKeyboard(deviceNum)) me.exit();
    while (true) {
        hi => now;
        while(hi.recv(msg)) {
            if(msg.isButtonDown() && msg.which == key && t.val > min) {
                t.val--;
                <<< name, t.val >>>;
            }
        }
    }
}

//creates classes for parameters, need to be classes in order to be pass by reference in ChucK
class Parameter{float amt;}
Parameter reverb;
0 => reverb.amt;
Parameter delayWet;
0 => delayWet.amt;
Parameter delayFeedback;
0 => delayFeedback.amt;
Parameter cutoff;
0.5 => cutoff.amt;
Parameter Q;
0 => Q.amt;
Parameter detune;
0 => detune.amt;
Parameter detuneBlend;
0 => detuneBlend.amt;
class Unison{float detune; float blend;}
Unison unison;
Parameter sawVol;
1 => sawVol.amt;
Parameter sqrVol;
1 => sqrVol.amt;
Parameter noiseVol;
0 => noiseVol.amt;
class WV{float saw; float sqr; float noise;}
WV waveVol;
Parameter ampDecay;
1 => ampDecay.amt;
class Toggle{int val;}
Toggle octaveShift;
0 => octaveShift.val;
Toggle octaveRange;
0 => octaveRange.val;
Parameter filterCutoff;
0 => filterCutoff.amt;
Parameter filterEnvelope;
0 => filterEnvelope.amt;

//signal flow
SawOsc saw => ADSR env => LPF f => Dyno comp => Echo d => NRev r => dac;

SawOsc sawDetune1 => env;
SawOsc sawDetune2 => env;

SqrOsc sqr => env;
SqrOsc sqrDetune1 => env;
SqrOsc sqrDetune2 => env;

Noise n => HPF noiseEQ => env;
3000 => noiseEQ.freq;

//sets envelope with decay at 0, since decay will be adjusted in updateParameters
env.set(1::ms, 0::ms, 0, 1::ms);

//uses step to create values for the filter envelope
Step step => ADSR fEnv => blackhole;
1 => step.next;
fEnv.set(1::ms, 0::ms, 0, 1::ms);

//limiter style compressor settings to prevent FX from drastically affecting arpeggiator volume
1::ms => comp.attackTime;
100::ms => comp.releaseTime;
0.08 => comp.thresh;
10 => comp.ratio;

//creates delay feedback
d => Gain feedback;
feedback => LPF delayEQ => d;

//updates parameters at sample rate, with coefficients determining the desired range of each parameter
fun void updateParameters() {
    while (true) {
        reverb.amt*0.3 => r.mix;
        delayWet.amt*0.99 => d.mix;
        delayFeedback.amt*0.9 => feedback.gain;
        bar/8  => d.delay;

        detune.amt*3 => unison.detune;
        detuneBlend.amt*0.5 => unison.blend;
        sawVol.amt*0.05 => waveVol.saw;
        sqrVol.amt*0.05 => waveVol.sqr;
        noiseVol.amt*0.05 => waveVol.noise;

        ampDecay.amt*((bar/16) - 40::ms) + 40::ms => env.decayTime;
        env.decayTime()*0.8 => fEnv.decayTime;

        //Mouse parameters
        Math.pow(x.value, 4)*10000 => filterCutoff.amt;
        (1 - y.value)*9 => f.Q;
        
        filterCutoff.amt*0.9 => delayEQ.freq;
        1::samp => now;
    }
}

//updates cutoff freq at sample rate once filter envelope is triggered
fun void updateFilter(LPF f, ADSR fEnv) {
  while (true) {
    (fEnv.last() * filterCutoff.amt) + ((1 - filterEnvelope.amt) * (1 - fEnv.last()) * filterCutoff.amt) + 150 => f.freq;
    1::samp => now;
   }
}

//put notes in an array
float nArr[notes.length()];
for (int i; i < notes.length(); i++) {
    (itom(notes.charAt(i))) => nArr[i];
}

//put gain values in an array
float rArr[16];
for (int i; i < accents; i++) {
    1 => rArr[i];
}
for (accents => int i; i < 16; i++) {
    Math.random2(0,2)*0.1 => rArr[i];
}

//set a repeating sequence based on randomized notes
//set a repeating rhythm with accents based by randomly arranging gain values
float seq[arpLength*16];
for (int i; i < arpLength*16; i++) {
   nArr[Math.random2(0, notes.length() - 1)] => seq[i];
}

float rhythm[16];
int rIndeces[16];
//set each index to 100 to prevent them from having the default value of 0
for (int i; i < rIndeces.cap(); i++) {100 => rIndeces[i];}
1 => int restart;
0 => int duplicatesFound;
int rRandom;

for (int i; i < 16; i++) {
    1 => restart;
    while (restart == 1) {
        0 => duplicatesFound;
        Math.random2(0, 15) => rRandom;
        for (int j; j < rIndeces.cap(); j++) {
            if (rIndeces[j] == rRandom) {
                1 => duplicatesFound;
            }
        }
        if (duplicatesFound == 0) {0 => restart;}
    }
    rRandom => rIndeces[i];
    rArr[rIndeces[i]] => rhythm[i];
}

//PLAY NOTES
fun void Main() {
    while (true) {
        for (int i; i < arpLength*16; i++) {
            Std.mtof(seq[i] + octaveShift.val*12 + Math.random2(0,octaveRange.val)*12) => float pitch;

            pitch => saw.freq;
            rhythm[i%16]*(1 - unison.blend)*waveVol.saw => saw.gain;
        
            pitch + unison.detune => sawDetune1.freq;
            rhythm[i%16]*unison.blend*waveVol.saw => sawDetune1.gain;
            pitch - unison.detune => sawDetune2.freq;
            rhythm[i%16]*unison.blend*waveVol.saw => sawDetune2.gain;
            
            pitch => sqr.freq;
            rhythm[i%16]*(1 - unison.blend)*waveVol.sqr => sqr.gain;

            pitch + unison.detune => sqrDetune1.freq;
            rhythm[i%16]*unison.blend*waveVol.sqr => sqrDetune1.gain;
            pitch - unison.detune => sqrDetune2.freq;
            rhythm[i%16]* unison.blend*waveVol.sqr => sqrDetune2.gain;

            rhythm[i%16]*waveVol.noise => n.gain;
            env.keyOn();
            fEnv.keyOn();
            bar/16.0 - 1::ms => now;
            env.keyOff();
            fEnv.keyOff();
            1::ms => now;
        }
    }
}

spork ~updateFilter(f, fEnv);
spork ~updateParameters();
spork ~updateMouse(x, y);

spork ~keyIncrease(30, sawVol, "Saw Volume");
spork ~keyDecrease(31, sawVol, "Saw Volume");

spork ~keyIncrease(32, sqrVol, "Square Volume");
spork ~keyDecrease(33, sqrVol, "Square Volume");

spork ~keyIncrease(34, noiseVol, "Noise Volume");
spork ~keyDecrease(35, noiseVol, "Noise Volume");

spork ~keyIncrease(20, reverb, "Reverb Mix");
spork ~keyDecrease(4, reverb, "Reverb Mix");

spork ~keyIncrease(26, delayWet, "Delay Mix");
spork ~keyDecrease(22, delayWet, "Delay Mix");

spork ~keyIncrease(8, delayFeedback, "Delay Feedback");
spork ~keyDecrease(7, delayFeedback, "Delay Feedback");

spork ~keyIncrease(21, detune, "Detune Amount");
spork ~keyDecrease(9, detune, "Detune Amount");

spork ~keyIncrease(23, detuneBlend, "Detune Blend");
spork ~keyDecrease(10, detuneBlend, "Detune Blend");

spork ~keyIncrease(28, ampDecay, "Decay Length");
spork ~keyDecrease(11, ampDecay, "Decay Length");

spork ~keyIncrease(24, filterEnvelope, "Filter Envelope");
spork ~keyDecrease(13, filterEnvelope, "Filter Envelope");

spork ~arrowIncrease(82, octaveShift, 3, "Octave");
spork ~arrowDecrease(81, octaveShift, -3, "Octave");

spork ~arrowIncrease(79, octaveRange, 3, "Octave Range");
spork ~arrowDecrease(80, octaveRange, 0, "Octave Range");

Main();