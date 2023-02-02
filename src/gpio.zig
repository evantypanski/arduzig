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

pub fn digitalWrite(comptime pin: u8, comptime val: enum { high, low }) void {
    const port = comptime portForPin(pin);
    var data_reg = port.dataReg().*;
    if (val == .high) {
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
