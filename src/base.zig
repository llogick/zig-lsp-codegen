//! generated by zig-lsp-codegen

const std = @import("std");

pub const URI = []const u8;
/// The URI of a document
pub const DocumentUri = []const u8;
/// A JavaScript regular expression; never used
pub const RegExp = []const u8;

pub const LSPAny = std.json.Value;
pub const LSPArray = []LSPAny;
pub const LSPObject = std.json.ArrayHashMap(std.json.Value);

/// See https://www.jsonrpc.org/specification
pub const JsonRPCMessage = union(enum) {
    request: Request,
    notification: Notification,
    response: Response,

    /// Method names that begin with the word rpc followed by a period character (U+002E or ASCII 46) are reserved for rpc-internal methods and extensions and MUST NOT be used for anything else.
    pub fn is_reserved_method_name(name: []const u8) bool {
        return std.mem.startsWith(u8, name, "rpc.");
    }

    pub const ID = union(enum) {
        number: i64,
        string: []const u8,

        pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) std.json.ParseError(@TypeOf(source.*))!ID {
            switch (try source.peekNextTokenType()) {
                .number => return .{ .number = try std.json.innerParse(i64, allocator, source, options) },
                .string => return .{ .string = try std.json.innerParse([]const u8, allocator, source, options) },
                else => return error.SyntaxError,
            }
        }

        pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) std.json.ParseFromValueError!ID {
            _ = allocator;
            _ = options;
            switch (source) {
                .integer => |number| return .{ .number = number },
                .string => |string| return .{ .string = string },
                else => return error.UnexpectedToken,
            }
        }

        pub fn jsonStringify(self: ID, stream: anytype) @TypeOf(stream.*).Error!void {
            switch (self) {
                inline else => |value| try stream.write(value),
            }
        }
    };

    pub const Request = struct {
        comptime jsonrpc: []const u8 = "2.0",
        /// The request id.
        id: ID,
        /// The method to be invoked.
        method: []const u8,
        /// The method's params. Can only be `.array` or `.object`.
        params: ?std.json.Value,
    };

    pub const Notification = struct {
        comptime jsonrpc: []const u8 = "2.0",
        /// The method to be invoked.
        method: []const u8,
        /// The notification's params. Can only be `.array` or `.object`.
        params: ?std.json.Value,
    };

    pub const Response = struct {
        comptime jsonrpc: []const u8 = "2.0",
        /// The request id.
        id: ?ID,
        /// The result of a request. This member is REQUIRED on success.
        /// This member MUST NOT exist if there was an error invoking the m
        result: ?std.json.Value,
        /// The error object in case a request fails.
        @"error": ?Error,

        pub const Error = struct {
            /// A number indicating the error type that occurred.
            code: Code,
            /// A string providing a short description of the error.
            message: []const u8,
            /// A primitive or structured value that contains additional
            /// information about the error. Can be omitted.
            data: std.json.Value = .null,

            /// The error codes from and including -32768 to -32000 are reserved for pre-defined errors. Any code within this range, but not defined explicitly below is reserved for future use.
            /// The remainder of the space is available for application defined errors.
            pub const Code = enum(i64) {
                /// Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.
                parse_error = -32700,
                /// The JSON sent is not a valid Request object.
                invalid_request = -32600,
                /// The method does not exist / is not available.
                method_not_found = -32601,
                /// Invalid method parameter(s).
                invalid_params = -32602,
                /// Internal JSON-RPC error.
                internal_error = -32603,

                /// -32000 to -32099 are reserved for implementation-defined server-errors.
                _,

                pub fn jsonStringify(code: Code, stream: anytype) @TypeOf(stream.*).Error!void {
                    try stream.write(@intFromEnum(code));
                }
            };
        };
    };

    pub fn jsonParse(
        allocator: std.mem.Allocator,
        source: anytype,
        options: std.json.ParseOptions,
    ) std.json.ParseError(@TypeOf(source.*))!JsonRPCMessage {
        if (try source.next() != .object_begin) return error.UnexpectedToken;

        var fields: Fields = .{};

        while (true) {
            const field_name = blk: {
                const name_token = try source.nextAllocMax(allocator, .alloc_if_needed, options.max_value_len.?);
                const maybe_field_name = switch (name_token) {
                    inline .string, .allocated_string => |slice| std.meta.stringToEnum(std.meta.FieldEnum(Fields), slice),
                    .object_end => break, // No more fields.
                    else => return error.UnexpectedToken,
                };

                switch (name_token) {
                    .string => {},
                    .allocated_string => |slice| allocator.free(slice),
                    else => unreachable,
                }

                break :blk maybe_field_name orelse {
                    if (options.ignore_unknown_fields) {
                        try source.skipValue();
                        continue;
                    } else {
                        return error.UnexpectedToken;
                    }
                };
            };

            // check for contradicting fields
            switch (field_name) {
                .jsonrpc => {},
                .id => {},
                .method, .params => {
                    const is_result_set = if (fields.result) |result| result != .null else false;
                    if (is_result_set or fields.@"error" != null) {
                        return error.UnexpectedToken;
                    }
                },
                .result => {
                    if (fields.@"error" != null) {
                        return error.UnexpectedToken;
                    }
                },
                .@"error" => {
                    const is_result_set = if (fields.result) |result| result != .null else false;
                    if (is_result_set) {
                        return error.UnexpectedToken;
                    }
                },
            }

            switch (field_name) {
                inline else => |comptime_field_name| {
                    if (comptime_field_name == field_name) {
                        if (@field(fields, @tagName(comptime_field_name))) |_| {
                            switch (options.duplicate_field_behavior) {
                                .use_first => {
                                    _ = try Fields.parse(comptime_field_name, allocator, source, options);
                                    break;
                                },
                                .@"error" => return error.DuplicateField,
                                .use_last => {},
                            }
                        }
                        @field(fields, @tagName(comptime_field_name)) = try Fields.parse(comptime_field_name, allocator, source, options);
                    }
                },
            }
        }

        return try fields.toMessage();
    }

    pub fn jsonParseFromValue(
        allocator: std.mem.Allocator,
        source: std.json.Value,
        options: std.json.ParseOptions,
    ) std.json.ParseFromValueError!JsonRPCMessage {
        if (source != .object) return error.UnexpectedToken;

        var fields: Fields = .{};

        for (source.object.keys(), source.object.values()) |field_name, field_source| {
            inline for (std.meta.fields(Fields)) |field| {
                const field_enum = comptime std.meta.stringToEnum(std.meta.FieldEnum(Fields), field.name).?;
                if (std.mem.eql(u8, field.name, field_name)) {
                    @field(fields, field.name) = try Fields.parseFromValue(field_enum, allocator, field_source, options);
                    break;
                }
            } else {
                // Didn't match anything.
                if (!options.ignore_unknown_fields) return error.UnknownField;
            }
        }

        return try fields.toMessage();
    }

    pub fn jsonStringify(message: JsonRPCMessage, stream: anytype) @TypeOf(stream.*).Error!void {
        try stream.beginObject();
        try stream.objectField("jsonrpc");
        try stream.write("2.0");

        switch (message) {
            .request => |request| {
                try stream.objectField("id");
                switch (request.id) {
                    .number => |number| try stream.write(number),
                    .string => |string| try stream.write(string),
                }
                try stream.objectField("method");
                try stream.write(request.method);

                if (request.params) |params_val| {
                    try stream.objectField("params");
                    try stream.write(params_val);
                } else if (stream.options.emit_null_optional_fields) {
                    try stream.objectField("params");
                    try stream.write(null);
                }
            },
            .notification => |notification| {
                try stream.objectField("method");
                try stream.write(notification.method);

                if (notification.params) |params_val| {
                    try stream.objectField("params");
                    try stream.write(params_val);
                } else if (stream.options.emit_null_optional_fields) {
                    try stream.objectField("params");
                    try stream.write(null);
                }
            },
            .response => |response| {
                if (response.id) |id_val| {
                    try stream.objectField("id");
                    switch (id_val) {
                        .number => |number| try stream.write(number),
                        .string => |string| try stream.write(string),
                    }
                } else if (stream.options.emit_null_optional_fields) {
                    try stream.objectField("id");
                    try stream.write(null);
                }

                try stream.objectField(if (response.result != null) "result" else "error");
                if (response.result) |result_val| {
                    try stream.write(result_val);
                } else if (response.@"error") |error_val| {
                    try stream.write(error_val);
                } else unreachable;
            },
        }
        try stream.endObject();
    }

    const Fields = struct {
        jsonrpc: ?[]const u8 = null,
        method: ?[]const u8 = null,
        id: ?ID = null,
        params: ?std.json.Value = null,
        result: ?std.json.Value = null,
        @"error": ?Response.Error = null,

        fn parse(
            comptime field: std.meta.FieldEnum(@This()),
            allocator: std.mem.Allocator,
            source: anytype,
            options: std.json.ParseOptions,
        ) std.json.ParseError(@TypeOf(source.*))!std.meta.FieldType(@This(), field) {
            return switch (field) {
                .jsonrpc, .method => try std.json.innerParse([]const u8, allocator, source, options),
                .id => switch (try source.peekNextTokenType()) {
                    .null => {
                        std.debug.assert(try source.next() == .null);
                        return null;
                    },
                    .number => ID{ .number = try std.json.innerParse(i64, allocator, source, options) },
                    .string => ID{ .string = try std.json.innerParse([]const u8, allocator, source, options) },
                    else => error.UnexpectedToken, // "id" field must be null/integer/string
                },
                .params => switch (try source.peekNextTokenType()) {
                    .null => {
                        std.debug.assert(try source.next() == .null);
                        return .null;
                    },
                    .object_begin, .array_begin => try std.json.Value.jsonParse(allocator, source, options),
                    else => error.UnexpectedToken, // "params" field must be null/object/array
                },
                .result => try std.json.Value.jsonParse(allocator, source, options),
                .@"error" => try std.json.innerParse(Response.Error, allocator, source, options),
            };
        }

        fn parseFromValue(
            comptime field: std.meta.FieldEnum(@This()),
            allocator: std.mem.Allocator,
            source: std.json.Value,
            options: std.json.ParseOptions,
        ) std.json.ParseFromValueError!std.meta.FieldType(@This(), field) {
            return switch (field) {
                .jsonrpc, .method => try std.json.innerParseFromValue([]const u8, allocator, source, options),
                .id => switch (source) {
                    .null => null,
                    .integer => |number| ID{ .number = number },
                    .string => |string| ID{ .string = string },
                    else => error.UnexpectedToken, // "id" field must be null/integer/string
                },
                .params => switch (source) {
                    .null, .object, .array => source,
                    else => error.UnexpectedToken, // "params" field must be null/object/array
                },
                .result => source,
                .@"error" => try std.json.innerParseFromValue(Response.Error, allocator, source, options),
            };
        }

        fn toMessage(self: Fields) !JsonRPCMessage {
            const jsonrpc = self.jsonrpc orelse
                return error.MissingField;
            if (!std.mem.eql(u8, jsonrpc, "2.0"))
                return error.UnexpectedToken; // the "jsonrpc" field must be "2.0"

            if (self.method) |method_val| {
                if (self.result != null or self.@"error" != null) {
                    return error.UnexpectedToken; // the "method" field indicates a request or notification which can't have the "result" or "error" field
                }
                if (self.params) |params_val| {
                    switch (params_val) {
                        .null, .object, .array => {},
                        else => unreachable,
                    }
                }

                if (self.id) |id_val| {
                    return .{
                        .request = .{
                            .method = method_val,
                            .params = self.params,
                            .id = id_val,
                        },
                    };
                } else {
                    return .{
                        .notification = .{
                            .method = method_val,
                            .params = self.params,
                        },
                    };
                }
            } else {
                if (self.@"error" != null) {
                    const is_result_set = if (self.result) |result| result != .null else false;
                    if (is_result_set) return error.UnexpectedToken; // the "result" and "error" fields can't both be set
                } else {
                    const is_result_set = self.result != null;
                    if (!is_result_set) return error.MissingField;
                }

                return .{
                    .response = .{
                        .result = self.result,
                        .@"error" = self.@"error",
                        .id = self.id,
                    },
                };
            }
        }
    };

    test Request {
        try testParse(
            \\{"jsonrpc": "2.0", "id": 1, "method": "Die", "params": null}
        , .{
            .request = .{
                .id = .{ .number = 1 },
                .method = "Die",
                .params = .null,
            },
        }, .{});
        try testParse(
            \\{"id": "Würde", "method": "des", "params": null, "jsonrpc": "2.0"}
        , .{
            .request = .{
                .id = .{ .string = "Würde" },
                .method = "des",
                .params = .null,
            },
        }, .{});
        try testParse(
            \\{"method": "ist", "params": {}, "jsonrpc": "2.0", "id": "Menschen"}
        , .{
            .request = .{
                .id = .{ .string = "Menschen" },
                .method = "ist",
                .params = .{ .object = undefined },
            },
        }, .{});
        try testParse(
            \\{"method": ".", "jsonrpc": "2.0", "id": "unantastbar"}
        , .{
            .request = .{
                .id = .{ .string = "unantastbar" },
                .method = ".",
                .params = null,
            },
        }, .{});
    }

    test Notification {
        try testParse(
            \\{"jsonrpc": "2.0", "method": "foo", "params": null}
        , .{
            .notification = .{
                .method = "foo",
                .params = .null,
            },
        }, .{});
        try testParse(
            \\{"method": "bar", "params": null, "jsonrpc": "2.0"}
        , .{
            .notification = .{
                .method = "bar",
                .params = .null,
            },
        }, .{});
        try testParse(
            \\{"params": [], "method": "baz", "jsonrpc": "2.0"}
        , .{
            .notification = .{
                .method = "baz",
                .params = .{ .array = undefined },
            },
        }, .{});
        try testParse(
            \\{"method": "booze?", "jsonrpc": "2.0"}
        , .{
            .notification = .{
                .method = "booze?",
                .params = null,
            },
        }, .{});
    }

    test "Notification allow setting the 'id' field to null" {
        try testParse(
            \\{"jsonrpc": "2.0", "id": null, "method": "foo", "params": null}
        , .{
            .notification = .{
                .method = "foo",
                .params = .null,
            },
        }, .{});
    }

    test Response {
        try testParse(
            \\{"jsonrpc": "2.0", "id": 1, "result": null}
        , .{ .response = .{
            .id = .{ .number = 1 },
            .result = .null,
            .@"error" = null,
        } }, .{});

        try testParseExpectedError(
            \\{"jsonrpc": "2.0", "id": 1}
        ,
            error.MissingField,
            error.MissingField,
            .{},
        );

        try testParse(
            \\{"id": "id", "jsonrpc": "2.0", "result": null, "error": {"code": 3, "message": "foo", "data": null}}
        , .{ .response = .{
            .id = .{ .string = "id" },
            .result = .null,
            .@"error" = .{ .code = @enumFromInt(3), .message = "foo", .data = .null },
        } }, .{});
        try testParse(
            \\{"id": "id", "jsonrpc": "2.0", "error": {"code": 42, "message": "bar"}}
        , .{ .response = .{
            .id = .{ .string = "id" },
            .result = null,
            .@"error" = .{ .code = @enumFromInt(42), .message = "bar", .data = .null },
        } }, .{});
    }

    test "validate that the 'params' is null/array/object" {
        // null
        try testParse(
            \\{"jsonrpc": "2.0", "id": 1, "method": "foo", "params": null}
        , .{ .request = .{
            .id = .{ .number = 1 },
            .method = "foo",
            .params = .null,
        } }, .{});
        try testParse(
            \\{"jsonrpc": "2.0", "id": 1, "method": "foo"}
        , .{ .request = .{
            .id = .{ .number = 1 },
            .method = "foo",
            .params = null,
        } }, .{});

        // bool
        try testParseExpectedError(
            \\{"jsonrpc": "2.0", "id": 1, "method": "foo", "params": true}
        ,
            error.UnexpectedToken,
            error.UnexpectedToken,
            .{},
        );

        // integer
        try testParseExpectedError(
            \\{"jsonrpc": "2.0", "id": 1, "method": "foo", "params": 5}
        ,
            error.UnexpectedToken,
            error.UnexpectedToken,
            .{},
        );

        // float
        try testParseExpectedError(
            \\{"jsonrpc": "2.0", "id": 1, "method": "foo", "params": 4.2}
        ,
            error.UnexpectedToken,
            error.UnexpectedToken,
            .{},
        );

        // string
        try testParseExpectedError(
            \\{"jsonrpc": "2.0", "id": 1, "method": "foo", "params": "bar"}
        ,
            error.UnexpectedToken,
            error.UnexpectedToken,
            .{},
        );

        // array
        try testParse(
            \\{"jsonrpc": "2.0", "id": 1, "method": "foo", "params": []}
        , .{ .request = .{
            .id = .{ .number = 1 },
            .method = "foo",
            .params = .{ .array = undefined },
        } }, .{});

        // object
        try testParse(
            \\{"jsonrpc": "2.0", "id": 1, "method": "foo", "params": {}}
        , .{ .request = .{
            .id = .{ .number = 1 },
            .method = "foo",
            .params = .{ .object = undefined },
        } }, .{});
    }

    test "ignore_unknown_fields" {
        try testParse(
            \\{"jsonrpc": "2.0", "id": 1, "other": null, "method": "foo", "params": null, "extra": "."}
        , .{
            .request = .{
                .id = .{ .number = 1 },
                .method = "foo",
                .params = .null,
            },
        }, .{ .ignore_unknown_fields = true });
        try testParse(
            \\{"other": "", "jsonrpc": "2.0", "extra": {}, "method": "bar"}
        , .{
            .notification = .{
                .method = "bar",
                .params = null,
            },
        }, .{ .ignore_unknown_fields = true });
        try testParseExpectedError(
            \\{"jsonrpc": "2.0", "id": 1, "other": null, ".": "Sie", "params": {}, "extra": {}}
        ,
            error.UnexpectedToken,
            error.UnknownField,
            .{ .ignore_unknown_fields = false },
        );
    }

    fn testParse(message: []const u8, expected: JsonRPCMessage, parse_options: std.json.ParseOptions) !void {
        const allocator = std.testing.allocator;

        const parsed_from_slice = try std.json.parseFromSlice(JsonRPCMessage, allocator, message, parse_options);
        defer parsed_from_slice.deinit();

        const parsed_value = try std.json.parseFromSlice(std.json.Value, allocator, message, parse_options);
        defer parsed_value.deinit();

        const parsed_from_value = try std.json.parseFromValue(JsonRPCMessage, allocator, parsed_value.value, parse_options);
        defer parsed_from_value.deinit();

        const from_slice_stringified = try std.json.stringifyAlloc(allocator, parsed_from_slice.value, .{ .whitespace = .indent_2 });
        defer allocator.free(from_slice_stringified);

        const from_value_stringified = try std.json.stringifyAlloc(allocator, parsed_from_value.value, .{ .whitespace = .indent_2 });
        defer allocator.free(from_value_stringified);

        if (!std.mem.eql(u8, from_slice_stringified, from_value_stringified)) {
            std.debug.print(
                \\
                \\====== std.json.parseFromSlice: ======
                \\{s}
                \\====== std.json.parseFromValue: ======
                \\{s}
                \\======================================\
                \\
            , .{ from_slice_stringified, from_value_stringified });
            return error.TestExpectedEqual;
        }

        try expectEqual(parsed_from_slice.value, parsed_from_value.value);
        try expectEqual(parsed_from_slice.value, expected);
        try expectEqual(parsed_from_value.value, expected);
    }

    fn testParseExpectedError(
        message: []const u8,
        expected_parse_error: std.json.ParseError(std.json.Scanner),
        expected_parse_from_error: std.json.ParseFromValueError,
        parse_options: std.json.ParseOptions,
    ) !void {
        const allocator = std.testing.allocator;

        try std.testing.expectError(expected_parse_error, std.json.parseFromSlice(JsonRPCMessage, allocator, message, parse_options));

        const parsed_value = std.json.parseFromSlice(std.json.Value, allocator, message, parse_options) catch |err| {
            try std.testing.expectEqual(expected_parse_from_error, err);
            return;
        };
        defer parsed_value.deinit();

        try std.testing.expectError(expected_parse_from_error, std.json.parseFromValue(JsonRPCMessage, allocator, parsed_value.value, parse_options));
    }

    fn expectEqual(a: JsonRPCMessage, b: JsonRPCMessage) !void {
        try std.testing.expectEqual(std.meta.activeTag(a), std.meta.activeTag(b));
        switch (a) {
            .request => {
                try std.testing.expectEqualDeep(a.request.id, b.request.id);
                try std.testing.expectEqualStrings(a.request.method, b.request.method);

                // this only a shallow equality check
                try std.testing.expectEqual(a.request.params == null, b.request.params == null);
                if (a.request.params != null) {
                    try std.testing.expectEqual(std.meta.activeTag(a.request.params.?), std.meta.activeTag(b.request.params.?));
                }
            },
            .notification => {
                try std.testing.expectEqualStrings(a.notification.method, b.notification.method);

                // this only a shallow equality check
                try std.testing.expectEqual(a.notification.params == null, b.notification.params == null);
                if (a.notification.params != null) {
                    try std.testing.expectEqual(std.meta.activeTag(a.notification.params.?), std.meta.activeTag(b.notification.params.?));
                }
            },
            .response => {
                try std.testing.expectEqualDeep(a.response.id, b.response.id);
                try std.testing.expectEqualDeep(a.response.@"error", b.response.@"error");

                // this only a shallow equality check
                try std.testing.expectEqual(a.response.result == null, b.response.result == null);
                if (a.response.result != null) {
                    try std.testing.expectEqual(std.meta.activeTag(a.response.result.?), std.meta.activeTag(b.response.result.?));
                }
            },
        }
    }
};

