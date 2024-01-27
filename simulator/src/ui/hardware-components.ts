import { LitElement, html, css } from "lit";
import { customElement, query, state } from 'lit/decorators.js';
import { App } from "./app";
import { unpack888 } from "./utils";

@customElement("wasm4-hardware-components")
export class HardwareComponents extends LitElement {
    static styles = css`
        :host {
            position: absolute;

            top: 20px;

            color: white;
            font-family: wasm4-font;
        }

        .labelled {
            display: flex;
            gap: 20px;
            align-items: center;
        }

        .neopixels {
            display: flex;
            gap: 5px;
            align-items: center;
        }

        .led {
            border: 2px solid white;
            border-radius: 100px;
            width: 20px;
            height: 20px;
            background-color: var(--color);
        }
    `;

    app!: App;

    @state() public neopixels: [number, number, number, number, number] = [0, 0, 0, 0, 0];
    @state() public redLed: boolean = false;

    lightLevelChanged(event: Event) {
        this.app.lightLevel = parseInt((event.target as HTMLInputElement).value);
    }

    render () {
        return html`
            <div class="labelled">
                <span>LEDs</span>
                <div class="neopixels">
                    ${this.neopixels.map(_ => {
                        const [r, g, b] = unpack888(_);
                        return html`<div class="led" style="--color: rgb(${r}, ${g}, ${b})"></div>`;
                    })}
                </div>
                <div class="led" style="--color: rgba(255, 0, 0, ${this.redLed ? 1 : 0.05});"></div>
            </div>
            <div class="labelled">
                <span>Light</span>
                <input type="range" class="range" min="0" max="4095" @input=${this.lightLevelChanged}>
            </div>
        `;
    }
}

declare global {
    interface HTMLElementTagNameMap {
        "wasm4-hardware-components": HardwareComponents;
    }
}
