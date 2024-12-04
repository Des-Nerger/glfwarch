fn FieldNamesRemovedTuple(comptime Struct: type, comptime names: *const [fields(Struct).len][]const u8) type {
    var fieldTypes: [fields(Struct).len]type = undefined;
    for (&fieldTypes, names) |*fieldType, name|
        fieldType.* = @TypeOf(@field(@as(Struct, undefined), name));
    return meta.Tuple(&fieldTypes);
}
pub fn arrayOfStructs(
    comptime Struct: type,
    comptime structFieldNames: *const [fields(Struct).len][]const u8,
    comptime tuples: []const FieldNamesRemovedTuple(Struct, structFieldNames),
) [tuples.len]Struct {
    var structs: [tuples.len]Struct = undefined;
    for (&structs, tuples) |*@"struct", tuple| {
        inline for (structFieldNames, fields(@TypeOf(tuple))) |structFieldName, tupleField|
            @field(@"struct", structFieldName) = @field(tuple, tupleField.name);
    }
    return structs;
}
const fields = meta.fields;
const meta = @This();
usingnamespace @import("std").meta;
