local TypeFunction = typeof or type

local StringTypes = {
    ["boolean"] = true,
    ["table"] = true,
    ["userdata"] = true,
    ["function"] = true,
    ["number"] = true,
    ["nil"] = true
}

local RawEqual = rawequal or function(A, B)
    return A == B
end

local function CountTable(Table)
    local Count = 0

    for _, _ in next, Table do
        Count = Count + 1
    end

    return Count
end

local function GetStringRepresentation(Object, ObjectType)
    local Result, Metatable, OriginalToString

    if not (ObjectType == "table" or ObjectType == "userdata") then
        return tostring(Object)
    end

    Metatable = (getrawmetatable or getmetatable)(Object)
    if not Metatable then
        return tostring(Object)
    end

    OriginalToString = rawget(Metatable, "__tostring")
    rawset(Metatable, "__tostring", nil)
    Result = tostring(Object)
    rawset(Metatable, "__tostring", OriginalToString)

    return Result
end

local function FormatValue(Value)
    local ValueType = TypeFunction(Value)

    if StringTypes[ValueType] then
        return GetStringRepresentation(Value, ValueType)
    elseif ValueType == "string" then
        return "\"" .. Value .. "\""
    elseif ValueType == "Instance" then
        return Value.GetFullName(Value)
    else
        return ValueType .. ".new(" .. tostring(Value) .. ")"
    end
end

local function TableSerializer(TableToSerialize, IndentLevel, Cache, SpacerFunction)
    local ResultString = ""
    local TotalItems = CountTable(TableToSerialize)
    local CurrentIndex = 1
    local HasElements = TotalItems > 0

    Cache = Cache or {}
    IndentLevel = IndentLevel or 1
    SpacerFunction = SpacerFunction or string.rep

    local function LocalizedFormat(Value, IsTable)
        return IsTable and (Cache[Value][2] >= IndentLevel) and TableSerializer(Value, IndentLevel + 1, Cache, SpacerFunction) or FormatValue(Value)
    end

    Cache[TableToSerialize] = {TableToSerialize, 0}

    for Key, Value in next, TableToSerialize do
        local IsKeyTable = type(Key) == "table"
        local IsValueTable = type(Value) == "table"

        if not Cache[Key] and IsKeyTable then
            Cache[Key] = {Key, IndentLevel}
        end

        if not Cache[Value] and IsValueTable then
            Cache[Value] = {Value, IndentLevel}
        end

        ResultString = ResultString .. SpacerFunction("  ", IndentLevel) .. "[" .. LocalizedFormat(Key, IsKeyTable) .. "] = " .. LocalizedFormat(Value, IsValueTable) .. (CurrentIndex < TotalItems and "," or "") .. "\n"

        CurrentIndex = CurrentIndex + 1
    end

    return "{" .. (HasElements and "\n" or "") .. ResultString .. (HasElements and SpacerFunction("  ", IndentLevel - 1) or "") .. "}"
end

return TableSerializer
