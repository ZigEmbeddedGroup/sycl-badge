import { LitElement, html, css } from "lit";
import { customElement, state, query } from 'lit/decorators.js';

import * as constants from "../constants";
import * as utils from "./utils";
import * as z85 from "../z85";
import { Runtime } from "../runtime";
import { State } from "../state";

import { MenuOverlay } from "./menu-overlay";
import { Notifications } from "./notifications";

class InputState {
    gamepad = [0, 0, 0, 0];
    mouseX = 0;
    mouseY = 0;
    mouseButtons = 0;
}

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

    private savedGameState?: State;

    readonly inputState = new InputState();
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

        const onMouseEvent = (event: PointerEvent) => {
            // Unhide the cursor if it was hidden by the keyboard handler
            document.body.style.cursor = "";

            if (event.isPrimary) {
                const bounds = canvas.getBoundingClientRect();
                const input = this.inputState;
                input.mouseX = Math.fround(constants.WIDTH * (event.clientX - bounds.left) / bounds.width);
                input.mouseY = Math.fround(constants.HEIGHT * (event.clientY - bounds.top) / bounds.height);
                input.mouseButtons = event.buttons & 0b111;
            }
        };
        window.addEventListener("pointerdown", onMouseEvent);
        window.addEventListener("pointerup", onMouseEvent);
        window.addEventListener("pointermove", onMouseEvent);

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
            "Enter": this.onMenuButtonPressed.bind(this),
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

            // We're using the keyboard now, hide the mouse cursor for extra immersion
            document.body.style.cursor = "none";

            if (down) {
                const hotkeyFn = HOTKEYS[event.key];
                if (hotkeyFn) {
                    hotkeyFn();
                    event.preventDefault();
                    return;
                }
            }

            let playerIdx = 0;
            let mask = 0;
            switch (event.code) {
            // Player 1
            case "KeyX": case "KeyV": case "Space": case "Period":
                mask = constants.BUTTON_X;
                break;
            case "KeyZ": case "KeyC": case "Comma":
                mask = constants.BUTTON_Z;
                break;
            case "ArrowUp":
                mask = constants.BUTTON_UP;
                break;
            case "ArrowDown":
                mask = constants.BUTTON_DOWN;
                break;
            case "ArrowLeft":
                mask = constants.BUTTON_LEFT;
                break;
            case "ArrowRight":
                mask = constants.BUTTON_RIGHT;
                break;

            // Player 2
            case "KeyA": case "KeyQ":
                playerIdx = 1;
                mask = constants.BUTTON_X;
                break;
            case "ShiftLeft": case "Tab":
                playerIdx = 1;
                mask = constants.BUTTON_Z;
                break;
            case "KeyE":
                playerIdx = 1;
                mask = constants.BUTTON_UP;
                break;
            case "KeyD":
                playerIdx = 1;
                mask = constants.BUTTON_DOWN;
                break;
            case "KeyS":
                playerIdx = 1;
                mask = constants.BUTTON_LEFT;
                break;
            case "KeyF":
                playerIdx = 1;
                mask = constants.BUTTON_RIGHT;
                break;

            // Player 3
            case "NumpadMultiply": case "NumpadDecimal":
                playerIdx = 2;
                mask = constants.BUTTON_X;
                break;
            case "NumpadSubtract": case "NumpadEnter":
                playerIdx = 2;
                mask = constants.BUTTON_Z;
                break;
            case "Numpad8":
                playerIdx = 2;
                mask = constants.BUTTON_UP;
                break;
            case "Numpad5":
                playerIdx = 2;
                mask = constants.BUTTON_DOWN;
                break;
            case "Numpad4":
                playerIdx = 2;
                mask = constants.BUTTON_LEFT;
                break;
            case "Numpad6":
                playerIdx = 2;
                mask = constants.BUTTON_RIGHT;
                break;
            }

            if (mask != 0) {
                event.preventDefault();

                // Set or clear the button bit from the next input state
                const gamepad = this.inputState.gamepad;
                if (down) {
                    gamepad[playerIdx] |= mask;
                } else {
                    gamepad[playerIdx] &= ~mask;
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
            if (!navigator.getGamepads) {
                return; // Browser doesn't support gamepads
            }

            for (const gamepad of navigator.getGamepads()) {
                if (gamepad == null) {
                    continue; // Disconnected gamepad
                } else if (gamepad.mapping != "standard") {
                    // The gamepad is available, but nonstandard, so we don't actually know how to read it.
                    // Let's warn once, and not use this gamepad afterwards.
                    if (!this.gamepadUnavailableWarned.has(gamepad.id)) {
                        this.gamepadUnavailableWarned.add(gamepad.id);
                        this.notifications.show("Unsupported gamepad: " + gamepad.id);
                    }
                    continue;
                }

                // https://www.w3.org/TR/gamepad/#remapping
                const buttons = gamepad.buttons;
                const axes = gamepad.axes;

                let mask = 0;
                if (buttons[12].pressed || axes[1] < -0.5) {
                    mask |= constants.BUTTON_UP;
                }
                if (buttons[13].pressed || axes[1] > 0.5) {
                    mask |= constants.BUTTON_DOWN;
                }
                if (buttons[14].pressed || axes[0] < -0.5) {
                    mask |= constants.BUTTON_LEFT;
                }
                if (buttons[15].pressed || axes[0] > 0.5) {
                    mask |= constants.BUTTON_RIGHT;
                }
                if (buttons[0].pressed || buttons[3].pressed || buttons[5].pressed || buttons[7].pressed) {
                    mask |= constants.BUTTON_X;
                }
                if (buttons[1].pressed || buttons[2].pressed || buttons[4].pressed || buttons[6].pressed) {
                    mask |= constants.BUTTON_Z;
                }

                if (buttons[9].pressed) {
                    this.showMenu = true;
                }

                this.inputState.gamepad[gamepad.index % 4] = mask;
            }
        }

        // When we should perform the next update
        let timeNextUpdate = performance.now();
        // Track the timestamp of the last frame
        let lastTimeFrameStart = timeNextUpdate;

        const onFrame = (timeFrameStart: number) => {
            requestAnimationFrame(onFrame);

            pollPhysicalGamepads();
            let input = this.inputState;

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
                for (let playerIdx = 0; playerIdx < 4; ++playerIdx) {
                    runtime.setGamepad(playerIdx, input.gamepad[playerIdx]);
                }
                runtime.setMouse(input.mouseX, input.mouseY, input.mouseButtons);
                runtime.update();
                calledUpdate = true;
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
            this.inputState.gamepad[0] |= constants.BUTTON_X;
        } else {
            this.showMenu = true;
        }
    }

    closeMenu () {
        if (this.showMenu) {
            this.showMenu = false;

            // Kind of a hack to prevent the button press to close the menu from being passed
            // through to the game
            for (let playerIdx = 0; playerIdx < 4; ++playerIdx) {
                this.inputState.gamepad[playerIdx] = 0;
            }
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
            <div class="content">
                ${this.showMenu ? html`<wasm4-menu-overlay .app=${this} />`: ""}
                <wasm4-notifications></wasm4-notifications>
                <div class="canvas-wrapper">
                    ${this.runtime.canvas}
                </div>
            </div>
            <wasm4-virtual-gamepad .app=${this} />
        `;
    }
}

declare global {
    interface HTMLElementTagNameMap {
        "wasm4-app": App;
    }
}
