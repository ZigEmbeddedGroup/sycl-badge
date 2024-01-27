import { LitElement, html, css } from "lit";
import { customElement, state, query } from 'lit/decorators.js';

import * as constants from "../constants";
import * as utils from "./utils";
import * as z85 from "../z85";
import { Runtime } from "../runtime";
import { State } from "../state";

import { MenuOverlay } from "./menu-overlay";
import { Notifications } from "./notifications";
import { HardwareComponents } from "./hardware-components";

@customElement("wasm4-app")
export class App extends LitElement {
    static styles = css`
        :host {
            width: 100%;
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;

            touch-action: none;
            user-select: none;
            -webkit-user-select: none;
            -webkit-tap-highlight-color: transparent;

            background: #202020;
        }

        .content {
            width: 100vmin;
            height: 100vmin;
            overflow: hidden;
        }

        /** Nudge the game upwards a bit in portrait to make space for the virtual gamepad. */
        @media (pointer: coarse) and (max-aspect-ratio: 2/3) {
            .content {
                position: absolute;
                top: calc((100% - 220px - 100vmin)/2)
            }
        }

        .canvas-wrapper {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 100%;
            height: 100%;
        }

        canvas {
            width: 100%;
            height: auto;
            image-rendering: pixelated;
            image-rendering: crisp-edges;
        }
    `;

    private readonly runtime: Runtime;

    @state() private showMenu = false;

    @query("wasm4-menu-overlay") private menuOverlay?: MenuOverlay;
    @query("wasm4-notifications") private notifications!: Notifications;
    @query("wasm4-hardware-components") private hardwareComponents!: HardwareComponents;

    private savedGameState?: State;

    public controls: number = 0;
    public lightLevel: number = 0;

    private readonly gamepadUnavailableWarned = new Set<string>();

    private readonly diskPrefix: string;

    readonly onPointerUp = (event: PointerEvent) => {
        if (event.pointerType == "touch") {
            // Try to go fullscreen on mobile
            utils.requestFullscreen();
        }

        // Try to begin playing audio
        this.runtime.unlockAudio();
    }

    constructor () {
        super();

        // this.diskPrefix = document.getElementById("wasm4-disk-prefix")?.textContent ?? utils.getUrlParam("disk-prefix") as string;
        this.diskPrefix = "disk";
        this.runtime = new Runtime(`${this.diskPrefix}-disk`);

        this.init();
    }

