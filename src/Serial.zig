const micro = @import("microzig");

const std = @import("std");

const SerialError = error{SerialNotBegun};

// The UART object provided by microzig. This could be returned but trying
// to closely mimic Arduino library which doesn't need a separate variable
// to hold a Serial object.
pub const uart = blk: {
    const uart_ty = micro.uart.Uart(0, .{});
    comptime var self: ?uart_ty = null;
    const result = struct {
        fn begin(comptime baud: u32) !void {
            self = try micro.Uart(0, .{}).init(.{
                .baud_rate = baud,
                .stop_bits = .one,
                .parity = null,
                .data_bits = .eight,
            });
        }

        fn get() SerialError!uart_ty {
            return self orelse SerialError.SerialNotBegun;
        }
    };

    break :blk result;
};

pub fn begin(comptime baud: u32) !void {
    try uart.begin(baud);
}

pub fn write(bytes: []const u8) !void {
    const uart_instance = try uart.get();
    const writer = uart_instance.writer();
    try writer.writeAll(bytes);
}

// All print* functions are the overloaded print functions in Arduino
pub fn printString(string: []const u8) !void {
    try write(string);
}

pub fn printNum(num: u32, base: u8) !void {
    // Just be safe I guess
    var buf = [_]u8{0} ** 33;
    // Neither this nor using the writer directly work too well...
    _ = std.fmt.formatIntBuf(&buf, num, base, .lower, .{});
    try write(&buf);
}

// TODO: This doesn't seem to work. :(
pub fn readString() ![]u8 {
    // For now just max out read length at 10
    const uart_instance = try uart.get();
    const reader = uart_instance.reader();
    var buf = [_]u8{0} ** 10;
    _ = try reader.read(&buf);
    return &buf;
}
