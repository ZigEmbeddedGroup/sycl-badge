export function getUrlParam (name: string): string | null {
    const url = new URL(location.href);

    // First try the URL query string
    const value = url.searchParams.get(name);
    if (value != null) {
        return value;
    }

    // Fallback to using the value in the hash
    const hash = new URL(url.hash.substring(1), "https://x");
    return hash.searchParams.get(name);
}

export function requestFullscreen () {
    if (document.fullscreenElement == null) {
        function expandIframe () {
            // Fullscreen failed, try to maximize our own iframe. We don't yet have a button to go
            // back to minimized, but this at least makes games on wasm4.org playable on iPhone
            const iframe = window.frameElement as HTMLElement | null;
            if (iframe) {
                iframe.style.position = "fixed";
                iframe.style.top = "0";
                iframe.style.left = "0";
                iframe.style.zIndex = "99999";
                iframe.style.width = "100%";
                iframe.style.height = "100%";
            }
        }

        const promise = document.body.requestFullscreen && document.body.requestFullscreen({navigationUI: "hide"});
        if (promise) {
            promise.catch(expandIframe);
        } else {
            expandIframe();
        }
    }
}

/**
 * @param red `0-31`
 * @param green `0-63`
 * @param blue `0-31`
 * @returns RGB565 representation
 */
export function pack565(red: number, green: number, blue: number): number {
    return blue | (green << 5) | (red << 11);
}

export function unpack565(bgr565: number): [number, number, number] {
    return [bgr565 >> 11, bgr565 >> 5 & 0b111111, bgr565 & 0b11111];
}

export function unpack888(bgr888: number): [number, number, number] {
    return [(bgr888 >> 8) & 0b11111111, bgr888 & 0b11111111, bgr888 >> 16];
}
