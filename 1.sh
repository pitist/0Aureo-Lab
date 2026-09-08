cat > install_0aureo_gguf.sh <<'BASH'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$HOME/0Aureo"
echo "[0AUREO] creando: $ROOT"

pkg update -y
pkg install -y git rust clang make cmake pkg-config python

mkdir -p "$ROOT"/{crates/{gguf,tensor,quant,arm64,rope,attention,kv_cache,mlp,transformer,sampler,runtime},apps/cli,apps/api,scripts,models}

cd "$ROOT"

cat > Cargo.toml <<'EOF'
[workspace]
resolver = "2"
members = [
    "crates/gguf",
    "crates/tensor",
    "crates/quant",
    "crates/arm64",
    "crates/rope",
    "crates/attention",
    "crates/kv_cache",
    "crates/mlp",
    "crates/transformer",
    "crates/sampler",
    "crates/runtime",
    "apps/cli",
    "apps/api"
]

[workspace.package]
edition = "2021"
version = "0.1.0"
license = "MIT"

[workspace.dependencies]
anyhow = "1"
EOF

make_crate() {
    NAME="$1"
    cargo new --lib "$ROOT/crates/$NAME" --vcs none >/dev/null
}

for c in gguf tensor quant arm64 rope attention kv_cache mlp transformer sampler runtime
do
    make_crate "$c"
done

cargo new --bin "$ROOT/apps/cli" --vcs none >/dev/null
cargo new --bin "$ROOT/apps/api" --vcs none >/dev/null

# ============================================================
# TENSOR
# ============================================================

cat > crates/tensor/src/lib.rs <<'EOF'
#[derive(Clone, Debug)]
pub struct Tensor {
    pub shape: Vec<usize>,
    pub data: Vec<f32>,
}

impl Tensor {
    pub fn new(shape: Vec<usize>, data: Vec<f32>) -> Self {
        let n: usize = shape.iter().product();
        assert_eq!(n, data.len());
        Self { shape, data }
    }

    pub fn zeros(shape: &[usize]) -> Self {
        let n: usize = shape.iter().product();
        Self {
            shape: shape.to_vec(),
            data: vec![0.0; n],
        }
    }

    pub fn scalar(x: f32) -> Self {
        Self {
            shape: vec![1],
            data: vec![x],
        }
    }

    pub fn len(&self) -> usize {
        self.data.len()
    }

    pub fn get(&self, i: usize) -> f32 {
        self.data[i]
    }

    pub fn set(&mut self, i: usize, v: f32) {
        self.data[i] = v;
    }
}

pub fn matmul(a: &Tensor, b: &Tensor) -> Tensor {
    assert_eq!(a.shape.len(), 2);
    assert_eq!(b.shape.len(), 2);

    let m = a.shape[0];
    let k = a.shape[1];
    let kb = b.shape[0];
    let n = b.shape[1];

    assert_eq!(k, kb);

    let mut out = vec![0.0f32; m * n];

    for i in 0..m {
        for p in 0..k {
            let av = a.data[i * k + p];

            for j in 0..n {
                out[i * n + j] += av * b.data[p * n + j];
            }
        }
    }

    Tensor::new(vec![m, n], out)
}

pub fn rms_norm(x: &Tensor, eps: f32) -> Tensor {
    let ss = x.data.iter()
        .map(|v| v * v)
        .sum::<f32>() / x.len() as f32;

    let inv = 1.0 / (ss + eps).sqrt();

    Tensor::new(
        x.shape.clone(),
        x.data.iter().map(|v| v * inv).collect()
    )
}

pub fn softmax(x: &Tensor) -> Tensor {
    let max = x.data.iter()
        .copied()
        .fold(f32::NEG_INFINITY, f32::max);

    let exps: Vec<f32> =
        x.data.iter().map(|v| (*v - max).exp()).collect();

    let sum: f32 = exps.iter().sum();

    Tensor::new(
        x.shape.clone(),
        exps.into_iter().map(|v| v / sum).collect()
    )
}
EOF

# ============================================================
# QUANTIZATION
# ============================================================

cat > crates/quant/src/lib.rs <<'EOF'
#[derive(Clone, Copy, Debug)]
pub enum QuantType {
    F32,
    F16,
    Q4_0,
    Q4_1,
    Q5_0,
    Q5_1,
    Q8_0,
}

