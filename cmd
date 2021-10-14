vim main.zig;zig build-exe main.zig&&DISASM=1 ./main ~/dev/zig/build-release/x | ndisasm -b64 - | less
