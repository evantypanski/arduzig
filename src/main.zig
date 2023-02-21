const gpio = @import("gpio.zig");
const pins = @import("pins.zig");
const time = @import("time.zig");
const Serial = @import("Serial.zig");
const LiquidCrystal = @import("LiquidCrystal.zig").LiquidCrystal;

const std = @import("std");

pub fn main() !void {
    time.init();
    const lcd = LiquidCrystal(7, 8, 9, 10, 11, 12);
    lcd.begin(16, 2);
    //lcd.print("a");
    // Onboard LED
    gpio.pinMode(13, .out);
    while (true) {
        gpio.digitalWrite(13, .high);
        lcd.print("aaaaa");
        time.delay(1000);
        gpio.digitalWrite(13, .low);
        lcd.clear();
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
