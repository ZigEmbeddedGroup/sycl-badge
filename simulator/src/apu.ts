// Created using `npm run build:apu-worklet` and
// is automatically generated in build and start scripts.
import worklet from "worklet:./apu-worklet";

export class APU {
    audioCtx: AudioContext
    processorPort?: MessagePort
    
    constructor() {
        this.audioCtx = new (window.AudioContext || window.webkitAudioContext)({
            sampleRate: 44100, // must match SAMPLE_RATE in worklet
        });
    }

    async init() {
        const audioCtx = this.audioCtx;
        await audioCtx.audioWorklet.addModule(worklet);

        const workletNode = new AudioWorkletNode(audioCtx, "wasm4-apu", {
            outputChannelCount: [2],
        });
        this.processorPort = workletNode.port;
        workletNode.connect(audioCtx.destination);
    }

    tick() {
        this.processorPort!.postMessage("tick");
    }

    tone(frequency: number, duration: number, volume: number, flags: number) {
        this.processorPort!.postMessage([frequency, duration, volume, flags]);
    }

    unlockAudio() {
        const audioCtx = this.audioCtx;
        if (audioCtx.state == "suspended") {
            audioCtx.resume();
        }
    }

    pauseAudio() {
        const audioCtx = this.audioCtx;
        if (audioCtx.state == "running") {
            audioCtx.suspend();
        }
    }
}
