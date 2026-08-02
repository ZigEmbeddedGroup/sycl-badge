//! Cart build tooling.
//!
//! ```text
//! cargo xtask build [-p <package>]   build a cart to target/cart.wasm
//! cargo xtask watch [-p <package>]   build, then serve it with live reload
//! ```
//!
//! `watch` implements the contract the existing simulator already speaks
//! (`simulator/src/ui/app.ts`):
//!
//! * `GET http://localhost:2468/cart.wasm` — the cart, with permissive CORS
//!   because the simulator UI is served from a different port.
//! * `ws://localhost:2468/ws` — the client sends a keepalive every 100 ms and
//!   reloads when it receives the text `reload`. If the socket closes, the
//!   simulator shows "Watcher was disconnected".
//!
//! There is no watcher in the repo at the moment — `docs/introduction/build.zig`
//! calls a `install_with_watcher` helper that no longer exists in `build.zig` —
//! so this fills a gap for Zig carts too, given a `.wasm` in the right place.
//!
//! Zero dependencies, so `cargo xtask` is quick and there is no supply chain to
//! vet for a dev tool.

use std::collections::HashMap;
use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream};
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::mpsc;
use std::sync::{Arc, Mutex};
use std::time::{Duration, SystemTime};

const PORT: u16 = 2468;
const TARGET: &str = "wasm32-unknown-unknown";
const DEFAULT_PACKAGE: &str = "flappy";
/// The simulator warns past this; see `simulator/src/runtime.ts`.
const SIM_SIZE_WARN: u64 = 64 * 1024;
const POLL_INTERVAL: Duration = Duration::from_millis(300);

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let cmd = args.first().map(String::as_str).unwrap_or("help");

    let package = flag(&args, "-p")
        .or_else(|| flag(&args, "--package"))
        .unwrap_or_else(|| DEFAULT_PACKAGE.to_string());
    let debug = args.iter().any(|a| a == "--debug");

    match cmd {
        "build" => {
            if build(&package, debug).is_none() {
                std::process::exit(1);
            }
        }
        "watch" => watch(&package, debug),
        _ => {
            eprintln!("usage: cargo xtask <build|watch> [-p <package>] [--debug]");
            std::process::exit(2);
        }
    }
}

fn flag(args: &[String], name: &str) -> Option<String> {
    let i = args.iter().position(|a| a == name)?;
    args.get(i + 1).cloned()
}

fn workspace_root() -> PathBuf {
    // CARGO_MANIFEST_DIR is <workspace>/xtask.
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .unwrap()
        .to_path_buf()
}

/// Build the cart and copy it to `target/cart.wasm`. Returns the output path.
fn build(package: &str, debug: bool) -> Option<PathBuf> {
    let root = workspace_root();
    let profile = if debug { "dev" } else { "release" };
    let profile_dir = if debug { "debug" } else { "release" };

    let status = Command::new(std::env::var("CARGO").unwrap_or_else(|_| "cargo".into()))
        .current_dir(&root)
        .args([
            "build",
            "--target",
            TARGET,
            "--profile",
            profile,
            "-p",
            package,
        ])
        .status();

    match status {
        Ok(s) if s.success() => {}
        Ok(_) => {
            eprintln!("build failed");
            return None;
        }
        Err(e) => {
            eprintln!("could not run cargo: {e}");
            return None;
        }
    }

    let built = root
        .join("target")
        .join(TARGET)
        .join(profile_dir)
        .join(format!("{}.wasm", package.replace('-', "_")));
    if !built.exists() {
        eprintln!("expected a cdylib at {}", built.display());
        return None;
    }

    let out = root.join("target").join("cart.wasm");
    if let Err(e) = std::fs::copy(&built, &out) {
        eprintln!("copy failed: {e}");
        return None;
    }

    let size = std::fs::metadata(&out).map(|m| m.len()).unwrap_or(0);
    print!("built {} -> target/cart.wasm ({size} bytes)", package);
    if size > SIM_SIZE_WARN {
        print!("  [over the simulator's {SIM_SIZE_WARN}-byte soft limit]");
    }
    println!();
    Some(out)
}

