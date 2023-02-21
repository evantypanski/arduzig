const regs = @import("microzig").chip.registers;

// Very uno specific
// TODO: Use board.pin_map
const DigitalPort = enum {
    D,
    B,

    pub fn bitMask(comptime self: DigitalPort, comptime pin: u8) u8 {
        if (self == .D) {
            return 1 << pin;
        } else {
            return 1 << (pin - 8);
        }
    }

    pub fn dataReg(self: DigitalPort) *volatile u8 {
        if (self == .D) {
            return regs.PORTD.PORTD;
        } else {
            return regs.PORTB.PORTB;
        }
    }

    pub fn dirReg(self: DigitalPort) *volatile u8 {
        if (self == .D) {
            return regs.PORTD.DDRD;
        } else {
            return regs.PORTB.DDRB;
        }
    }

    pub fn inReg(self: DigitalPort) *volatile u8 {
        if (self == .D) {
            return regs.PORTD.PIND;
        } else {
            return regs.PORTB.PINB;
        }
    }
};

fn portForPin(comptime pin: u8) DigitalPort {
    if (pin < 8) {
        return .D;
    } else {
        return .B;
    }
}

pub fn pinMode(comptime pin: u8, comptime dir: enum { in, out }) void {
    const port = comptime portForPin(pin);
    if (dir == .in) {
        port.dirReg().* &= ~port.bitMask(pin);
    } else {
        port.dirReg().* |= port.bitMask(pin);
    }
}

pub const DigitalVal = enum(u1) {
    low = 1,
    high = 0,
};

pub fn digitalWrite(comptime pin: u8, val: DigitalVal) void {
    const port = comptime portForPin(pin);
    var data_reg = port.dataReg().*;
    if (val == .low) {
        data_reg &= ~port.bitMask(pin);
    } else {
        data_reg |= port.bitMask(pin);
    }
    port.dataReg().* = data_reg;
}

pub fn digitalRead(comptime pin: u8) enum { high, low } {
    const port = comptime portForPin(pin);
    return if ((port.inReg().* & comptime port.bitMask(pin)) == 0) .low else .high;
}

pub fn toggle(comptime pin: u8) void {
    const port = comptime portForPin(pin);
    var val = port.dataReg().*;
    val ^= port.bitMask(pin);
    port.dataReg().* = val;
}

pub fn analogRead(comptime pin: u8) u16 {
    // If we're reading then need to enable ADC
    regs.CPU.PRR.modify(.{ .PRADC = 0 });
    // ADPS set based on prescaling, 16MHz = 0x3
    regs.ADC.ADCSRA.modify(.{ .ADPS = 3, .ADEN = 1 });
    // Choose the pin and mode. In future REFS will possibly be set by user
    regs.ADC.ADMUX.modify(.{ .MUX = pin, .REFS = 1 });
    // Start conversation
    regs.ADC.ADCSRA.modify(.{ .ADSC = 1 });
    while (regs.ADC.ADCSRA.read().ADSC == 1) {}

    // Conversation done, ADC has the read value.
    return regs.ADC.ADC.*;
}

pub fn analogWrite(comptime pin: u8, comptime val: u8) void {
    pinMode(pin, .out);
    // Special cases at extremes
    if (val == 0) {
        digitalWrite(pin, .low);
    } else if (val == 255) {
        digitalWrite(pin, .high);
    } else {
        // Else we set the duty cycle
        // Hard code this for now, may want to change based on chip
        switch (pin) {
            3 => {
                // TIMER2B
                regs.TC2.TCCR2A.modify(.{ .COM2B = 2 });
                regs.TC2.OCR2B.* = val;
            },
            5 => {
                // TIMER0B
                regs.TC0.TCCR0A.modify(.{ .COM0B = 2 });
                regs.TC0.OCR0B.* = val;
            },
            6 => {
                // TIMER0A
                regs.TC0.TCCR0A.modify(.{ .COM0A = 2 });
                regs.TC0.OCR0A.* = val;
            },
            9 => {
                // TIMER1A
                regs.TC1.TCCR1A.modify(.{ .COM1A = 2 });
                regs.TC1.OCR1A.* = val;
            },
            10 => {
                // TIMER1B
                regs.TC1.TCCR1A.modify(.{ .COM1B = 2 });
                regs.TC1.OCR1B.* = val;
            },
            11 => {
                // TIMER2A
                regs.TC2.TCCR2A.modify(.{ .COM2A = 2 });
                regs.TC2.OCR2A.* = val;
            },
            else => {
                if (val < 128) {
                    digitalWrite(pin, .low);
                } else {
                    digitalWrite(pin, .high);
                }
            },
        }
    }
}