/// Indicates in which direction a message is sent in the protocol.
pub const MessageDirection = enum {
    client_to_server,
    server_to_client,
    both,
};

pub const RegistrationMetadata = struct {
    method: ?[]const u8,
    Options: ?type,
};

pub const NotificationMetadata = struct {
    method: []const u8,
    documentation: ?[]const u8,
    direction: MessageDirection,
    Params: ?type,
    registration: RegistrationMetadata,
};

pub const RequestMetadata = struct {
    method: []const u8,
    documentation: ?[]const u8,
    direction: MessageDirection,
    Params: ?type,
    Result: type,
    PartialResult: ?type,
    ErrorData: ?type,
    registration: RegistrationMetadata,
};

pub fn Map(comptime Key: type, comptime Value: type) type {
    if (Key != []const u8) @compileError("TODO support non string Key's");
    return std.json.ArrayHashMap(Value);
}

pub fn UnionParser(comptime T: type) type {
    return struct {
        pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) std.json.ParseError(@TypeOf(source.*))!T {
            const json_value = try std.json.Value.jsonParse(allocator, source, options);
            return try jsonParseFromValue(allocator, json_value, options);
        }

        pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) std.json.ParseFromValueError!T {
            inline for (std.meta.fields(T)) |field| {
                if (std.json.parseFromValueLeaky(field.type, allocator, source, options)) |result| {
                    return @unionInit(T, field.name, result);
                } else |_| {}
            }
            return error.UnexpectedToken;
        }

        pub fn jsonStringify(self: T, stream: anytype) @TypeOf(stream.*).Error!void {
            switch (self) {
                inline else => |value| try stream.write(value),
            }
        }
    };
}

