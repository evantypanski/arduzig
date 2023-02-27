//! Timing functions such as delay.

const micro = @import("microzig");
const regs = @import("microzig").chip.registers;
const std = @import("std");

const clock_cycles_per_microsecond = micro.clock.get().cpu / 1000000;
const microseconds_per_timer0_overflow = clock_cycles_to_microseconds(64 * 256);
pub const millis_inc = (microseconds_per_timer0_overflow / 1000);

pub const fract_inc: u8 = ((microseconds_per_timer0_overflow % 1000) >> 3);
pub const fract_max: u8 = (1000 >> 3);

pub var timer0_overflow_count: u64 = 0;
pub var timer0_millis: u64 = 0;
pub var timer0_fract: u8 = 0;

fn clock_cycles_to_microseconds(a: u64) u64 {
    return ((a) / clock_cycles_per_microsecond);
}

fn microseconds_to_clock_cycles(a: u64) u64 {
    return ((a) * clock_cycles_per_microsecond);
}

// This will eventually move from time. Probably. Just most of this stuff
// is enabling timers and interrupts on them
pub fn init() void {
    // Enable interrupts
    regs.CPU.SREG.modify(.{ .I = 0x1 });
    regs.TC0.TIMSK0.modify(.{ .TOIE0 = 0x1 });
    // Set clock mode
    regs.TC0.TCCR0B.modify(.{ .CS0 = 0x1 });
    regs.TC0.TCCR0A.modify(.{ .WGM0 = 0x1 });

    // PWM timer stuff
    regs.TC1.TCCR1B.modify(.{ .CS1 = 0x4 });
    regs.TC1.TCCR1A.modify(.{ .WGM1 = 0x1 });
    regs.TC2.TCCR2B.modify(.{ .CS2 = 0x4 });
    regs.TC2.TCCR2A.modify(.{ .WGM2 = 0x1 });
}

pub fn micros() u64 {
    const oldSREG = regs.CPU.SREG.*;
    micro.cpu.cli();
    var m = timer0_overflow_count;
    const t = regs.TC0.TCNT0.*;
    if (regs.TC0.TIFR0.read().TOV0 == 1 and t < 255) {
        m += 1;
    }
    regs.CPU.SREG.* = oldSREG;
    return ((m << 8) + t) * (64 / clock_cycles_per_microsecond);
}

pub fn millis() u64 {
    const oldSREG = regs.CPU.SREG.*;
    micro.cpu.cli();

    var m = timer0_millis;

    regs.CPU.SREG.* = oldSREG;
    return m;
}
pub fn delay(ms: u64) void {
    // Please tell me why in the world I need this 32 here
    var var_ms = comptime ms * 32;
    var start = micros();
    while (var_ms > 0) {
        while ((var_ms > 0) and ((micros() - start) >= 1000)) {
            var_ms -= 1;
            start += 1000;
        }
    }
}

// u32 not u64 to easily get signed version so we can have more efficient
// loop later. This is really trial and error and should be done better when
// I am able.
pub fn delayMicroseconds(us: u32) void {
    // TODO: Care about clock frequency
    // We'll assume <= 1us overhead of function call is enough
    if (us <= 1) return;

    // This is signed so later we can subtract an amount larger than 1
    // and check if it's greater than 0 without underflow.
    var us_var: i64 = us;

    // Trying to get the loop later exactly right... and this x4 to get
    // us to actually be us and not ms, but this was trial and error anyway
    us_var <<= 2;
    // Subtract an amount of time. Arduino libraries have 5 so I'll do that,
    // but I think copying the variable will add a load in there. But then
    // we aren't doing the shift first at the moment so it may even out.
    us_var -= 5;

    // After messing around with inline ASM for forever, I think Zig/LLVM
    // don't fully work with AVR inline assembly constraints like =w - or
    // probably any 32 bit or 64 bit types. Instead, just try out a busy
    // wait with a loop.
    while (us_var > 0) {
        us_var -= 9;
        asm volatile ("nop");
    }
}
