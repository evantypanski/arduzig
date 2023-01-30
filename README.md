# Zigduino

An attempt to get Arduino's simple [standard library](https://www.arduino.cc/reference/en/) in Zig. This will make it easier for first time users to make Arduino projects with Zig.

At the time of writing it's all done for Arduino Uno. Ideally, all of that would be abstracted out with the abstraction layer in [microzig](https://github.com/ZigEmbeddedGroup/microzig).

## Building

```
zig build
```

## Uploading to an Arduino Uno

```
zig build upload -Dport=/dev/ttyACM0
```

You may need to be root or change permissions to access the device. Note that `/dev/ttyACM0` is the default.