pub fn EnumCustomStringValues(comptime T: type, comptime contains_empty_enum: bool) type {
    return struct {
        const kvs = build_kvs: {
            const KV = struct { []const u8, T };
            const fields = @typeInfo(T).Union.fields;
            var kvs_array: [fields.len - 1]KV = undefined;
            for (fields[0 .. fields.len - 1], 0..) |field, i| {
                kvs_array[i] = .{ field.name, @field(T, field.name) };
            }
            break :build_kvs kvs_array;
        };
        /// NOTE: this maps 'empty' to .empty when T contains an empty enum
        /// this shouldn't happen but this doesn't do any harm
        const map = std.StaticStringMap(T).initComptime(kvs);

        pub fn eql(a: T, b: T) bool {
            const tag_a = std.meta.activeTag(a);
            const tag_b = std.meta.activeTag(b);
            if (tag_a != tag_b) return false;

            if (tag_a == .custom_value) {
                return std.mem.eql(u8, a.custom_value, b.custom_value);
            } else {
                return true;
            }
        }

        pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) std.json.ParseError(@TypeOf(source.*))!T {
            const slice = try std.json.innerParse([]const u8, allocator, source, options);
            if (contains_empty_enum and slice.len == 0) return .empty;
            return map.get(slice) orelse return .{ .custom_value = slice };
        }

        pub fn jsonParseFromValue(allocator: std.mem.Allocator, source: std.json.Value, options: std.json.ParseOptions) std.json.ParseFromValueError!T {
            const slice = try std.json.parseFromValueLeaky([]const u8, allocator, source, options);
            if (contains_empty_enum and slice.len == 0) return .empty;
            return map.get(slice) orelse return .{ .custom_value = slice };
        }

        pub fn jsonStringify(self: T, stream: anytype) @TypeOf(stream.*).Error!void {
            if (contains_empty_enum and self == .empty) {
                try stream.write("");
                return;
            }
            switch (self) {
                .custom_value => |str| try stream.write(str),
                else => |val| try stream.write(@tagName(val)),
            }
        }
    };
}

pub fn EnumStringifyAsInt(comptime T: type) type {
    return struct {
        pub fn jsonStringify(self: T, stream: anytype) @TypeOf(stream.*).Error!void {
            try stream.write(@intFromEnum(self));
        }
    };
}

comptime {
    _ = @field(@This(), "notification_metadata");
    _ = @field(@This(), "request_metadata");
}
