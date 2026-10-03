# Buzzer (CMT-7525-80-SMT-TR) freqency response analysis

The buzzer used in the Badge V2 is inexpensive and small, and is considered a
buzzer, not a speaker. It has a significantly higher response to 2700Hz than at
other audible frequencies and I want to understand how it will perform beyond
simple square waves. Will it be able to handle smoother tones such as a sine
wav? Will users of the hardware be able to apply ADSR envelope techniques to add
depth to the audio component of their application?

The current API exposes a single function to generate a fixed tone for a fixed
duration, and I want to answer these questions before implementing firmware. Why
put in the work to expose new functionality in the API if it's going to sound
like crap?

I managed to created an Audacity Filter Curve EQ effect based off of
the frequency response curve found in the [datasheet](./CMT-7525-80-SMT-TR.pdf).
The resulting file is `CMT-7525-80-SMT-TR.txt`. Now 

I did this using [WebPlotDigitizer](https://apps.automeris.io/wpd4/) to trace
the freqency response graph to generate a table, then wrote
[convert.awk](./convert.awk) to convert the CSV into the Audacity format.

Take note that our freqency response for this speaker goes up to 10KHz, beyond
that it is unknown, and you might need to fiddle with the last data point to
test different conditions for attenuation of high frequency.

There will be other factors at play such as the direction of the speaker,
performance of the driving circuit. Right now I'm considering the use of an I2S
D-class amplifier that I've used in the past. All in all though it sounds
alright, and I think users will be able to make something of this buzzer, even
if it sounds mildly worse than the results of this experiment.
