const gpio = @import("gpio.zig");
const pins = @import("pins.zig");
const time = @import("time.zig");
const Serial = @import("Serial.zig");

const std = @import("std");

pub fn main() !void {
    try Serial.begin(115200);
    try Serial.write("Hi there");
    const read = try Serial.readString();
    var buf = [_]u8{0} ** 10;
    _ = std.fmt.formatIntBuf(&buf, @intCast(u32, read[0]), 10, .upper, .{});
    try Serial.write(&buf);

    time.init();
    // Onboard LED
    gpio.pinMode(10, .out);
    while (true) {
        gpio.analogWrite(10, 100);
        time.delay(1000);
        gpio.analogWrite(10, 200);
        time.delay(1000);
    }
}

// Interrupt stuff in root for timer
pub const interrupts = struct {
    pub fn TIMER0_OVF() void {
        // Dunno if we need locals like in Arduino standard library to keep in
        // registers. But I'll do it anyway
        var m = time.timer0_millis;
        var f = time.timer0_fract;

        m += time.millis_inc;
        f += time.fract_inc;
        if (f >= time.fract_max) {
            f -= time.fract_max;
            m += 1;
        }

        time.timer0_fract = f;
        time.timer0_millis = m;
        time.timer0_overflow_count += 1;
    }
};
