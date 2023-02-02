const board = @import("microzig").board;
const regs = @import("microzig").chip.registers;
const std = @import("std");

pub fn begin(comptime baud: comptime_int) void {
    // From Arduino HardwareSerial begin method, kinda
    regs.USART0.UBRR0.modify((board.clock_frequencies.cpu / 4 / baud - 1) / 2);
    regs.USART0.UCSR0A.modify(.{ .U2X0 = 1 });
    regs.USART0.UCSR0B.modify(.{ .TXEN0 = 1 });
}

// Maybe public?
fn write(data: u8) void {
    // Data register gets data sent to it then it clears.
    // Make sure it's empty before sending to I/O register.
    while (regs.USART0.UCSR0A.read().UDRE0 == 0) {}

    // Send to I/O register.
    regs.USART0.UDR0.* = data;
}

pub fn println(data: []const u8) u32 {
    var n = print(data);
    n += print("\n");
    return n;
}

pub fn print(data: []const u8) u32 {
    var n: u32 = 0;
    for (data) |ch| {
        write(ch);
        n += 1;
    }

    while (regs.USART0.UCSR0A.read().TXC0 == 0) {}

    return n;
}

pub fn printNum(n: i64, base: u8) u32 {
    var mut_base = base;
    // TODO probably handle this not just default to 0
    var mut_n = std.math.absInt(n) catch 0;
    var t: u32 = 0;

    if (mut_base < 2) {
        mut_base = 10;
    }

    // Only print negative sign for base 10
    if (mut_base == 10 and n < 0) {
        t += print("-");
    }

    // TODO: Turns out we can only have 8 digits before linker errors
    // because no memset
    var buf = [_]u8{
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
    };
    var i = buf.len - 1;

    while (true) {
        i -= 1;
        const c: u8 = @intCast(u8, @rem(mut_n, mut_base));
        mut_n = @divTrunc(mut_n, mut_base);
        buf[i] = std.fmt.digitToChar(c, .upper);

        if (mut_n == 0) break;
    }

    return print(buf[i..buf.len]) + t;
}
