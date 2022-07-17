# zig-kdl

Library to parse [kdl](kdl.dev) configuration files in [Zig](ziglang.org/).

## Installation

Clone this repo into your zig project, for example under a `deps/` folder:
```shell
git clone https://github.com/pedromsilvapt/zig-kdl.git ./deps/zig-kdl
```

Then add this line to your `build.zig` file:
```zig
obj.addPackagePath("kdl", "deps/zig-kdl/src/main.zig");
```

## Usage
```zig
const std = @import("std");
const Parser = @import("kdl").Parser;

pub fn main () !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_purpose_allocator.deinit();

    var allocator = &general_purpose_allocator.allocator;

    var parser = try Parser.init(allocator,
        \\ package {
        \\     name "foo"
        \\     version "1.0.0"
        \\     dependencies platform="windows" {
        \\         winapi "1.0.0" path="./crates/my-winapi-fork"
        \\     }
        \\     dependencies {
        \\         miette "2.0.0" dev=true
        \\     }
        \\ }
    );

    while (try parser.next()) |element| {
        // Handle element
    }
}
```

The type of elements is:
```zig

pub const Element = union(enum) {
    pub const NodeBegin = struct {
        name: []const u8,
        type_name: ?[]const u8,
    };

    pub const Property = struct {
        name: []const u8,
        value: Value,
    };

    pub const Value = struct {
        type_name: ?[]const u8,
        data: ValueData,
    };

    pub const ValueData = union(enum) {
        string: []const u8,
        integer: i64,
        decimal: f64,
        boolean: bool,
        none: void,
    };

    node_begin: NodeBegin,
    node_end: void,
    property: Property,
    argument: Value,
};
```

## TODO
 - [ ] Update PUML parser states diagram
 - [ ] Remove all allocations from the parser, return tokens instead
   - [ ] Make the responsability of the caller to allocate memory as needed
 - [ ] Implement Slashdash comments
 - [ ] Create utility to convert sequence of `Element` to string
 - [ ] Pass the official KDL test suite