local M = {}

function M.is_empty(str)
  if type(str) ~= "string" or str == "" then
    return true
  end
  return false
end

---Checks type of o, if o not match with the given typenames, will
---throw an error and return false.
---@param o any
---@param ... type
---@return boolean
function M.check_type(o, ...)
  local args = { ... }
  local type = type(o)

  for _, typename in ipairs(args) do
    if type == typename then
      return true
    end
  end

  local typenames = ""
  for _, typename in ipairs(args) do
    typenames = typenames .. " " .. typename
  end

  error("Type check failed: expected " .. typenames .. " got " .. type)
  return false
end

local function serialize_impl(o, level)
  if type(o) == "string" then
    return '"' .. o .. '"'
  end
  if type(o) ~= "table" then
    return tostring(o)
  end

  local result = ""
  local indent = string.rep("\t", level)

  result = result .. "{\n"
  for key, value in pairs(o) do
    if type(key) ~= "number" then
      key = '"' .. key .. '"'
    end
    result = result .. indent .. "\t[" .. key .. "] = "
    local sublevel = level
    if type(value) == "table" then
      sublevel = sublevel + 1
    end
    result = result .. serialize_impl(value, sublevel) .. ",\n"
  end
  result = result .. indent .. "}"
  return result
end

---Serialized lua table into a string
---@param o table
---@return string
---@deprecated
function M.serialize(o)
  return serialize_impl(o, 0)
end

local function condfail(cond, ...)
  if not cond then
    return nil, (...)
  end
  return ...
end

---@deprecated
function M.deserialize(str, vars)
  -- create dummy environment
  local env = vars and setmetatable({}, { __index = vars }) or {}
  -- create function that returns deserialized value(s)
  local f, _err = load("return " .. str, "=deserialize", "t", env)
  if not f then
    return nil, _err
  end -- syntax error?
  -- set up safe runner
  local co = coroutine.create(f)
  -- local hook = function(why)
  --   error('Deserialization error: ' .. why, 1)
  -- end
  -- debug.sethook(co, hook, "", 1000)
  -- now run the deserialization
  return condfail(coroutine.resume(co))
end

function M.read_file(filename)
  local file, msg = io.open(filename, "r")
  if not file then
    return nil, msg
  end
  local str = file:read("a")
  file:close()
  return str
end

function M.write_file(filename, str)
  local file, msg = io.open(filename, "w")
  if not file then
    return nil, msg
  end
  _, msg = file:write(str)
  file:close()
  if msg then
    return nil, msg
  end
  return true
end

return M
