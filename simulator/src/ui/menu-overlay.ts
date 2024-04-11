import { LitElement, html, css } from "lit";
import { customElement, state } from 'lit/decorators.js';
import { map } from 'lit/directives/map.js';

import { App } from "./app";
import * as constants from "../constants";

const optionContext = {
    DEFAULT: 0,
    DISK: 1,
};

const optionIndex = [
    {
        CONTINUE: 0,
        SAVE_STATE: 1,
        LOAD_STATE: 2,
        DISK_OPTIONS: 3,
        LOAD_CART: 4,
        // OPTIONS: null,
        RESET_CART: 5,
    },
    {
        BACK: 0,
        EXPORT_DISK: 1,
        IMPORT_DISK: 2,
        CLEAR_DISK: 3,
    }
];

const options = [
    [
        "CONTINUE",
        "SAVE STATE",
        "LOAD STATE",
        "DISK OPTIONS",
        "LOAD CART",
        // "OPTIONS",
        "RESET CART",
    ],
    [
        "BACK",
        "EXPORT DISK",
        "IMPORT DISK",
        "CLEAR DISK",
    ]
];

@customElement("wasm4-menu-overlay")
export class MenuOverlay extends LitElement {
    static styles = css`
        :host {
            width: 100vmin;
            height: 100vmin;
            position: absolute;

            color: #a0a0a0;
            font: 16px wasm4-font;

            display: flex;
            align-items: center;
            justify-content: center;
            flex-direction: column;

            background: rgba(0, 0, 0, 0.85);
        }

        .menu {
            border: 2px solid #f0f0f0;
            padding: 0 1em 0 1em;
            line-height: 2em;
        }

        .ping-you {
            color: #f0f0f0;
        }

        .ping-good {
            color: green;
        }

        .ping-ok {
            color: yellow;
        }

        .ping-bad {
            color: red;
        }

        ul {
            list-style: none;
            padding-left: 0;
            padding-right: 1em;
        }

        li::before {
            content: "\\00a0\\00a0";
        }
        li.selected::before {
            content: "> ";
        }
        li.selected {
            color: #fff;
        }
    `;

    app!: App;

    private lastGamepad = 0;

    @state() private selectedIdx = 0;

    private optionContext: number = 0;

    private optionContextHistory: {context: number, index: number}[] = [];

    constructor () {
        super();
    }

    get optionIndex (): any {
        return optionIndex[this.optionContext];
    }

    get options (): string[] {
        return options[this.optionContext];
    }

    previousContext () {
        if(this.optionContextHistory.length > 0) {
            const previousContext = this.optionContextHistory.pop() as {context: number, index: number};

            this.resetInput();
            this.optionContext = previousContext.context;
            this.selectedIdx = previousContext.index;
        }
    }

    switchContext (context: number, index: number = 0) {
        this.optionContextHistory.push({
            context: this.optionContext, 
            index: this.selectedIdx
        });

        this.resetInput();
        this.optionContext = context;
        this.selectedIdx = index;
    }

    resetInput () {
        this.app.controls = 0;
    }

    applyInput () {
        const controls = this.app.controls;
        const pressedThisFrame = controls & (controls ^ this.lastGamepad);
        this.lastGamepad = controls;

        if (pressedThisFrame & (constants.CONTROLS_START | constants.CONTROLS_A)) {
            if(this.optionContext === optionContext.DEFAULT) {
                switch (this.selectedIdx) {
                    case this.optionIndex.CONTINUE:
                        this.app.closeMenu();
                        break;
                    case this.optionIndex.SAVE_STATE:
                        this.app.saveGameState();
                        this.app.closeMenu();
                        break;
                    case this.optionIndex.LOAD_STATE:
                        this.app.loadGameState();
                        this.app.closeMenu();
                        break;
                    case this.optionIndex.DISK_OPTIONS:
                        this.switchContext(optionContext.DISK);
                        break;
                    case this.optionIndex.LOAD_CART:
                        this.app.importCart();
                        this.app.closeMenu();
                        break;
                    case this.optionIndex.RESET_CART:
                        this.app.resetCart();
                        this.app.closeMenu();
                        break;
                }
            }
            else if(this.optionContext === optionContext.DISK) {
                switch (this.selectedIdx) {
                    case this.optionIndex.BACK:
                        this.previousContext();
                        break;
                    case this.optionIndex.EXPORT_DISK:
                        this.app.exportGameDisk();
                        this.app.closeMenu();
                        break;
                    case this.optionIndex.IMPORT_DISK:
                        this.resetInput();
                        this.app.importGameDisk();
                        break;
                    case this.optionIndex.CLEAR_DISK:
                        this.app.clearGameDisk();
                        this.app.closeMenu();
                        break;
                }
            }
        }

        if (pressedThisFrame & constants.CONTROLS_DOWN) {
            this.selectedIdx++;
        }
        if (pressedThisFrame & constants.CONTROLS_UP) {
            this.selectedIdx--;
        }
        this.selectedIdx = (this.selectedIdx + this.options.length) % this.options.length;
    }

    render () {
        return html`
            <div class="menu">
                <ul style="display:${this.optionContext === optionContext.DEFAULT? "inherit": "none"}">
                    ${map(options[optionContext.DEFAULT], (option, idx) =>
                        html`<li class="${this.selectedIdx == idx ? "selected" : ""}"}>${option}</li>`)}
                </ul>
                <ul style="display:${this.optionContext === optionContext.DISK? "inherit": "none"}">
                    ${map(options[optionContext.DISK], (option, idx) =>
                        html`<li class="${this.selectedIdx == idx ? "selected" : ""}"}>${option}</li>`)}
                </ul>
            </div>
        `;
    }
}

declare global {
    interface HTMLElementTagNameMap {
        "wasm4-menu-overlay": MenuOverlay;
    }
}
