const board = @import("microzig").board;
const regs = @import("microzig").chip.registers;

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