// ── watch ───────────────────────────────────────────────────────────────────

fn watch(package: &str, debug: bool) {
    let root = workspace_root();
    let cart = root.join("target").join("cart.wasm");
    build(package, debug);

    let clients: Arc<Mutex<Vec<TcpStream>>> = Arc::new(Mutex::new(Vec::new()));
    let (reload_tx, reload_rx) = mpsc::channel::<()>();

    {
        let cart = cart.clone();
        let clients = Arc::clone(&clients);
        std::thread::spawn(move || serve(cart, clients, reload_rx));
    }

    println!("watching {package}; simulator should connect to http://localhost:{PORT}");
    println!("open the simulator UI (cd simulator && npm run dev) at http://localhost:1234");

    let watched = watch_paths(&root, package);
    let mut seen = snapshot(&watched);

    loop {
        std::thread::sleep(POLL_INTERVAL);
        let now = snapshot(&watched);
        if now == seen {
            continue;
        }
        seen = now;
        println!("change detected, rebuilding");
        if build(package, debug).is_some() {
            let _ = reload_tx.send(());
        }
    }
}

fn watch_paths(root: &Path, package: &str) -> Vec<PathBuf> {
    vec![
        root.join("sycl-cart").join("src"),
        root.join("sycl-cart").join("Cargo.toml"),
        root.join("showcase").join(package).join("src"),
        root.join("showcase").join(package).join("Cargo.toml"),
    ]
}

/// Modification times of every file under the watched paths.
fn snapshot(paths: &[PathBuf]) -> HashMap<PathBuf, SystemTime> {
    let mut out = HashMap::new();
    for p in paths {
        collect(p, &mut out);
    }
    out
}

fn collect(path: &Path, out: &mut HashMap<PathBuf, SystemTime>) {
    let Ok(meta) = std::fs::metadata(path) else {
        return;
    };
    if meta.is_file() {
        if let Ok(m) = meta.modified() {
            out.insert(path.to_path_buf(), m);
        }
        return;
    }
    let Ok(entries) = std::fs::read_dir(path) else {
        return;
    };
    for entry in entries.flatten() {
        collect(&entry.path(), out);
    }
}

// ── HTTP + WebSocket ────────────────────────────────────────────────────────

fn serve(cart: PathBuf, clients: Arc<Mutex<Vec<TcpStream>>>, reload: mpsc::Receiver<()>) {
    let listener = match TcpListener::bind(("127.0.0.1", PORT)) {
        Ok(l) => l,
        Err(e) => {
            eprintln!("cannot bind port {PORT}: {e}");
            return;
        }
    };

    // Broadcast reloads from a separate thread so accepting never blocks on it.
    {
        let clients = Arc::clone(&clients);
        std::thread::spawn(move || {
            while reload.recv().is_ok() {
                let frame = text_frame("reload");
                let mut guard = clients.lock().unwrap();
                guard.retain_mut(|s| s.write_all(&frame).and_then(|_| s.flush()).is_ok());
                println!("reload sent to {} client(s)", guard.len());
            }
        });
    }

    for stream in listener.incoming().flatten() {
        let cart = cart.clone();
        let clients = Arc::clone(&clients);
        std::thread::spawn(move || {
            if let Err(e) = handle(stream, &cart, &clients) {
                // Browsers open and abandon probe connections constantly; not
                // worth reporting.
                let _ = e;
            }
        });
    }
}