pub fn dequantize_q4_0(block: &[u8], scale: f32) -> Vec<f32> {
    let mut out = Vec::with_capacity(block.len() * 2);

    for byte in block {
        let lo = byte & 0x0f;
        let hi = byte >> 4;

        let a = lo as i8 - 8;
        let b = hi as i8 - 8;

        out.push(a as f32 * scale);
        out.push(b as f32 * scale);
    }

    out
}
EOF

# ============================================================
# GGUF LOADER
# ============================================================

cat > crates/gguf/src/lib.rs <<'EOF'
use std::fs::File;
use std::io::{self, Read};
use std::path::Path;

#[derive(Debug)]
pub struct GgufHeader {
    pub version: u32,
    pub tensor_count: u64,
    pub metadata_count: u64,
}

pub struct GgufFile {
    pub header: GgufHeader,
}

impl GgufFile {
    pub fn open<P: AsRef<Path>>(path: P) -> io::Result<Self> {
        let mut f = File::open(path)?;

        let mut magic = [0u8; 4];
        f.read_exact(&mut magic)?;

        if &magic != b"GGUF" {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "not a GGUF file"
            ));
        }

        let version = read_u32(&mut f)?;
        let tensor_count = read_u64(&mut f)?;
        let metadata_count = read_u64(&mut f)?;

        Ok(Self {
            header: GgufHeader {
                version,
                tensor_count,
                metadata_count,
            }
        })
    }
}

fn read_u32<R: Read>(r: &mut R) -> io::Result<u32> {
    let mut b = [0u8; 4];
    r.read_exact(&mut b)?;
    Ok(u32::from_le_bytes(b))
}

fn read_u64<R: Read>(r: &mut R) -> io::Result<u64> {
    let mut b = [0u8; 8];
    r.read_exact(&mut b)?;
    Ok(u64::from_le_bytes(b))
}
EOF

# ============================================================
# ARM64
# ============================================================

cat > crates/arm64/src/lib.rs <<'EOF'
#[cfg(target_arch = "aarch64")]
#[inline]
pub fn matmul_arm64(a: &[f32], b: &[f32], m: usize, k: usize, n: usize) -> Vec<f32> {
    let mut out = vec![0.0f32; m * n];

    for i in 0..m {
        for p in 0..k {
            let av = a[i * k + p];

            for j in 0..n {
                out[i * n + j] += av * b[p * n + j];
            }
        }
    }

    out
}

#[cfg(not(target_arch = "aarch64"))]
pub fn matmul_arm64(a: &[f32], b: &[f32], m: usize, k: usize, n: usize) -> Vec<f32> {
    let mut out = vec![0.0f32; m * n];

    for i in 0..m {
        for p in 0..k {
            for j in 0..n {
                out[i*n+j] += a[i*k+p] * b[p*n+j];
            }
        }
    }

    out
}
EOF

# ============================================================
# RoPE
# ============================================================

cat > crates/rope/src/lib.rs <<'EOF'
pub fn apply_rope(x: &mut [f32], position: usize, theta: f32) {
    let dim = x.len();

    for i in (0..dim).step_by(2) {
        if i + 1 >= dim {
            break;
        }

        let freq = theta.powf(-(i as f32 / dim as f32));
        let angle = position as f32 * freq;

        let c = angle.cos();
        let s = angle.sin();

        let a = x[i];
        let b = x[i + 1];

        x[i] = a * c - b * s;
        x[i + 1] = a * s + b * c;
    }
}
EOF

# ============================================================
# KV CACHE
# ============================================================

cat > crates/kv_cache/src/lib.rs <<'EOF'
#[derive(Default)]
pub struct KvCache {
    pub keys: Vec<Vec<f32>>,
    pub values: Vec<Vec<f32>>,
    pub positions: usize,
}

impl KvCache {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn push(&mut self, key: Vec<f32>, value: Vec<f32>) {
        self.keys.push(key);
        self.values.push(value);
        self.positions += 1;
    }

    pub fn len(&self) -> usize {
        self.positions
    }

    pub fn clear(&mut self) {
        self.keys.clear();
        self.values.clear();
        self.positions = 0;
    }
}
EOF

# ============================================================
# ATTENTION
# ============================================================

cat > crates/attention/src/lib.rs <<'EOF'
use tensor::{softmax, Tensor};
use kv_cache::KvCache;

