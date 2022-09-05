-- panbbcode - BBCode writer for pandoc
-- Copyright (C) 2014 Jens Oliver John < dev ! 2ion ! de >
-- Licensed under the GNU General Public License v3 or later.
-- Written for Lua 5.{1,2}

-- PRIVATE

local function enclose(t, s, p)
  if p then
    return string.format('[%s=%s]%s[/%s]', t, p, s, t)
  else
    return string.format('[%s]%s[/%s]', t, s, t)
  end
end

local function rstrip(s)
  local t, _ = s:gsub('\n+$', '')
  return t
end

local function strlen_utf8(s)
  local _, count = s:gsub('[^\128-\193]', '')
  return count
end

local function each_line(s)
  if s:sub(-1) ~= '\n' then
    s = s .. '\n'
  end
  return s:gmatch('(.-)\n')
end

local function strsize(s)
  local w, h = 0, 0
  for line in each_line(s) do
    local lw = strlen_utf8(line)
    if w < lw then
      w = lw
    end
    h = h + 1
  end
  return w, h
end

-- PUBLIC

local notes = {}

function Doc(body, meta, vars)
  local buf = rstrip(body)
  if #notes > 0 then
    buf = buf .. '\n\n' .. string.rep('-', 80) .. '\n'
    for i, n in ipairs(notes) do
      buf = buf .. string.format('\n[%d] %s', i, n)
    end
  end
  return buf
end

function Str(s)
  return s
end

function Space()
  return ' '
end

function LineBreak()
  return '\n'
end

function Emph(s)
  return enclose('i', s)
end

function Strong(s)
  return enclose('b', s)
end

function Subscript(s)
  return enclose('size', s, '70')
end

function Superscript(s)
  return '^' .. s
end

function SmallCaps(s)
  return s
end

function Strikeout(s)
  return enclose('s', s)
end

function Link(s, src, title)
  return enclose('url', s, src)
end

function Image(s, src, title)
  return enclose('img', src)
end

function CaptionedImage(src, attr, title)
  return enclose('img', src)
end

function Code(s, attr)
  return enclose('u', s)
end

function InlineMath(s)
  return s
end

function DisplayMath(s)
  return s
end

function Note(s)
  table.insert(notes, s)
  return string.format('[%d]', #notes)
end

function Span(s, attr)
  return s
end

function Plain(s)
  return s
end

function Para(s)
  return s .. '\n'
end

function Header(level, s, attr)
  if level == 1 then
    return enclose('b', enclose('size', s, '200')) .. '\n'
  elseif level == 2 then
    return enclose('b', enclose('size', s, '180')) .. '\n'
  else
    return enclose('b', enclose('size', s, '140')) .. '\n'
  end
end

function BlockQuote(s)
  s = rstrip(s)
  local a, t = s:match('@([%w]+):?(.+)')
  if a then
    t = t:gsub('^[ \n]+', '')
    if a == 'spoiler' then
      return enclose('spoiler', t)
    end
    return enclose('quote', t, '"' .. a .. '"')
  else
    return enclose('quote', s)
  end
end

function Cite(s)
  return s
end

function Blocksep(s)
  return '\n'
end

function HorizontalRule(s)
  return string.rep('-', 80) .. '\n'
end

function CodeBlock(s, attr)
  return enclose('code', s)
end

local function makelist(items, ltype)
  local buf = ''
  for _, e in ipairs(items) do
    buf = buf .. '[*]' .. rstrip(e)
  end
  return enclose('list', buf, ltype) .. '\n'
end

function BulletList(items)
  return makelist(items)
end

function OrderedList(items)
  return makelist(items, '1')
end

function DefinitionList(items)
  local buf = ''
  local function mkdef(k,v)
    return string.format("%s: %s\n", enclose('b', k), v)
  end
  for _,e in ipairs(items) do
    for k,v in pairs(items) do
      buf = buf .. mkdef(k,v)
    end
  end
  return buf
end

function Table(cap, align, widths, headers, rows)
  -- Determine the width of each column
  local charw = {}
  local charh = {}
  charh[0] = 0
  for i, s in ipairs(headers) do
    local w, h = strsize(s)
    if charh[0] < h then
      charh[0] = h
    end
    charw[i] = w
  end
  for j, row in ipairs(rows) do
    charh[j] = 0
    for i, s in ipairs(row) do
      local w, h = strsize(s)
      if charw[i] < w then
        charw[i] = w
      end
      if charh[j] < h then
        charh[j] = h
      end
    end
  end

  -- Closures
  local function align_str(s, w, align)
    local diff = w - strlen_utf8(s)
    if align == 'AlignCenter' then
      local left = math.floor(diff / 2)
      local right = diff - left
      return string.rep(' ', left) .. s .. string.rep(' ', right)
    elseif align == 'AlignRight' then
      return string.rep(' ', diff) .. s
    else
      return s .. string.rep(' ', diff)
    end
  end

  local function hrule()
    local buf = '+'
    for _, w in ipairs(charw) do
      buf = buf .. string.rep('-', w + 2) .. '+'
    end
    return buf
  end

  local function row(row, h)
    local buf = {}
    for i = 1, h do
      buf[i] = '|'
    end
    for i, s in ipairs(row) do
      local w = charw[i]
      local j = 1
      for line in each_line(s) do
        buf[j] = buf[j] .. ' ' .. align_str(line, w, align[i]) .. ' |'
        j = j + 1
      end
    end
    return table.concat(buf, '\n')
  end

  -- Construct table
  local buf = hrule() .. '\n'
  buf = buf .. row(headers, charh[0]) .. '\n'
  buf = buf .. hrule() .. '\n'
  for i, r in ipairs(rows) do
    buf = buf .. row(r, charh[i]) .. '\n'
  end
  buf = buf .. hrule()

  return enclose('code', buf)
end

function Div(s, attr)
  return s
end

function RawInline(format, s)
  return ''
end

function SingleQuoted(lst)
  return '‘' .. lst .. '’'
end

function DoubleQuoted(lst)
  return '“' .. lst .. '”'
end

function SoftBreak()
  return ' '
end

-- boilerplate

local meta = {}
meta.__index =
  function(_, key)
    io.stderr:write(string.format("WARNING: Undefined function '%s'\n",key))
    return function() return "" end
  end
setmetatable(_G, meta)
