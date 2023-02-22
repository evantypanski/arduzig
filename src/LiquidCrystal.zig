const gpio = @import("gpio.zig");
const time = @import("time.zig");

// This is all just an bit flag but we can deal with it as a struct.
const Config = struct {
    // Function set
    lcd_bitmode: enum { bits4, bits8 },
    lcd_lines: enum { oneline, twoline },
    lcd_dots: enum { dots5x8, dots5x10 },

    // Display set
    display: enum { on, off },
    cursor: enum { on, off },
    blink: enum { on, off },

    // Entry mode set
    entry: enum { right, left },
    entry_shift: enum { increment, decrement },

    pub fn init() Config {
        return Config{
            .lcd_bitmode = .bits4,
            .lcd_lines = .oneline,
            .lcd_dots = .dots5x8,
            .display = .on,
            .cursor = .off,
            .blink = .off,
            .entry = .left,
            .entry_shift = .decrement,
        };
    }

    // Turn config into bits for commands to recognize
    pub fn functionBits(self: Config) u8 {
        var bits: u8 = 0;
        if (self.lcd_bitmode == .bits8) {
            bits |= 0x10;
        }
        if (self.lcd_lines == .twoline) {
            bits |= 0x08;
        }
        if (self.lcd_dots == .dots5x10) {
            bits |= 0x04;
        }

        return bits;
    }

    // Turn config into bits for commands to recognize
    pub fn displayBits(self: Config) u8 {
        var bits: u8 = 0;
        if (self.display == .on) {
            bits |= 0x04;
        }
        if (self.cursor == .on) {
            bits |= 0x02;
        }
        if (self.blink == .on) {
            bits |= 0x01;
        }

        return bits;
    }

    // Turn config into bits for commands to recognize
    pub fn entryBits(self: Config) u8 {
        var bits: u8 = 0;
        if (self.entry == .left) {
            bits |= 0x02;
        }
        if (self.entry_shift == .increment) {
            bits |= 0x01;
        }

        return bits;
    }
};

// Commands
const clear_display = 0x01;
const return_home = 0x02;
const entry_mode_set = 0x04;
const display_control = 0x08;
const cursor_shift = 0x10;
const function_set = 0x20;
const set_cgram_addr = 0x40;
const set_dram_addr = 0x80;

// For display/cursor shift
const display_move = 0x08;
const cursor_move = 0x00;
const move_right = 0x04;
const move_left = 0x00;

// For now only 4 bit mode
pub fn LiquidCrystal(comptime rs: u8, comptime enable: u8, comptime d0: u8, comptime d1: u8, comptime d2: u8, comptime d3: u8) type {
    return struct {
        const Self = @This();

        const rs_pin: usize = rs;
        // TODO: rw_pin
        const enable_pin: usize = enable;

        // TODO: 8 pin mode
        // TODO: array doesn't get comptime for some reason... would prefer
        // this is an array. Needs comptime to set pinMode etc.
        const data0_pin = d0;
        const data1_pin = d1;
        const data2_pin = d2;
        const data3_pin = d3;

        var columns: u8 = 16;
        var num_lines: u8 = 1;

        var lcd_config = Config.init();

        // TODO dotsize but can't test
        pub fn begin(comptime cols: u8, comptime lines: u8) void {
            if (lines > 1) {
                lcd_config.lcd_lines = .twoline;
            }
            columns = cols;
            num_lines = lines;
            // TODO: Row offsets?

            gpio.pinMode(rs_pin, .out);
            gpio.pinMode(enable_pin, .out);
            gpio.pinMode(data0_pin, .out);
            gpio.pinMode(data1_pin, .out);
            gpio.pinMode(data2_pin, .out);
            gpio.pinMode(data3_pin, .out);

            time.delay(50);
            gpio.digitalWrite(rs_pin, .low);
            gpio.digitalWrite(enable_pin, .low);

            // Put into 4 bit mode
            write4bits(0x03);
            time.delay(5);
            write4bits(0x03);
            time.delay(5);
            write4bits(0x03);
            time.delay(1);
            write4bits(0x02);

            command(function_set | lcd_config.functionBits());
            display();
            clear();
            command(entry_mode_set | lcd_config.entryBits());
        }

        pub fn clear() void {
            command(clear_display);
            time.delay(2);
        }

        pub fn home() void {
            command(return_home);
            time.delay(2);
        }

        pub fn noDisplay() void {
            lcd_config.display = .off;
            command(display_control | lcd_config.displayBits());
        }

        pub fn display() void {
            lcd_config.display = .on;
            command(display_control | lcd_config.displayBits());
        }

        pub fn noCursor() void {
            lcd_config.cursor = .off;
            command(display_control | lcd_config.displayBits());
        }

        pub fn cursor() void {
            lcd_config.cursor = .on;
            command(display_control | lcd_config.displayBits());
        }

        pub fn noBlink() void {
            lcd_config.blink = .off;
            command(display_control | lcd_config.displayBits());
        }

        pub fn blink() void {
            lcd_config.blink = .on;
            command(display_control | lcd_config.displayBits());
        }

        // Scroll the text on the display one spot to the left
        pub fn scrollDisplayLeft() void {
            command(cursor_shift | display_move | move_left);
        }

        // Scroll the text on the display one spot to the right
        pub fn scrollDisplayRight() void {
            command(cursor_shift | display_move | move_right);
        }

        // Make text flow left -> right
        pub fn leftToRight() void {
            lcd_config.entry = .left;
            command(entry_mode_set | lcd_config.entryBits());
        }

        // Make text flow right -> left
        pub fn rightToLeft() void {
            lcd_config.entry = .right;
            command(entry_mode_set | lcd_config.entryBits());
        }

        // Right justify
        pub fn autoscroll() void {
            lcd_config.entry_shift = .increment;
            command(entry_mode_set | lcd_config.entryBits());
        }

        // Left justify
        pub fn noAutoscroll() void {
            lcd_config.entry_shift = .decrement;
            command(entry_mode_set | lcd_config.entryBits());
        }

        pub fn print(str: []const u8) void {
            for (str) |value| {
                write(value);
            }
        }

        inline fn command(value: u8) void {
            send(value, .command);
        }

        inline fn write(value: u8) void {
            send(value, .val);
        }

        fn send(value: u8, mode: enum { command, val }) void {
            if (mode == .command) {
                gpio.digitalWrite(rs_pin, .low);
            } else {
                gpio.digitalWrite(rs_pin, .high);
            }

            write4bits(@intCast(u4, value >> 4));
            write4bits(@intCast(u4, value & 0xf));
        }

        fn write4bits(value: u4) void {
            gpio.digitalWrite(data0_pin, @intToEnum(gpio.DigitalVal, value & 0x01));
            gpio.digitalWrite(data1_pin, @intToEnum(gpio.DigitalVal, (value >> 1) & 0x01));
            gpio.digitalWrite(data2_pin, @intToEnum(gpio.DigitalVal, (value >> 2) & 0x01));
            gpio.digitalWrite(data3_pin, @intToEnum(gpio.DigitalVal, (value >> 3) & 0x01));
            pulseEnable();
        }

        fn pulseEnable() void {
            gpio.digitalWrite(enable_pin, .low);
            // TODO: This should be 1 us.. but we're slow here.
            time.delay(1);
            gpio.digitalWrite(enable_pin, .high);
            // Enable just needs to be high for >450 ns so we good.
            time.delay(1);
            gpio.digitalWrite(enable_pin, .low);
            // This'll be 100us not 1us like others to settle
            time.delay(1);
        }
    };
}
