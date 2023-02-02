const std = @import("std");
const microzig = @import("microzig/src/main.zig");

pub fn build(b: *std.build.Builder) !void {
    const backing = .{
        .board = microzig.boards.arduino_uno,

        // if you don't have one of the boards, but do have one of the
        // "supported" chips:
        // .chip = microzig.chips.atmega328p,
    };

    var exe = microzig.addEmbeddedExecutable(
        b,
        "zigduino",
        "src/main.zig",
        backing,
        .{
            // optional slice of packages that can be imported into your app:
            // .packages = &my_packages,
        },
    );
    exe.setBuildMode(.ReleaseSmall);
    exe.install();

    const port = b.option([]const u8, "port", "Port Arduino is connected to (default: /dev/ttyACM0)") orelse "/dev/ttyACM0";

    const bin_path = b.getInstallPath(exe.inner.install_step.?.dest_dir, exe.inner.out_filename);

    const flash = try std.fmt.allocPrint(b.allocator, "flash:w:{s}:e", .{bin_path});
    defer b.allocator.free(flash);

    // Assume avrdude installed
    const upload_command = b.addSystemCommand(&.{ "avrdude", "-c", "arduino", "-P", port, "-b", "115200", "-p", "atmega328p", "-U", flash });
    upload_command.step.dependOn(b.getInstallStep());

    const upload_step = b.step("upload", "Upload binary to Arduino");
    upload_step.dependOn(&upload_command.step);

    const monitor = b.step("serial", "Serial output monitor");

    const baud = b.option([]const u8, "baud", "Baud rate for the serial monitor") orelse "115200";

    const screen = b.addSystemCommand(&.{
        "screen",
        port,
        baud,
    });

    // You don't have to upload in order to attach the serial monitor
    monitor.dependOn(&screen.step);
}
