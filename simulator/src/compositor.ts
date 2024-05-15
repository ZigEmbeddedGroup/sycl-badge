import { WIDTH, HEIGHT } from "./constants";
import * as constants from "./constants";
import * as GL from "./webgl-constants";
import type { Framebuffer } from "./framebuffer";

const PALETTE_SIZE = 4;

export class WebGLCompositor {
    constructor (public gl: WebGLRenderingContext) {
        const canvas = gl.canvas;
        canvas.addEventListener("webglcontextlost", event => {
            event.preventDefault();
        });
        canvas.addEventListener("webglcontextrestored", () => { this.initGL() });

        this.initGL();

        // // Test WebGL context loss
        // window.addEventListener("mousedown", () => {
        //     console.log("Losing context");
        //     const ext = gl.getExtension('WEBGL_lose_context');
        //     ext.loseContext();
        //     setTimeout(() => {
        //         ext.restoreContext();
        //     }, 0);
        // })
    }

    initGL () {
        const gl = this.gl;

        function createShader (type: number, source: string) {
            const shader = gl.createShader(type)!;

            gl.shaderSource(shader, source);
            gl.compileShader(shader);
            if (gl.getShaderParameter(shader, GL.COMPILE_STATUS) == 0) {
                throw new Error(gl.getShaderInfoLog(shader) + '');
            }
            return shader;
        }

        function createTexture (slot: number) {
            const texture = gl.createTexture();
            gl.activeTexture(slot);
            gl.bindTexture(GL.TEXTURE_2D, texture);
            gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
            gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
            gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
            gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
        }

        const vertexShader = createShader(GL.VERTEX_SHADER, `
            attribute vec2 pos;
            varying vec2 framebufferCoord;

            void main () {
                framebufferCoord = pos*vec2(0.5, -0.5) + 0.5;
                gl_Position = vec4(pos, 0, 1);
            }
        `);

        const fragmentShader = createShader(GL.FRAGMENT_SHADER, `
            precision mediump float;
            uniform sampler2D framebuffer;
            varying vec2 framebufferCoord;

            void main () {
                gl_FragColor = texture2D(framebuffer, framebufferCoord);
            }
        `);

        // Setup shaders
        const program = gl.createProgram()!;

        gl.attachShader(program, vertexShader);
        gl.attachShader(program, fragmentShader);
        gl.linkProgram(program);
        if (gl.getProgramParameter(program, GL.LINK_STATUS) == 0) {
            throw new Error(gl.getProgramInfoLog(program) + '');
        }
        gl.useProgram(program);

        gl.uniform1i(gl.getUniformLocation(program, "framebuffer"), 0);

        // Cleanup shaders
        gl.detachShader(program, vertexShader);
        gl.deleteShader(vertexShader);
        gl.detachShader(program, fragmentShader);
        gl.deleteShader(fragmentShader);

        // Create framebuffer texture
        createTexture(GL.TEXTURE0);
        gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGB565, WIDTH, HEIGHT, 0, GL.RGB, GL.UNSIGNED_SHORT_5_6_5, null);

        // Setup static geometry
        const positionAttrib = gl.getAttribLocation(program, "pos");
        const positionBuffer = gl.createBuffer();
        const positionData = new Float32Array([
            -1, -1, -1, +1, +1, +1,
            +1, +1, +1, -1, -1, -1,
        ]);
        gl.bindBuffer(GL.ARRAY_BUFFER, positionBuffer);
        gl.bufferData(GL.ARRAY_BUFFER, positionData, GL.STATIC_DRAW);
        gl.enableVertexAttribArray(positionAttrib);
        gl.vertexAttribPointer(positionAttrib, 2, GL.FLOAT, false, 0, 0);
    }

    composite (framebuffer: Framebuffer): number {
        const gl = this.gl;
        const bytes = framebuffer.bytes;

        // Upload framebuffer
        gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGB565, WIDTH, HEIGHT, 0, GL.RGB, GL.UNSIGNED_SHORT_5_6_5, bytes);

        // Draw the fullscreen quad
        gl.drawArrays(GL.TRIANGLES, 0, 6);

        return framebuffer.countChangedPixelsAndReset();
    }
}