fn handle(
    mut stream: TcpStream,
    cart: &Path,
    clients: &Arc<Mutex<Vec<TcpStream>>>,
) -> std::io::Result<()> {
    let request = read_headers(&mut stream)?;
    let (start_line, headers) = parse_request(&request);
    let mut parts = start_line.split_whitespace();
    let method = parts.next().unwrap_or("");
    let path = parts.next().unwrap_or("");

    if method == "OPTIONS" {
        return stream.write_all(
            b"HTTP/1.1 204 No Content\r\n\
              Access-Control-Allow-Origin: *\r\n\
              Access-Control-Allow-Methods: GET, OPTIONS\r\n\
              Access-Control-Allow-Headers: *\r\n\
              Content-Length: 0\r\n\r\n",
        );
    }

    let upgrading = headers
        .get("upgrade")
        .map(|v| v.eq_ignore_ascii_case("websocket"))
        .unwrap_or(false);

    if upgrading {
        let Some(key) = headers.get("sec-websocket-key") else {
            return respond(&mut stream, "400 Bad Request", b"missing key", "text/plain");
        };
        let accept = base64(&sha1(
            format!("{key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11").as_bytes(),
        ));
        stream.write_all(
            format!(
                "HTTP/1.1 101 Switching Protocols\r\n\
                 Upgrade: websocket\r\n\
                 Connection: Upgrade\r\n\
                 Sec-WebSocket-Accept: {accept}\r\n\r\n"
            )
            .as_bytes(),
        )?;
        stream.flush()?;

        // Keep a handle for broadcasting, and drain the client's keepalives on
        // this thread so its send buffer never backs up.
        let writer = stream.try_clone()?;
        clients.lock().unwrap().push(writer);
        println!("simulator connected");

        let mut sink = [0u8; 256];
        loop {
            match stream.read(&mut sink) {
                Ok(0) | Err(_) => break,
                Ok(_) => {}
            }
        }
        println!("simulator disconnected");
        return Ok(());
    }

    if method == "GET" && (path == "/cart.wasm" || path.starts_with("/cart.wasm?")) {
        return match std::fs::read(cart) {
            Ok(bytes) => respond(&mut stream, "200 OK", &bytes, "application/wasm"),
            Err(_) => respond(
                &mut stream,
                "404 Not Found",
                b"no cart built yet",
                "text/plain",
            ),
        };
    }

    respond(&mut stream, "404 Not Found", b"not found", "text/plain")
}

fn respond(
    stream: &mut TcpStream,
    status: &str,
    body: &[u8],
    content_type: &str,
) -> std::io::Result<()> {
    let head = format!(
        "HTTP/1.1 {status}\r\n\
         Content-Type: {content_type}\r\n\
         Content-Length: {}\r\n\
         Access-Control-Allow-Origin: *\r\n\
         Cache-Control: no-store\r\n\r\n",
        body.len()
    );
    stream.write_all(head.as_bytes())?;
    stream.write_all(body)?;
    stream.flush()
}

/// Read until the end of the header block.
fn read_headers(stream: &mut TcpStream) -> std::io::Result<String> {
    let mut buf = Vec::with_capacity(1024);
    let mut byte = [0u8; 1];
    while !buf.ends_with(b"\r\n\r\n") {
        if stream.read(&mut byte)? == 0 {
            break;
        }
        buf.push(byte[0]);
        if buf.len() > 16 * 1024 {
            break;
        }
    }
    Ok(String::from_utf8_lossy(&buf).into_owned())
}

fn parse_request(request: &str) -> (&str, HashMap<String, String>) {
    let mut lines = request.split("\r\n");
    let start = lines.next().unwrap_or("");
    let mut headers = HashMap::new();
    for line in lines {
        if line.is_empty() {
            break;
        }
        if let Some((k, v)) = line.split_once(':') {
            headers.insert(k.trim().to_ascii_lowercase(), v.trim().to_string());
        }
    }
    (start, headers)
}

/// An unmasked text frame. Server-to-client frames must not be masked, and our
/// payloads are tiny, so the 2-byte header form is always enough.
fn text_frame(payload: &str) -> Vec<u8> {
    let bytes = payload.as_bytes();
    assert!(bytes.len() < 126);
    let mut out = Vec::with_capacity(bytes.len() + 2);
    out.push(0x81); // FIN | text
    out.push(bytes.len() as u8);
    out.extend_from_slice(bytes);
    out
}

// ── Minimal SHA-1 and base64, for the WebSocket handshake only ──────────────