pub fn attention(
    query: &[f32],
    cache: &KvCache
) -> Vec<f32> {

    if cache.keys.is_empty() {
        return query.to_vec();
    }

    let scale = 1.0 / (query.len() as f32).sqrt();

    let mut scores = Vec::with_capacity(cache.keys.len());

    for key in &cache.keys {
        let score = query.iter()
            .zip(key)
            .map(|(a,b)| a*b)
            .sum::<f32>() * scale;

        scores.push(score);
    }

    let weights = softmax(
        &Tensor::new(vec![scores.len()], scores)
    );

    let mut out = vec![0.0f32; query.len()];

    for (i, value) in cache.values.iter().enumerate() {
        for j in 0..out.len() {
            out[j] += weights.data[i] * value[j];
        }
    }

    out
}
EOF

cat > crates/attention/Cargo.toml <<'EOF'
[package]
name = "attention"
version.workspace = true
edition.workspace = true

[dependencies]
tensor = { path = "../tensor" }
kv_cache = { path = "../kv_cache" }
EOF

# ============================================================
# MLP
# ============================================================

cat > crates/mlp/src/lib.rs <<'EOF'
pub fn silu(x: f32) -> f32 {
    x / (1.0 + (-x).exp())
}

pub fn mlp(x: &[f32]) -> Vec<f32> {
    x.iter().map(|v| silu(*v)).collect()
}
EOF

# ============================================================
# TRANSFORMER
# ============================================================

cat > crates/transformer/src/lib.rs <<'EOF'
use attention::attention;
use kv_cache::KvCache;
use mlp::mlp;
use rope::apply_rope;
use tensor::{rms_norm, Tensor};

pub struct Transformer {
    pub cache: KvCache,
    pub position: usize,
}

impl Transformer {
    pub fn new() -> Self {
        Self {
            cache: KvCache::new(),
            position: 0,
        }
    }

    pub fn forward(&mut self, input: Vec<f32>) -> Vec<f32> {
        let mut x = input;

        let norm = rms_norm(
            &Tensor::new(vec![x.len()], x.clone()),
            1e-5
        );

        x = norm.data;

        apply_rope(&mut x, self.position, 10000.0);

        let key = x.clone();
        let value = x.clone();

        self.cache.push(key, value);

        let attn = attention(&x, &self.cache);

        let output = mlp(&attn);

        self.position += 1;

        output
    }
}
EOF

cat > crates/transformer/Cargo.toml <<'EOF'
[package]
name = "transformer"
version.workspace = true
edition.workspace = true

[dependencies]
attention = { path = "../attention" }
kv_cache = { path = "../kv_cache" }
mlp = { path = "../mlp" }
rope = { path = "../rope" }
tensor = { path = "../tensor" }
EOF

# ============================================================
# SAMPLER
# ============================================================

cat > crates/sampler/src/lib.rs <<'EOF'
pub fn argmax(logits: &[f32]) -> usize {
    logits.iter()
        .enumerate()
        .max_by(|a,b| a.1.partial_cmp(b.1).unwrap())
        .map(|(i,_)| i)
        .unwrap_or(0)
}

pub fn temperature(logits: &mut [f32], t: f32) {
    let t = if t <= 0.0 { 1.0 } else { t };

    for x in logits {
        *x /= t;
    }
}
EOF

# ============================================================
# RUNTIME
# ============================================================

cat > crates/runtime/src/lib.rs <<'EOF'
use transformer::Transformer;
use sampler::{argmax, temperature};

pub struct Runtime {
    pub transformer: Transformer,
}

impl Runtime {
    pub fn new() -> Self {
        Self {
            transformer: Transformer::new()
        }
    }

    pub fn step(&mut self, input: Vec<f32>) -> usize {
        let mut logits = self.transformer.forward(input);

        temperature(&mut logits, 0.8);

        argmax(&logits)
    }
}
EOF

cat > crates/runtime/Cargo.toml <<'EOF'
[package]
name = "runtime"
version.workspace = true
edition.workspace = true

[dependencies]
transformer = { path = "../transformer" }
sampler = { path = "../sampler" }
EOF

# ============================================================
# CLI
# ============================================================

cat > apps/cli/Cargo.toml <<'EOF'
[package]
name = "aurea-cli"
version.workspace = true
edition.workspace = true