    async init () {
        const runtime = this.runtime;
        await runtime.init();

        const canvas = runtime.canvas;

        runtime.blueScreen("TODO improve devex\nload cart in menu");        

        // await runtime.load(await loadCartWasm());

        // runtime.start();
        
        // if (import.meta.env.DEV) {
        //     devkit.websocket?.addEventListener("message", async event => {
        //         switch (event.data) {
        //         case "reload":
        //             this.resetCart(await loadCartWasm());
        //             break;
        //         case "hotswap":
        //             this.resetCart(await loadCartWasm(), true);
        //             break;
        //         }
        //     });
        // }

        function takeScreenshot () {
            // We need to render a frame first
            runtime.composite();

            canvas.toBlob(blob => {
                const url = URL.createObjectURL(blob!);
                const anchor = document.createElement("a");
                anchor.href = url;
                anchor.download = "wasm4-screenshot.png";
                anchor.click();
                URL.revokeObjectURL(url);
            });
        }

        let videoRecorder: MediaRecorder | null = null;
        function recordVideo () {
            if (videoRecorder != null) {
                return; // Still recording, ignore
            }

            const mimeType = "video/webm";
            const videoStream = canvas.captureStream();
            videoRecorder = new MediaRecorder(videoStream, {
                mimeType,
                videoBitsPerSecond: 25000000,
            });

            const chunks: Blob[] = [];
            videoRecorder.ondataavailable = event => {
                chunks.push(event.data);
            };

            videoRecorder.onstop = () => {
                const blob = new Blob(chunks, { type: mimeType });
                const url = URL.createObjectURL(blob);
                const anchor = document.createElement("a");
                anchor.href = url;
                anchor.download = "wasm4-animation.webm";
                anchor.click();
                URL.revokeObjectURL(url);
            };

            videoRecorder.start();
            setTimeout(() => {
                if(videoRecorder) {
                    videoRecorder.requestData();
                    videoRecorder.stop();
                    videoRecorder = null;
                }
            }, 4000);
        }

        canvas.addEventListener("contextmenu", event => {
            event.preventDefault();
        });

        const HOTKEYS: Record<string, (...args:any[]) => any> = {
            "2": this.saveGameState.bind(this),
            "4": this.loadGameState.bind(this),
            "r": this.resetCart.bind(this),
            "R": this.resetCart.bind(this),
            "F9": takeScreenshot,
            "F10": recordVideo,
            "F11": utils.requestFullscreen,
            "Escape": this.onMenuButtonPressed.bind(this),
        };

        const onKeyboardEvent = (event: KeyboardEvent) => {
            if (event.ctrlKey || event.altKey) {
                return; // Ignore ctrl/alt modified key presses because they may be the user trying to navigate
            }

            if (event.srcElement instanceof HTMLElement && event.srcElement.tagName == "INPUT") {
                return; // Ignore if we have an input element focused
            }

            const down = (event.type == "keydown");

            // Poke WebAudio
            runtime.unlockAudio();

            if (down) {
                const hotkeyFn = HOTKEYS[event.key];
                if (hotkeyFn) {
                    hotkeyFn();
                    event.preventDefault();
                    return;
                }
            }

            let mask = 0;
            switch (event.code) {
            case "Space":
                mask |= constants.CONTROLS_START;
                break;
            case "Enter":
                mask |= constants.CONTROLS_SELECT;
                break;
            case "ShiftLeft": case "ShiftRight":
                mask |= constants.CONTROLS_CLICK;
                break;
            case "ArrowUp": case "KeyW":
                mask |= constants.CONTROLS_UP;
                break;
            case "ArrowDown": case "KeyS":
                mask |= constants.CONTROLS_DOWN;
                break;
            case "ArrowLeft": case "KeyA":
                mask |= constants.CONTROLS_LEFT;
                break;
            case "ArrowRight": case "KeyD":
                mask |= constants.CONTROLS_RIGHT;
                break;
            }

            if (mask != 0) {
                event.preventDefault();

                // Set or clear the button bit from the next input state
                if (down) {
                    this.controls |= mask;
                } else {
                    this.controls &= ~mask;
                }
            }
        };
        window.addEventListener("keydown", onKeyboardEvent);
        window.addEventListener("keyup", onKeyboardEvent);

        // Also listen to the top frame when we're embedded in an iframe
        if (top && top != window) {
            try {
                top.addEventListener("keydown", onKeyboardEvent);
                top.addEventListener("keyup", onKeyboardEvent);
            } catch {
                // Ignore iframe security errors
            }
        }

        const pollPhysicalGamepads = () => {
            // TODO
            // if (!navigator.getGamepads) {
            //     return; // Browser doesn't support gamepads
            // }

            // for (const gamepad of navigator.getGamepads()) {
            //     if (gamepad == null) {
            //         continue; // Disconnected gamepad
            //     } else if (gamepad.mapping != "standard") {
            //         // The gamepad is available, but nonstandard, so we don't actually know how to read it.
            //         // Let's warn once, and not use this gamepad afterwards.
            //         if (!this.gamepadUnavailableWarned.has(gamepad.id)) {
            //             this.gamepadUnavailableWarned.add(gamepad.id);
            //             this.notifications.show("Unsupported gamepad: " + gamepad.id);
            //         }
            //         continue;
            //     }

            //     // https://www.w3.org/TR/gamepad/#remapping
            //     const buttons = gamepad.buttons;
            //     const axes = gamepad.axes;

            //     let mask = 0;
            //     if (buttons[12].pressed || axes[1] < -0.5) {
            //         mask |= constants.BUTTON_UP;
            //     }
            //     if (buttons[13].pressed || axes[1] > 0.5) {
            //         mask |= constants.BUTTON_DOWN;
            //     }
            //     if (buttons[14].pressed || axes[0] < -0.5) {
            //         mask |= constants.BUTTON_LEFT;
            //     }
            //     if (buttons[15].pressed || axes[0] > 0.5) {
            //         mask |= constants.BUTTON_RIGHT;
            //     }
            //     if (buttons[0].pressed || buttons[3].pressed || buttons[5].pressed || buttons[7].pressed) {
            //         mask |= constants.BUTTON_X;
            //     }
            //     if (buttons[1].pressed || buttons[2].pressed || buttons[4].pressed || buttons[6].pressed) {
            //         mask |= constants.BUTTON_Z;
            //     }

            //     if (buttons[9].pressed) {
            //         this.showMenu = true;
            //     }

            //     this.inputState.gamepad[gamepad.index % 4] = mask;
            // }
        }

        // When we should perform the next update
        let timeNextUpdate = performance.now();
        // Track the timestamp of the last frame
        let lastTimeFrameStart = timeNextUpdate;

        const onFrame = (timeFrameStart: number) => {
            requestAnimationFrame(onFrame);

            pollPhysicalGamepads();

            if (this.menuOverlay != null) {
                this.menuOverlay.applyInput();

                return; // Pause updates and rendering
            }

            let calledUpdate = false;

            // Prevent timeFrameStart from getting too far ahead and death spiralling
            if (timeFrameStart - timeNextUpdate >= 200) {
                timeNextUpdate = timeFrameStart;
            }

            while (timeFrameStart >= timeNextUpdate) {
                timeNextUpdate += 1000/60;

                // Pass inputs into runtime memory
                runtime.setControls(this.controls);
                runtime.setLightLevel(this.lightLevel);
                runtime.update();
                calledUpdate = true;

                this.hardwareComponents.neopixels = runtime.getNeopixels();
                this.hardwareComponents.redLed = runtime.getRedLed();
            }

            if (calledUpdate) {
                runtime.composite();

                // if (import.meta.env.DEV) {
                //     // FIXED(2023-12-13): Pass the correct FPS for display                    
                //     devtoolsManager.updateCompleted(runtime, timeFrameStart - lastTimeFrameStart);
                //     lastTimeFrameStart = timeFrameStart;
                // }
            }
        }
        requestAnimationFrame(onFrame);
    }

