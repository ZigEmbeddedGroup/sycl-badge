import { LitElement, html, css } from "lit";
import { customElement, state, query } from 'lit/decorators.js';

import * as constants from "../constants";
import * as utils from "./utils";
import * as z85 from "../z85";
import { Runtime } from "../runtime";
import { State } from "../state";

import { MenuOverlay } from "./menu-overlay";
import { Notifications } from "./notifications";
import { LEDs } from "./leds";
import { LightSensor } from "./light-sensor";

@customElement("wasm4-app")
export class App extends LitElement {
    static styles = css`
        :host {
            width: 100%;
            height: 100%;
            display: flex;

            touch-action: none;
            user-select: none;
            -webkit-user-select: none;
            -webkit-tap-highlight-color: transparent;

            background: #202020;
        }

        .content {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            width: 100vw;
            height: 100vh;
            overflow: hidden;
            gap: 0.5rem;
            padding: 0.5rem;
            box-sizing: border-box;
        }

        /** Nudge the game upwards a bit in portrait to make space for the virtual gamepad. */
        @media (pointer: coarse) and (max-aspect-ratio: 2/3) {
            .content {
                position: absolute;
                top: calc((100% - 220px - 100vmin)/2)
            }
        }

        canvas {
            flex: 1;
            max-width: 100%;
            object-fit: contain;
            image-rendering: pixelated;
            image-rendering: crisp-edges;
        }

        .help {
            font-family: wasm4-font;
            font-size: 0.9em;
            color: #aaa;
        }
    `;

    private readonly runtime: Runtime;

    @state() private showMenu = false;

    @query("wasm4-menu-overlay") private menuOverlay?: MenuOverlay;
    @query("wasm4-notifications") private notifications!: Notifications;
    @query("wasm4-leds") private hardwareComponents!: LEDs;

    private savedGameState?: State;

    public controls: number = 0;
    public lightLevel: number = 0;

    private readonly gamepadUnavailableWarned = new Set<string>();

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

        this.runtime = new Runtime();

        this.init();
    }

    async init () {
        const runtime = this.runtime;
        await runtime.init();

        const canvas = runtime.canvas;

        fetch("http://localhost:2468/cart.wasm").then(async res => {
            await this.resetCart(new Uint8Array(await (res).arrayBuffer()), false);
        }).catch(() => {
            if (!this.runtime.wasmBuffer) {
                runtime.blueScreen("Watcher not found.\n\nStart and reload.");
            }
        });

        let wsWasConnected = false
        const ws = new WebSocket(`ws://localhost:2468/ws`);
        ws.onopen = () => {
            wsWasConnected = true;
            setInterval(() => {
                ws.send("spam");
            }, 100);
        }
        ws.onclose = () => {
            if (wsWasConnected) {
                wsWasConnected = false;
                runtime.blueScreen("Watcher was\ndisconnected.");
            }
        };
        ws.onmessage = async m => {
            if (m.data == "reload") {
                await this.resetCart(new Uint8Array(await (await fetch("http://localhost:2468/cart.wasm")).arrayBuffer()), false);
            }
        }

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
            case "Enter": case "KeyY":
                mask |= constants.CONTROLS_START;
                break;
            case "Backspace": case "KeyT":
                mask |= constants.CONTROLS_SELECT;
                break;
            case "KeyZ": case "KeyK":
                mask |= constants.CONTROLS_A;
                break;
            case "KeyX": case "KeyJ":
                mask |= constants.CONTROLS_B;
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

        // Drag and drop handlers for loading carts
        window.addEventListener("dragover", e => e.preventDefault());
        window.addEventListener("drop", e => {
            e.preventDefault();
            if (e.dataTransfer?.files?.[0]) {
                this.loadCartFromFile(e.dataTransfer.files[0]);
            }
        });

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
                const extraTimePenalty = runtime.composite();
                const screenDoneTime = timeFrameStart + extraTimePenalty;
                if (screenDoneTime > timeNextUpdate) {
                    console.log("throttled by pixels!");
                    timeNextUpdate = screenDoneTime;
                }

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

    loadCartFromFile (file: File) {
        let reader = new FileReader();
        reader.addEventListener("load", () => {
            this.resetCart(new Uint8Array(reader.result as ArrayBuffer), false);
        });
        reader.readAsArrayBuffer(file);
    }

    importCart () {
        const input = document.createElement("input");

        input.style.display = "none";
        input.type = "file";
        input.accept = ".wasm";
        input.multiple = false;

        input.addEventListener("change", async () => {
            if (input.files?.[0]) {
                this.loadCartFromFile(input.files[0]);
            }
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
            <div class="content">
                ${this.showMenu ? html`<wasm4-menu-overlay .app=${this}></wasm4-menu-overlay>`: ""}
                <wasm4-notifications></wasm4-notifications>
                <wasm4-light-sensor .app=${this}></wasm4-light-sensor>
                ${this.runtime.canvas}
                <wasm4-leds .app=${this}></wasm4-leds>
                <div class="help">
                    Controls: Arrows/WASD, Z/K, X/J, Enter/Y, Backspace/T, Escape
                </div>
            </div>
        `;
        // <wasm4-virtual-gamepad .app=${this}></wasm4-virtual-gamepad>
    }
}

declare global {
    interface HTMLElementTagNameMap {
        "wasm4-app": App;
    }
}
