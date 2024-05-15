import * as constants from "./constants";
import * as z85 from "./z85";
import { APU } from "./apu";
import { Framebuffer } from "./framebuffer";
import { WebGLCompositor } from "./compositor";
import { pack565, unpack565 } from "./ui/utils";

const PIXELS_PER_MILLISECOND = 512; // about 25 FPS for full screen refreshes.

export class Runtime {
    canvas: HTMLCanvasElement;
    memory: WebAssembly.Memory;
    apu: APU;
    compositor: WebGLCompositor;
    data: DataView;
    framebuffer: Framebuffer;
    pauseState: number;
    wasmBuffer: Uint8Array | null = null;
    wasmBufferByteLen: number;
    wasm: WebAssembly.Instance | null = null;
    warnedFileSize = false;

    flashBuffer: ArrayBuffer;

    constructor () {
        const canvas = document.createElement("canvas");
        canvas.width = constants.WIDTH;
        canvas.height = constants.HEIGHT;
        this.canvas = canvas;

        const gl = canvas.getContext("webgl2", {
            alpha: false,
            depth: false,
            antialias: false,
        });

        if(!gl) {
            throw new Error('web-runtime: could not create wegl context')  // TODO(2021-08-01): Fallback to Canvas2DCompositor
        }

        this.compositor = new WebGLCompositor(gl);
        
        this.apu = new APU();

        this.flashBuffer = new ArrayBuffer(constants.FLASH_PAGE_SIZE);

        this.memory = new WebAssembly.Memory({initial: 64, maximum: 64});
        this.data = new DataView(this.memory.buffer);

        this.framebuffer = new Framebuffer(this.memory.buffer);

        this.reset();

        this.pauseState = constants.PAUSE_REBOOTING;
        this.wasmBufferByteLen = 0;
    }

    async init () {
        await this.apu.init();
    }

    setControls (controls: number) {
        this.data.setUint16(constants.ADDR_CONTROLS, controls, true);
    }
    
    setLightLevel (value: number) {
        this.data.setUint16(constants.ADDR_LIGHT_LEVEL, value, true);
    }

    getNeopixels (): [number, number, number, number, number] {
        const mem32 = new Uint32Array(this.data.buffer, constants.ADDR_NEOPIXELS);
        return [
            mem32[0] & 0b1111_1111_1111_1111_1111_1111,
            mem32[1] & 0b1111_1111_1111_1111_1111_1111,
            mem32[2] & 0b1111_1111_1111_1111_1111_1111,
            mem32[3] & 0b1111_1111_1111_1111_1111_1111,
            mem32[4] & 0b1111_1111_1111_1111_1111_1111
        ];
    }

    getRedLed(): boolean {
        return this.data.getUint8(constants.ADDR_RED_LED) !== 0;
    }

    unlockAudio () {
        this.apu.unlockAudio();
    }

    pauseAudio() {
        this.apu.pauseAudio();
    }

    reset (zeroMemory?: boolean) {
        // Initialize default color table and palette
        const mem32 = new Uint32Array(this.memory.buffer);
        if (zeroMemory) {
            mem32.fill(0);
        }
        this.pauseState &= ~constants.PAUSE_CRASHED;
    }

    async load (wasmBuffer: Uint8Array, enforceSizeLimit = true) {
        const limit = 1 << 16;
        this.wasmBuffer = wasmBuffer;
        this.wasmBufferByteLen = wasmBuffer.byteLength;
        this.wasm = null;

        if (wasmBuffer.byteLength > limit) {
            if (!this.warnedFileSize) {
                this.warnedFileSize = true;
                this.print(`Warning: Cart is larger than ${limit} bytes. Ensure the release build of your cart is small enough to be bundled.`);
            }
        }

        const env = {
            memory: this.memory,

            rect: this.framebuffer.drawRect.bind(this.framebuffer),
            oval: this.framebuffer.drawOval.bind(this.framebuffer),
            line: this.framebuffer.drawLine.bind(this.framebuffer),

            hline: this.framebuffer.drawHLine.bind(this.framebuffer),
            vline: this.framebuffer.drawVLine.bind(this.framebuffer),

            text: this.text.bind(this),

            blit: this.blit.bind(this),

            tone: this.apu.tone.bind(this.apu),

            read_flash: this.read_flash.bind(this),
            write_flash_page: this.write_flash_page.bind(this),

            trace: this.trace.bind(this),
        };

        await this.bluescreenOnError(async () => {
            const module = await WebAssembly.instantiate(wasmBuffer, { env });
            this.wasm = module.instance;

            // Call the WASI _start/_initialize function (different from WASM-4's start callback!)
            if (typeof this.wasm.exports["_start"] === 'function') {
                this.wasm.exports._start();
            }
            if (typeof this.wasm.exports["_initialize"] === 'function') {
                this.wasm.exports._initialize();
            }
        });
    }

