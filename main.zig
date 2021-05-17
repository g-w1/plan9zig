const aout = @import("a.out.zig");
pub fn main() void {
    const Hrd: aout.Exec = .{
        .magic = aout.S_MAGIC,
        .text = 10,
        .data = 10,
        .bss = 10,
        .syms = 10,
        .entry = 0x40,
        .spsz = 0,
        .pcsz = 0,
    };
}