fn sha1(data: &[u8]) -> [u8; 20] {
    let mut h: [u32; 5] = [
        0x6745_2301,
        0xEFCD_AB89,
        0x98BA_DCFE,
        0x1032_5476,
        0xC3D2_E1F0,
    ];
    let bit_len = (data.len() as u64) * 8;

    let mut msg = data.to_vec();
    msg.push(0x80);
    while msg.len() % 64 != 56 {
        msg.push(0);
    }
    msg.extend_from_slice(&bit_len.to_be_bytes());

    for chunk in msg.chunks(64) {
        let mut w = [0u32; 80];
        for (i, word) in chunk.chunks(4).enumerate() {
            w[i] = u32::from_be_bytes([word[0], word[1], word[2], word[3]]);
        }
        for i in 16..80 {
            w[i] = (w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16]).rotate_left(1);
        }

        let [mut a, mut b, mut c, mut d, mut e] = h;
        for (i, &wi) in w.iter().enumerate() {
            let (f, k) = match i {
                0..=19 => ((b & c) | (!b & d), 0x5A82_7999u32),
                20..=39 => (b ^ c ^ d, 0x6ED9_EBA1),
                40..=59 => ((b & c) | (b & d) | (c & d), 0x8F1B_BCDC),
                _ => (b ^ c ^ d, 0xCA62_C1D6),
            };
            let tmp = a
                .rotate_left(5)
                .wrapping_add(f)
                .wrapping_add(e)
                .wrapping_add(k)
                .wrapping_add(wi);
            e = d;
            d = c;
            c = b.rotate_left(30);
            b = a;
            a = tmp;
        }
        h[0] = h[0].wrapping_add(a);
        h[1] = h[1].wrapping_add(b);
        h[2] = h[2].wrapping_add(c);
        h[3] = h[3].wrapping_add(d);
        h[4] = h[4].wrapping_add(e);
    }

    let mut out = [0u8; 20];
    for (i, word) in h.iter().enumerate() {
        out[i * 4..i * 4 + 4].copy_from_slice(&word.to_be_bytes());
    }
    out
}

fn base64(data: &[u8]) -> String {
    const ALPHABET: &[u8; 64] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    let mut out = String::new();
    for chunk in data.chunks(3) {
        let b = [
            chunk[0],
            *chunk.get(1).unwrap_or(&0),
            *chunk.get(2).unwrap_or(&0),
        ];
        let n = ((b[0] as u32) << 16) | ((b[1] as u32) << 8) | b[2] as u32;
        out.push(ALPHABET[(n >> 18) as usize & 63] as char);
        out.push(ALPHABET[(n >> 12) as usize & 63] as char);
        out.push(if chunk.len() > 1 {
            ALPHABET[(n >> 6) as usize & 63] as char
        } else {
            '='
        });
        out.push(if chunk.len() > 2 {
            ALPHABET[n as usize & 63] as char
        } else {
            '='
        });
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sha1_matches_known_vectors() {
        assert_eq!(
            sha1(b"abc").to_vec(),
            vec![
                0xa9, 0x99, 0x3e, 0x36, 0x47, 0x06, 0x81, 0x6a, 0xba, 0x3e, 0x25, 0x71, 0x78, 0x50,
                0xc2, 0x6c, 0x9c, 0xd0, 0xd8, 0x9d
            ]
        );
        assert_eq!(
            sha1(b"").to_vec(),
            vec![
                0xda, 0x39, 0xa3, 0xee, 0x5e, 0x6b, 0x4b, 0x0d, 0x32, 0x55, 0xbf, 0xef, 0x95, 0x60,
                0x18, 0x90, 0xaf, 0xd8, 0x07, 0x09
            ]
        );
    }

    #[test]
    fn base64_matches_known_vectors() {
        assert_eq!(base64(b"a"), "YQ==");
        assert_eq!(base64(b"ab"), "YWI=");
        assert_eq!(base64(b"abc"), "YWJj");
    }

    #[test]
    fn handshake_matches_the_rfc_example() {
        // RFC 6455 section 1.3.
        let key = "dGhlIHNhbXBsZSBub25jZQ==";
        let accept = base64(&sha1(
            format!("{key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11").as_bytes(),
        ));
        assert_eq!(accept, "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=");
    }

    #[test]
    fn text_frame_is_unmasked_with_a_short_header() {
        assert_eq!(text_frame("reload"), b"\x81\x06reload".to_vec());
    }
}
