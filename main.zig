const std = @import("std");
const aout = @import("a.out.zig");
const sects_names = aout.sects_names;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = &gpa.allocator;
    const buf = try std.fs.cwd().readFileAlloc(allocator, "out/6.out", std.math.maxInt(usize));
    defer allocator.free(buf);

    var stream = std.io.FixedBufferStream([]const u8){ .buffer = buf, .pos = 0 };
    const r = stream.reader();

    var f: File = undefined;
    f.hdr = try getHeader(&r);

    testHeaderSize(f.hdr, buf);

    var off: u32 = @sizeOf(aout.Exec);

    inline for (sects_names) |name, i| {
        const size = @field(f.hdr, name);
        var sl = buf[off .. off + size];
        f.sects[i] = .{ .name = name, .data = sl };
        off += size;
    }
    std.debug.print("f: {}\n", .{f});
    const syms = try readSyms(allocator, f.sects[2].data);
    defer allocator.free(syms);
    std.debug.print("syms: {any}", .{syms});
}

fn testHeaderSize(h: aout.Exec, b: []const u8) void {
    const size_from_h = @sizeOf(aout.Exec) + h.text + h.data + h.syms + h.spsz + h.pcsz;
    const size_from_b = b.len;
    if (size_from_h != size_from_b) {
        std.debug.print("===ASSERTION FAILED: size from header {d} != size from buf {d}===\n", .{
            size_from_h,
            size_from_b,
        });
    }
}

pub fn readSyms(ally: *std.mem.Allocator, sym_sec: []const u8) ![]const aout.Sym {
    var l = std.ArrayList(aout.Sym).init(ally);
    var stream = std.io.FixedBufferStream([]const u8){ .buffer = sym_sec, .pos = 0 };
    const r = stream.reader();
    while (true) {
        var s: aout.Sym = undefined;
        s.value = r.readBytesNoEof(4) catch break;
        s.type = try aout.SymType.fromU8(r.readByte() catch break);
        s.name = std.mem.span(@ptrCast([*:0]const u8, stream.buffer[stream.pos..].ptr));
        try l.append(s);
    }
    return l.toOwnedSlice();
}

pub fn getHeader(r: anytype) !aout.Exec {
    var h: aout.Exec = undefined;
    inline for (std.meta.fields(aout.Exec)) |f| {
        @field(h, f.name) = try r.readIntBig(u32);
    }
    return h;
}

// A File represents an open Plan 9 a.out file.
const File = struct {
    hdr: aout.Exec,
    sects: [5]Section,
};

// A Section represents a single section in a Plan 9 a.out file.
const Section = struct {
    name: []const u8,
    /// the data of the section
    data: []const u8,
    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, out_stream: anytype) !void {
        try std.fmt.format(out_stream, "\nSection {{ name: {s}, ", .{self.name});
        try std.fmt.format(out_stream, "data: {any} }}", .{std.fmt.fmtSliceHexLower(self.data)});
    }
};
// // TODO make this in std.meta or make proposal for inclusion in language?
// pub fn makeSlice(comptime T: type, s: struct { len: usize, ptr: [*]const T }) []const T {
// var sl: []const T = undefined;
// sl.ptr = s.ptr;
// sl.len = s.len;
// return sl;
// }