    async bluescreenOnError (fn: Function) {
        try {
            await fn();
        } catch (err) {
            if (err instanceof Error) {
                const errorExplanation = errorToBlueScreenText(err);
                this.blueScreen(errorExplanation);
            }

            throw err;
        }
    }

    text (textColor: number, backgroundColor: number, textPtr: number, byteLength: number, x: number, y: number) {
        const text = new Uint8Array(this.memory.buffer, textPtr, byteLength);
        this.framebuffer.drawText(textColor, backgroundColor, text, x, y);
    }

    blit (spritePtr: number, x: number, y: number, width: number, height: number, srcX: number, srcY: number, stride: number, flags: number) {
        const sprite = new Uint16Array(this.memory.buffer, spritePtr);
        const flipX = (flags & 1);
        const flipY = (flags & 2);
        const rotate = (flags & 4);

        this.framebuffer.blit(sprite, x, y, width, height, srcX, srcY, stride, flipX, flipY, rotate);
    }

    read_flash (offset: number, dstPtr: number, length: number): number {
        const src = new Uint8Array(this.flashBuffer, offset, length);
        const dst = new Uint8Array(this.memory.buffer, dstPtr, length);

        dst.set(src);

        return src.length;
    }

    write_flash_page (page: number, srcPtr: number) {
        // TODO: Make dangerous write crash!!

        const src = new Uint8Array(this.memory.buffer, srcPtr, constants.FLASH_PAGE_SIZE);
        const dst = new Uint8Array(this.flashBuffer, page * constants.FLASH_PAGE_SIZE, constants.FLASH_PAGE_SIZE);

        dst.set(src);
    }

    getCString (ptr: number) {
        let str = "";
        for (;;) {
            const c = this.data.getUint8(ptr++);
            if (c == 0) {
                break;
            }
            str += String.fromCharCode(c);
        }
        return str;
    }

    print (str: string) {
        console.log(str);
    }

    trace (strUtf8Ptr: number, byteLength: number) {
        const strUtf8 = new Uint8Array(this.memory.buffer, strUtf8Ptr, byteLength);
        const str = new TextDecoder().decode(strUtf8);
        this.print(str);
    }

    start () {
        let start_function = this.wasm!.exports["start"];
        if (typeof start_function === "function") {
            this.bluescreenOnError(start_function);
        }
    }

    update () {
        if (this.pauseState != 0) {
            return;
        }

        let update_function = this.wasm!.exports["update"];
        if (typeof update_function === "function") {
            this.bluescreenOnError(update_function);
        }
        this.apu.tick();
    }

    blueScreen (text: string) {
        this.pauseState |= constants.PAUSE_CRASHED;

        const blue = pack565(5, 10, 5);
        const grey = pack565(25, 50, 25);

        const toCharArr = (s: string) => [...s].map(x => x.charCodeAt(0));

        const title = ` ${constants.CRASH_TITLE} `;
        const headerTitle = title;
        const headerWidth = (8 * title.length);
        const headerX = (160 - (8 * title.length)) / 2;
        const headerY = 20;
        const messageX = 9;
        const messageY = 52;

        this.framebuffer.fillScreen(blue);
        
        this.framebuffer.drawHLine(grey, headerX, headerY-1, headerWidth);
        this.framebuffer.drawText(blue, grey, toCharArr(headerTitle), headerX, headerY);
        this.framebuffer.drawText(grey, blue, toCharArr(text), messageX, messageY);

        this.composite();
    }

    composite () {
        const changedPixels = this.compositor.composite(this.framebuffer);
        const screenUpdateTimeMs = changedPixels / PIXELS_PER_MILLISECOND;
        return screenUpdateTimeMs;
    }
}

function errorToBlueScreenText(err: Error) {
    // hand written messages for specific errors
    console.log(err);
    if (err instanceof WebAssembly.RuntimeError) {
        let message;
        if (err.message.match(/unreachable/)) {
            message = "The cartridge has\nreached a code \nsegment marked as\nunreachable.";
        } else if (err.message.match(/out of bounds/)) {
            message = "The cartridge has\nattempted a memory\naccess that is\nout of bounds.";
        }
        return message + "\n\n\n\nHit R to reboot.";
    } else if (err instanceof WebAssembly.LinkError) {
        return "The cartridge has\ntried to import\na missing function.\n\n\nSee console for\nmore details.";
    } else if (err instanceof WebAssembly.CompileError) {
        return "The cartridge is\ncorrupted.\n\n\nSee console for\nmore details.";
    } else if (err instanceof Wasm4Error) {
        return err.wasm4Message;
    }
    return "Unknown error.\n\n\nSee console for\nmore details.";
}

class Wasm4Error extends Error {
    wasm4Message: string;
    constructor(w4Message: string) {
        super(w4Message.replace('\n', ' '));
        this.name = "Wasm4Error";
        this.wasm4Message = w4Message;
    }
}
