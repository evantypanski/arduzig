const gpio = @import("gpio.zig");
const pins = @import("pins.zig");
const time = @import("time.zig");

pub fn main() void {
    time.init();
    // Onboard LED
    gpio.pinMode(pins.led_builtin, .out);
    while (true) {
        const sensor_val = gpio.analogRead(0);
        gpio.toggle(pins.led_builtin);
        time.delay(sensor_val);
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