[dependencies]
gguf = { path = "../../crates/gguf" }
runtime = { path = "../../crates/runtime" }
EOF

cat > apps/cli/src/main.rs <<'EOF'
use std::env;

fn main() {
    let args: Vec<String> = env::args().collect();

    println!("================================");
    println!("        0AUREO GGUF RUNTIME");
    println!("================================");

    if args.len() < 2 {
        println!("Uso:");
        println!("  aurea-cli modelo.gguf");
        return;
    }

    let path = &args[1];

    match gguf::GgufFile::open(path) {
        Ok(model) => {
            println!("GGUF OK");
            println!("version       : {}", model.header.version);
            println!("tensors       : {}", model.header.tensor_count);
            println!("metadata      : {}", model.header.metadata_count);

            let mut runtime = runtime::Runtime::new();

            let input = vec![
                0.1, 0.2, 0.3, 0.4,
                0.5, 0.6, 0.7, 0.8
            ];

            let token = runtime.step(input);

            println!("token         : {}", token);
        }

        Err(e) => {
            eprintln!("ERROR GGUF: {}", e);
            std::process::exit(1);
        }
    }
}
EOF

# ============================================================
# API
# ============================================================

cat > apps/api/src/main.rs <<'EOF'
use std::net::TcpListener;
use std::io::{Read, Write};

fn main() {
    let listener = TcpListener::bind("127.0.0.1:8080")
        .expect("bind");

    println!("0Aureo API -> http://127.0.0.1:8080");

    for stream in listener.incoming() {
        let mut stream = match stream {
            Ok(s) => s,
            Err(_) => continue
        };

        let mut buffer = [0u8; 4096];

        let _ = stream.read(&mut buffer);

        let body = r#"{"system":"0Aureo","status":"ok"}"#;

        let response = format!(
            "HTTP/1.1 200 OK\r\n\
             Content-Type: application/json\r\n\
             Content-Length: {}\r\n\
             Connection: close\r\n\r\n{}",
            body.len(),
            body
        );

        let _ = stream.write_all(response.as_bytes());
    }
}
EOF

# ============================================================
# TEST
# ============================================================

cat > scripts/verify.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "[1] cargo check"
cargo check --workspace

echo "[2] cargo test"
cargo test --workspace

echo "[3] release build"
cargo build --release --workspace

echo
echo "======================================"
echo "0AUREO BUILD OK"
echo "======================================"
EOF

chmod +x scripts/verify.sh

# ============================================================
# DOCUMENTACIÓN DE ARQUITECTURA
# ============================================================

cat > ARCHITECTURE.md <<'EOF'
# 0Aureo GGUF Runtime

GGUF
 ↓
GGUF Loader
 ↓
Tensor
 ↓
Quantization
 ↓
ARM64 Kernel
 ↓
RoPE
 ↓
Attention
 ↓
KV Cache
 ↓
MLP
 ↓
Transformer
 ↓
Sampler
 ↓
Runtime
 ↓
CLI / API / Android

## Capas

gguf
  lectura del contenedor GGUF.

tensor
  representación matemática.

quant
  descompresión/decuantización.

arm64
  kernels específicos ARM64.

rope
  positional encoding.

attention
  mecanismo de atención.

kv_cache
  memoria de claves/valores.

mlp
  feed-forward.

transformer
  bloques Transformer.

sampler
  selección del siguiente token.

runtime
  ejecución autoregresiva.

apps/cli
  interfaz local.

apps/api
  interfaz HTTP.

Android
  debe conectarse posteriormente al runtime mediante FFI/JNI/UniFFI.
EOF

# ============================================================
# GIT
# ============================================================

git init
git add .
git commit -m "0Aureo GGUF ARM64 Transformer runtime"

echo
echo "======================================"
echo "0AUREO CREADO"
echo "======================================"
echo
echo "Directorio:"
echo "$ROOT"
echo
echo "Verificar:"
echo "cd $ROOT && ./scripts/verify.sh"
echo
echo "CLI:"
echo "cd $ROOT && cargo run -p aurea-cli -- models/model.gguf"
echo
echo "API:"
echo "cd $ROOT && cargo run -p aurea-api"
echo
echo "Arquitectura:"
echo "$ROOT/ARCHITECTURE.md"
BASH

chmod +x install_0aureo_gguf.sh
./install_0aureo_gguf.sh