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
            const iframe = window.frameElement;
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
