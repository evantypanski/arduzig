//! Timing functions such as delay.

const serial = @import("serial.zig");
const chip = @import("microzig").chip;
const regs = @import("microzig").chip.registers;
const std = @import("std");
const Allocator = std.mem.Allocator;

const cpu_freq = 16000000;
const clock_cycles_per_microsecond = cpu_freq / 1000000;

var timer0_overflow_count = 0;

fn init() void {
    regs.TC0.TCCR0B.modify(.{ .CS0 = 0x5 });
    regs.TC0.TCCR0A.modify(.{ .WGM0 = 0x1 });
}

fn micros() u32 {
    // TODO: Need to care more about flags, interrupts, stuff like that.
    // TODO: Care about overflow in timer register
    return regs.TC0.TCNT0.*;
}

pub fn delay(ms: u64) void {
    init();
    var var_ms = comptime ms;
    var start = micros();
    while (var_ms > 0) {
        //if (micros() == start) {
        //var_ms -= 1;
        //}
        while ((var_ms > 0) and (micros() >= start)) {
            var_ms -= 1;
            start += 1000;
        }
    }
}
