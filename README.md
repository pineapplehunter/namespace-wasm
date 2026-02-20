# Wasm in bubblewrap example using Nix

## Experiments
Read flake.nix to see how bwrap is used.

### Run wasm application in namespace
This will run the wasm application defined in `main.c` with wasmtime.
There will only be wasmtime binary and the built wasm binary in the namespace.

```bash
$ nix run
```

### Run a bash shell in namespace
This opens a shell inside the namespace. It only includes bash and coreutils in the namespace.

```bash
$ nix run .#debug
```
