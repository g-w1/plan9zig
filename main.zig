const std = @import("std");
const aout = @import("a.out.zig");
const sects_names = aout.sects_names;

var hmap: std.AutoHashMap(u64, []const u8) = undefined;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = &gpa.allocator;
    const buf = try std.fs.cwd().readFileAlloc(allocator, std.mem.span(std.os.argv[1]), std.math.maxInt(usize));
    defer allocator.free(buf);

    hmap = std.AutoHashMap(u64, []const u8).init(allocator);
    defer hmap.deinit();

    var stream = std.io.FixedBufferStream([]const u8){ .buffer = buf, .pos = 0 };
    const r = stream.reader();

    var f: File = undefined;
    f.hdr = try getHeader(&r);

    try testHeaderSize(f.hdr, buf);

    var off: u32 = @sizeOf(aout.Exec);

    if (f.hdr.magic & aout.HDR_MAGIC != 0) // weird extension thing
        off += 8;

    inline for (sects_names) |name, i| {
        const size = @field(f.hdr, name);
        var sl = buf[off .. off + size];
        f.sects[i] = .{ .name = name, .data = sl };
        off += size;
    }
    // disassemble
    if (std.os.getenv("DISASM") != null) {
        // var cp = try std.ChildProcess.init(&.{ "ndisasm", "-" }, allocator);
        // defer cp.deinit();
        // cp.stdin_behavior = .Pipe;
        // try cp.spawn();
        // try cp.stdin.?.writeAll(f.sects[0].data);
        // _ = try cp.wait();
        try std.io.getStdOut().writeAll(f.sects[0].data);
        return;
    }

    std.log.info("file: {}", .{f});
    const syms = try readSyms(allocator, f.sects[2].data);
    defer allocator.free(syms);
    std.log.info("syms: {any}", .{syms});

    if (std.os.argv.len == 3) {
        const symname = std.mem.span(std.os.argv[2]);

        try getLineFromSym(allocator, syms, symname, f.sects[4].data);
    }
}

fn testHeaderSize(h: aout.Exec, b: []const u8) !void {
    const ext_off: u32 = if (h.magic & aout.HDR_MAGIC != 0) 8 else 0;
    const size_from_h = @sizeOf(aout.Exec) + h.text + h.data + h.syms + h.spsz + h.pcsz + ext_off;
    const size_from_b = b.len;
    if (size_from_h != size_from_b) {
        std.log.emerg("===Header size doesn't match: size from header {d} != size from buf {d}===\n", .{
            size_from_h,
            size_from_b,
        });
        return error.HeaderSizeNoMatch;
    }
}

pub fn readSyms(ally: *std.mem.Allocator, sym_sec: []const u8) ![]const aout.Sym {
    var l = std.ArrayList(aout.Sym).init(ally);
    errdefer l.deinit();
    var stream = std.io.FixedBufferStream([]const u8){ .buffer = sym_sec, .pos = 0 };
    const r = stream.reader();
    while (true) {
        var s: aout.Sym = undefined;
        s.value = r.readBytesNoEof(8) catch break; // TODO this should be 4 for 32 bit systems and 8 for 64. Include this in the manpage patch too!
        std.log.info("==\ns.value = {any}", .{std.fmt.fmtSliceHexLower(&s.value)});
        s.type = try aout.SymType.fromU8(r.readByte() catch break);
        std.log.info("s.type: {}", .{s.type});

        switch (s.type) {
            .f => {
                s.name = std.mem.span(@ptrCast([*:0]const u8, stream.buffer[stream.pos..].ptr));
                stream.pos += s.name.len + 1;
                try hmap.put(std.mem.readIntBig(u64, &s.value), s.name);
            },
            .z => {
                const b = try r.readByte();
                if (b != 0) return error.ZeroNoFollowz;
                const st = stream.pos;
                var e: usize = 0;
                while (true) {
                    if ((r.readIntBig(u16) catch return error.ZeroNoEndz) == 0) {
                        e = stream.pos - 2;
                        break;
                    }
                }
                s.name = stream.buffer[st..e];
                std.log.info("Z NAME: {any}", .{s.name});
            },
            .Z => {
                const b = try r.readByte();
                if (b != 0) return error.ZeroNoFollowZ;
                while (true) {
                    if ((r.readIntBig(u16) catch break) == 0) break; // TODO actually handle it
                }
                s.name = "TODO: name for Z";
            },
            else => {
                s.name = std.mem.span(@ptrCast([*:0]const u8, stream.buffer[stream.pos..].ptr));
                stream.pos += s.name.len + 1;
            },
        }

        std.log.info("s.name: \"{s}\"({d})", .{ s.name, s.name.len });

        try l.append(s);
    }
    return l.toOwnedSlice();
}

/// return is filename:line
fn getLineFromSym(a: *std.mem.Allocator, syms: []const aout.Sym, sym: []const u8, linebuf: []const u8) !void {
    var prevzidxo: ?usize = null;
    const symidx = for (syms) |s, i| {
        if (s.type == .z and syms[i - 1].type != .z and syms[i - 1].type != .Z) {
            prevzidxo = i;
        }
        if (std.mem.eql(u8, sym, s.name)) {
            break i;
        }
    } else return error.SymNotFound;
    const prevzidx = prevzidxo orelse return error.NoFName;
    const z = syms[prevzidx];
    std.log.info("z: {}", .{z});
    const name = try getNameFromz(a, z.name);
    defer a.free(name);

    const symval = std.mem.readIntBig(u64, &syms[symidx].value);
    std.log.info("value for {s}: {x}", .{ sym, symval });
    const pcquant = 1;
    var lc: i64 = 0;
    var curpc: usize = 0x200028 - pcquant;
    const reader = std.io.fixedBufferStream(linebuf).reader();
    while (true) {
        if (curpc >= symval) break;
        var u = reader.readByte() catch break;
        if (u == 0)
            lc += try reader.readIntBig(i32)
        else if (u < 65)
            lc += u
        else if (u < 129)
            lc -= (u - 64)
        else
            curpc += (u - 129) * pcquant;
        curpc += pcquant;
        std.log.debug("after: {d}", .{lc});
    }
    std.log.info("file from {s}: `{s}:{d}`", .{
        sym,
        name,
        lc,
    });
}

// returns allocated slice
fn getNameFromz(a: *std.mem.Allocator, b: []const u8) ![]const u8 {
    var ar = std.ArrayList(u8).init(a);
    const r = std.io.fixedBufferStream(b).reader();
    var i: u16 = 0;
    while (true) : (i += 1) {
        const v = r.readIntBig(u16) catch {
            _ = ar.pop();
            return ar.toOwnedSlice();
        };
        try ar.appendSlice(hmap.get(v).?);
        if (i != 0) {
            try ar.append('/');
        }
    }
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
        _ = fmt;
        _ = options;
        try std.fmt.format(out_stream, "\nSection {{ .name = {s}, ", .{self.name});
        try std.fmt.format(out_stream, ".data = {s} }}", .{std.fmt.fmtSliceHexLower(self.data)});
    }
};
