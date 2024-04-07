import * as constants from "./constants";
import { Runtime } from "./runtime";

export class State {
    memory: ArrayBuffer;
    flashBuffer: ArrayBuffer;

    // TODO(2022-03-17): APU state

    constructor () {
        this.memory = new ArrayBuffer(1 << 16);
        this.flashBuffer = new ArrayBuffer(constants.FLASH_PAGE_SIZE * constants.FLASH_PAGE_COUNT);
    }

    read (runtime: Runtime) {
        new Uint8Array(this.memory).set(new Uint8Array(runtime.memory.buffer));

        new Uint8Array(this.flashBuffer).set(new Uint8Array(runtime.flashBuffer, 0));
    }

    write (runtime: Runtime) {
        new Uint8Array(runtime.memory.buffer).set(new Uint8Array(this.memory));

        new Uint8Array(runtime.flashBuffer).set(new Uint8Array(this.flashBuffer, 0));
    }
}
