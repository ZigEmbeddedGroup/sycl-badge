import { LitElement, html, css } from "lit";
import { customElement } from 'lit/decorators.js';
import { App } from "./app";

@customElement("wasm4-light-sensor")
export class LightSensor extends LitElement {
    static styles = css`
        input[type="range"] {
            position: relative;
            -webkit-appearance: none;
            appearance: none;
            background: transparent;
            cursor: pointer;
            width: 15rem;
            padding: 0px 0.1rem;

            height: 1.1rem;
            border: 3px solid black;
            border-radius: 20px;
            background: linear-gradient(to right, black, yellow);
        }

        input[type="range"]::-webkit-slider-thumb {
            -webkit-appearance: none;
            appearance: none;
            border: 3px solid black;
            background-color: white;
            height: 1.75rem;
            width: 1rem;
            z-index: 100;
            border-radius: 3px;
        }
    `;

    app!: App;

    lightLevelChanged(event: Event) {
        this.app.lightLevel = parseInt((event.target as HTMLInputElement).value);
    }

    render () {
        return html`
            <input type="range" class="range" min="0" max="4095" value="0" @input=${this.lightLevelChanged}>
        `;
    }
}

declare global {
    interface HTMLElementTagNameMap {
        "wasm4-light-sensor": LightSensor;
    }
}