    onMenuButtonPressed () {
        if (this.showMenu) {
            // If the pause menu is already open, treat it as an X button
            this.controls |= constants.CONTROLS_SELECT;
        } else {
            this.showMenu = true;
        }
    }

    closeMenu () {
        if (this.showMenu) {
            this.showMenu = false;
            this.controls = 0;
        }
    }

    saveGameState () {
        let state = this.savedGameState;
        if (state == null) {
            state = this.savedGameState = new State();
        }
        state.read(this.runtime);

        this.notifications.show("State saved");
    }

    loadGameState () {
        const state = this.savedGameState;
        if (state != null) {
            state.write(this.runtime);
            this.notifications.show("State loaded");
        } else {
            this.notifications.show("Need to save a state first");
        }
    }

    exportGameDisk () {
        if(this.runtime.diskSize <= 0) {
            this.notifications.show("Disk is empty");
            return;
        }

        const disk = new Uint8Array(this.runtime.diskBuffer).slice(0, this.runtime.diskSize);
        const blob = new Blob([disk], { type: "application/octet-stream" });
        const link = document.createElement("a");

        link.style.display = "none";
        link.href = URL.createObjectURL(blob);
        link.download = `${this.diskPrefix}.disk`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    importGameDisk () {
        const app = this;
        const input = document.createElement("input");

        input.style.display = "none";
        input.type = "file";
        input.accept = ".disk";
        input.multiple = false;

        input.addEventListener("change", () => {
            const files = input.files as FileList;
            let reader = new FileReader();
            
            reader.addEventListener("load", () => {
                let result = new Uint8Array(reader.result as ArrayBuffer).slice(0, constants.STORAGE_SIZE);
                let disk = new Uint8Array(constants.STORAGE_SIZE);

                disk.set(result);
                app.runtime.diskBuffer = disk.buffer;
                this.runtime.diskSize = result.length;
                
                const str = z85.encode(result);
                try {
                    localStorage.setItem(this.runtime.diskName, str);
                    app.notifications.show("Disk imported");
                } catch (error) {
                    app.notifications.show("Error importing disk");
                    console.error("Error importing disk", error);
                }

                app.closeMenu();
            });

            reader.readAsArrayBuffer(files[0]);
        });

        document.body.appendChild(input);
        input.click();
        document.body.removeChild(input);
    }

    clearGameDisk () {
        this.runtime.diskBuffer = new ArrayBuffer(constants.STORAGE_SIZE);
        this.runtime.diskSize = 0;
        
        try {
            localStorage.removeItem(this.runtime.diskName);
        } catch (error) {
            this.notifications.show("Error clearing disk");
            console.error("Error clearing disk", error);
        }

        this.notifications.show("Disk cleared");
    }

    importCart () {
        const app = this;
        const input = document.createElement("input");

        input.style.display = "none";
        input.type = "file";
        input.accept = ".wasm";
        input.multiple = false;

        input.addEventListener("change", () => {
            const files = input.files as FileList;
            let reader = new FileReader();
            
            reader.addEventListener("load", () => {
                this.resetCart(new Uint8Array(reader.result as ArrayBuffer), false);
                app.closeMenu();
            });

            reader.readAsArrayBuffer(files[0]);
        });

        document.body.appendChild(input);
        input.click();
        document.body.removeChild(input);
    }

    async resetCart (wasmBuffer?: Uint8Array, preserveState: boolean = false) {
        if (!wasmBuffer) {
            wasmBuffer = this.runtime.wasmBuffer!;
        }

        let state;
        if (preserveState) {
            // Take a snapshot
            state = new State();
            state.read(this.runtime);
        }
        this.runtime.reset(true);


        this.runtime.pauseState |= constants.PAUSE_REBOOTING;
        await this.runtime.load(wasmBuffer);
        this.runtime.pauseState &= ~constants.PAUSE_REBOOTING;

        if (state) {
            // Restore the previous snapshot
            state.write(this.runtime);
        } else {
            this.runtime.start();
        }
    }

    connectedCallback () {
        super.connectedCallback();

        window.addEventListener("pointerup", this.onPointerUp);
    }

    disconnectedCallback () {
        window.removeEventListener("pointerup", this.onPointerUp);

        super.disconnectedCallback();
    }

    render () {
        return html`
            <wasm4-hardware-components .app=${this}></wasm4-hardware-components>
            <div class="content">
                ${this.showMenu ? html`<wasm4-menu-overlay .app=${this}></wasm4-menu-overlay>`: ""}
                <wasm4-notifications></wasm4-notifications>
                <div class="canvas-wrapper">
                    ${this.runtime.canvas}
                </div>
            </div>
            <wasm4-virtual-gamepad .app=${this}></wasm4-virtual-gamepad>
        `;
    }
}

declare global {
    interface HTMLElementTagNameMap {
        "wasm4-app": App;
    }
}
