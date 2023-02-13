const gpio = @import("gpio.zig");
const pins = @import("pins.zig");
const time = @import("time.zig");

pub fn main() void {
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
