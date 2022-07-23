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

    var parser = try Parser.init(
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
        if (element == .node_begin) {
            var name = try element.node_begin.name.toString(allocator);
            defer allocator.free(name);

            std.debug.print("Node name: {s}\n", .{ name });
        }
    }
}
```

The parser does not allocate any memory during it's execution. Inside it's elements, it always returns pointers to inside the buffer provided by the caller.

It is the responsability of the caller to tell when to allocate the memory needed.

The type of elements is:
```zig
pub const Element = union(enum) {
    pub const NodeBegin = struct {
        name: Token,
        type_name: ?Token,
    };

    pub const Property = struct {
        name: Token,
        value: Value,
    };

    pub const Value = struct {
        type_name: ?Token,
        data: Token,
    };

    node_begin: NodeBegin,
    node_end: void,
    property: Property,
    argument: Value,
};
```

The caller can convert tokens into values using the functions `token.toString(allocator)`, `token.toInteger()` and `token.toDecimal()`, if they know the type of the token is one of those. Or they can use the more generic `token.toScala(allocator)`, which returns a union with the appropriate values depending on the token.

```zig
pub const Scalar = union(enum) {
    string: []const u8,
    integer: i64,
    decimal: f64,
    boolean: bool,
    none: void,
}
```

## TODO
 - [x] Update PUML parser states diagram
 - [x] Remove all allocations from the parser, return tokens instead
   - [x] Make the responsability of the caller to allocate memory as needed
 - [ ] Implement Slashdash comments
 - [ ] Create utility to convert sequence of `Element` to string
 - [ ] Pass the official KDL test suite