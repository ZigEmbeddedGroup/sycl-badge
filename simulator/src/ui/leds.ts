import { LitElement, html, css } from "lit";
import { customElement, query, state } from 'lit/decorators.js';
import { App } from "./app";
import { unpack888 } from "./utils";

@customElement("wasm4-leds")
export class LEDs extends LitElement {
    static styles = css`
        .leds {
            display: flex;
            gap: 40px;
            align-items: center;
        }

        .neopixels {
            display: flex;
            gap: 10px;
            align-items: center;
        }

        .led-wrapper {
            border: 3px solid black;
            border-radius: 3px;
            width: 40px;
            height: 40px;
            padding: 2.5px;
            background-color: white;
        }

        .led {
            border-radius: 100px;
            width: 100%;
            height: 100%;
            background-color: var(--color);
        }
    `;

    app!: App;

    @state() public neopixels: [number, number, number, number, number] = [0, 0, 0, 0, 0];
    @state() public redLed: boolean = false;

    render () {
        return html`
            <div class="leds">
                <div class="neopixels">
                    ${this.neopixels.map(_ => {
                        const [r, g, b] = unpack888(_);
                        return html`<div class="led-wrapper"><div class="led" style="--color: rgb(${r}, ${g}, ${b})"></div></div>`;
                    })}
                </div>
                <div class="led-wrapper"><div class="led" style="--color: rgba(255, 0, 0, ${this.redLed ? 1 : 0.4});"></div></div>
            </div>
        `;
    }
}

declare global {
    interface HTMLElementTagNameMap {
        "wasm4-leds": LEDs;
    }
}
