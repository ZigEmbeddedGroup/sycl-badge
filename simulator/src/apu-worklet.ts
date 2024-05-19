"use strict";

class APUProcessor extends AudioWorkletProcessor {
    //  multiple of 512
    samplesLeft: number[] = []
    samplesRight: number[] = []

    constructor () {
        super();

        if (this.port != null) {
            this.port.onmessage = (event: MessageEvent<{left: number[], right: number[]}>) => {
                this.samplesLeft = this.samplesLeft.concat(event.data.left);
                this.samplesRight = this.samplesRight.concat(event.data.right);
            };
        }
    }

    /**
     * Web standards only support [2][128]f32 but hardware (and thus the wasm code) runs with [2][512]u16 (but I think it's signed in reality?)
     */
    process (_inputs: Float32Array[][], [[ outputLeft, outputRight ]]: Float32Array[][], _parameters: Record<string, Float32Array>): boolean {
        const pcmLeft = this.samplesLeft.splice(0, 128);
        const pcmRight = this.samplesRight.splice(0, 128);

        for (let index = 0; index < pcmLeft.length; index += 1) {
            pcmLeft[index] = pcmLeft[index] / 32767;
            pcmRight[index] = pcmRight[index] / 32767;
        }

        outputLeft.set(new Float32Array(pcmLeft));
        outputRight.set(new Float32Array(pcmRight));

        return true;
    }
}

registerProcessor("wasm4-apu", APUProcessor as unknown as AudioWorkletProcessorConstructor);
