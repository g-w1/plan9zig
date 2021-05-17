pub usingnamespace @import("std").c.builtins;
pub const ushort = c_ushort;
pub const uchar = u8;
pub const ulong = c_ulong;
pub const uint = c_uint;
pub const schar = i8;
pub const vlong = c_longlong;
pub const struct_Exec = extern struct {
    magic: c_long,
    text: c_long,
    data: c_long,
    bss: c_long,
    syms: c_long,
    entry: c_long,
    spsz: c_long,
    pcsz: c_long,
};
pub const Exec = struct_Exec;
pub const struct_Sym = extern struct {
    value: vlong,
    sig: uint,
    type: u8,
    name: [*c]u8,
};
pub const Sym = struct_Sym;
pub const HDR_MAGIC = @import("std").meta.promoteIntLiteral(c_int, 0x00008000, .hexadecimal);
pub fn _MAGIC(f: anytype, b: anytype) callconv(.Inline) @TypeOf(f | ((((@as(c_int, 4) * b) + @as(c_int, 0)) * b) + @as(c_int, 7))) {
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
pub const DYN_MAGIC = @import("std").meta.promoteIntLiteral(c_int, 0x80000000, .hexadecimal);
