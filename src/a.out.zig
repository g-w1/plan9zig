//! Idomatic translation of a.out.h
const std = @import("std");
pub usingnamespace @import("std").zig.c_builtins;
pub const ushort = c_ushort;
pub const uchar = u8;
pub const ulong = c_ulong;
pub const uint = c_uint;
pub const schar = i8;
pub const vlong = c_longlong;
pub const Exec = extern struct {
    magic: u32,
    text: u32,
    data: u32,
    bss: u32,
    syms: u32,
    entry: u32,
    spsz: u32,
    pcsz: u32,
};

// uchar value[4];
// char  type;
// char  name[n];   /* NUL-terminated */
pub const Sym = struct {
    value: [8]u8,
    type: SymType,
    name: []const u8,
    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, out_stream: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(out_stream, "Sym {{ .name = \"{s}\", .value = {any}, .type = {}, }}", .{ self.name, self.value, self.type });
    }
};
// The type field is one of the following characters with the
// high bit set:
// T    text segment symbol
// t    static text segment symbol
// L    leaf function text segment symbol
// l    static leaf function text segment symbol
// D    data segment symbol
// d    static data segment symbol
// B    bss segment symbol
// b    static bss segment symbol
// a    automatic (local) variable symbol
// p    function parameter symbol
// f    source file name components
// z    source file name
// Z    source file line offset
// m for '.frame' not sure what its for
pub const SymType = enum(u8) {
    T = 0x80 | 'T',
    t = 0x80 | 't',
    L = 0x80 | 'L',
    l = 0x80 | 'l',
    D = 0x80 | 'D',
    d = 0x80 | 'd',
    B = 0x80 | 'B',
    b = 0x80 | 'b',
    a = 0x80 | 'a',
    p = 0x80 | 'p',
    f = 0x80 | 'f',
    z = 0x80 | 'z',
    Z = 0x80 | 'Z',
    m = 0x80 | 'm',
    _,
    pub fn fromU8(cr: u8) !@This() {
        const c = @as(@This(), @enumFromInt(cr));
        return switch (c) {
            .T => c,
            .t => c,
            .L => c,
            .l => c,
            .D => c,
            .d => c,
            .B => c,
            .b => c,
            .a => c,
            .p => c,
            .f => c,
            .z => c,
            .Z => c,
            .m => c,
            _ => {
                std.log.err("NotSym: {d} is not a symbol", .{cr});
                return error.NotSym;
            },
        };
    }
};

pub const HDR_MAGIC = 0x00008000;
pub inline fn _MAGIC(f: anytype, b: anytype) @TypeOf(f | ((((@as(c_int, 4) * b) + @as(c_int, 0)) * b) + @as(c_int, 7))) {
    return f | ((((@as(c_int, 4) * b) + @as(c_int, 0)) * b) + @as(c_int, 7));
}
pub const A_MAGIC = _MAGIC(@as(c_int, 0), @as(c_int, 8));
pub const I_MAGIC = _MAGIC(@as(c_int, 0), @as(c_int, 11));
pub const J_MAGIC = _MAGIC(@as(c_int, 0), @as(c_int, 12));
pub const K_MAGIC = _MAGIC(@as(c_int, 0), @as(c_int, 13));
pub const V_MAGIC = _MAGIC(@as(c_int, 0), @as(c_int, 16));
pub const X_MAGIC = _MAGIC(@as(c_int, 0), @as(c_int, 17));
pub const M_MAGIC = _MAGIC(@as(c_int, 0), @as(c_int, 18));
pub const D_MAGIC = _MAGIC(@as(c_int, 0), @as(c_int, 19));
pub const E_MAGIC = _MAGIC(@as(c_int, 0), @as(c_int, 20));
pub const Q_MAGIC = _MAGIC(@as(c_int, 0), @as(c_int, 21));
pub const N_MAGIC = _MAGIC(@as(c_int, 0), @as(c_int, 22));
pub const L_MAGIC = _MAGIC(@as(c_int, 0), @as(c_int, 23));
pub const P_MAGIC = _MAGIC(@as(c_int, 0), @as(c_int, 24));
pub const U_MAGIC = _MAGIC(@as(c_int, 0), @as(c_int, 25));
// #define	S_MAGIC		_MAGIC(HDR_MAGIC, 26)	/* amd64 */
pub const S_MAGIC = _MAGIC(HDR_MAGIC, @as(c_int, 26));
pub const T_MAGIC = _MAGIC(HDR_MAGIC, @as(c_int, 27));
pub const R_MAGIC = _MAGIC(HDR_MAGIC, @as(c_int, 28));
pub const MIN_MAGIC = @as(c_int, 8);
pub const MAX_MAGIC = @as(c_int, 28);
pub const DYN_MAGIC = 0x80000000;

pub const sects_names = [5][]const u8{
    "text",
    "data",
    "syms",
    "spsz",
    "pcsz",
};
