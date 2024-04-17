local ls = require 'luasnip'
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local rep = require('luasnip.extras').rep
local fmt = require('luasnip.extras.fmt').fmt

local snippets, autosnippets = {}, {}

local function get_keys(args, _)
  local key_value_pairs = args[1][1]
  if type(key_value_pairs) ~= 'string' then
    return sn(nil, c(1, { t 'default' }))
  end
  local pattern = '%("(.-)",'
  if not string.match(key_value_pairs, pattern) then
    return sn(nil, c(1, { t 'default' }))
  end
  local keys = {}
  for key in string.gmatch(key_value_pairs, pattern) do
    table.insert(keys, t(key))
  end
  return sn(nil, c(1, keys))
end

local function transform_model_to_technical(args, _)
  return string.gsub(args[1][1], '(.)(%u)', '%1.%2'):lower()
end

local function transform_snake_to_camel(args, _)
  return string
    .gsub(args[1][1], '_(%w)', function(w)
      return w:upper()
    end)
    :gsub('^%l', string.upper)
end

table.insert(
  snippets,
  s(
    'manifest',
    fmt(
      [[
{{
  "name": "{1}",
  "version": "{2}",
  "description": "{3}",
  "summary": "{4}",
  "author": "{5}",
  "website": "{6}",
  "license": "{7}",
  "category": "{8}",
  "depends": [
    "{9}"
  ],
  "data": [
    "{10}"
  ],
  "demo": [
    "{11}"
  ],
  "auto_install": {12},
  "application": {13},
  "assets": {{
  }}
}}
]],
      {
        i(1),
        i(2, '0.1'),
        i(3),
        i(4),
        i(5),
        i(6),
        c(7, { t 'LGPL-3', t 'OPL-1' }),
        i(8),
        i(9),
        i(10),
        i(11),
        c(12, {
          t 'False',
          t 'True',
        }),
        c(13, {
          t 'False',
          t 'True',
        }),
      }
    )
  )
)

table.insert(snippets, s('oimp', t 'from odoo import _, api, fields, models'))
table.insert(
  snippets,
  s('oimpe', {
    t 'from odoo.exceptions import ',
    c(1, { t 'UserError', t 'ValidationError', t 'RedirectWarning', t 'AccessDenied', t 'AccessError', t 'CacheMiss', t 'MissingError' }),
  })
)
table.insert(snippets, s('oimpl', t { 'import logging', '_logger = logging.getLogger(__name__)' }))
table.insert(
  snippets,
  s(
    'omod',
    fmt(
      [[
class {className}(models.{modelType}):
  {newOrInherit} = "{modelName}"
  
]],
      {
        className = i(1, 'ClassName'),
        modelType = c(2, { t 'Model', t 'AbstractModel', t 'TransientModel' }),
        newOrInherit = c(3, { t '_name', t '_inherit' }),
        modelName = f(transform_model_to_technical, { 1 }),
      }
    )
  )
)

table.insert(snippets, s('ofchar', { i(1), t ' = fields.Char(string="', f(transform_snake_to_camel, { 1 }), t '"', i(0), t ')' }))
table.insert(snippets, s('oftext', { i(1), t ' = fields.Text(string="', f(transform_snake_to_camel, { 1 }), t '"', i(0), t ')' }))
table.insert(snippets, s('ofinteger', { i(1), t ' = fields.Integer(string="', f(transform_snake_to_camel, { 1 }), t '"', i(0), t ')' }))
table.insert(snippets, s('offloat', { i(1), t ' = fields.Float(string="', f(transform_snake_to_camel, { 1 }), t '"', i(0), t ')' }))
table.insert(snippets, s('ofdate', { i(1), t ' = fields.Date(string="', f(transform_snake_to_camel, { 1 }), t '"', i(0), t ')' }))
table.insert(snippets, s('ofdatetime', { i(1), t ' = fields.Datetime(string="', f(transform_snake_to_camel, { 1 }), t '"', i(0), t ')' }))
table.insert(snippets, s('ofbinary', { i(1), t ' = fields.Binary(string="', f(transform_snake_to_camel, { 1 }), t '"', i(0), t ')' }))
table.insert(snippets, s('ofmonetary', { i(1), t ' = fields.Monetary(string="', f(transform_snake_to_camel, { 1 }), t '"', i(0), t ')' }))

table.insert(
  snippets,
  s(
    'ofselection',
    fmt(
      [[
    {fieldName} = fields.Selection(
      string="{fieldString}",
      selection=[{fieldSelection}],
      default="{fieldDefault}{fieldDefaultEnd}")
    ]],
      {
        fieldName = i(1),
        fieldString = f(transform_snake_to_camel, { 1 }),
        fieldSelection = i(2, '("key1", "value1"), ("key2", "value2")'),
        fieldDefault = d(3, get_keys, { 2 }),
        fieldDefaultEnd = i(0),
      }
    )
  )
)

return snippets, autosnippets
