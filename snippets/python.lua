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

local function transform_snake_to_words(args, _)
  return string
    .gsub(args[1][1], '_(%w)', function(w)
      return ' ' .. w:upper()
    end)
    :gsub(' Ids$', 's')
    :gsub(' Id$', '')
    :gsub('^%l', string.upper)
end

table.insert(
  snippets,
  s(
    {
      trig = 'omanifest',
      name = 'Manifest',
      desc = 'Odoo manifest file',
    },
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

table.insert(snippets, s({ trig = 'oimp', name = 'Odoo imports', desc = 'Odoo Standard imports' }, { t 'from odoo import _, api, fields, models' }))
table.insert(
  snippets,
  s({ trig = 'oimpe', name = 'Odoo Exception Imports', desc = 'Exception imports' }, {
    t 'from odoo.exceptions import ',
    c(1, { t 'UserError', t 'ValidationError', t 'RedirectWarning', t 'AccessDenied', t 'AccessError', t 'CacheMiss', t 'MissingError' }),
  })
)
table.insert(
  snippets,
  s(
    { trig = 'oimpl', name = 'Odoo Logging imports', desc = 'Logging imports and logger variable definition' },
    t { 'import logging', '_logger = logging.getLogger(__name__)' }
  )
)

table.insert(
  snippets,
  s(
    { trig = 'omod', name = 'Odoo Model definition', desc = 'Odoo Model Body' },
    fmt(
      [[
class {className}(models.{modelType}):
    {newOrInherit} = "{modelName}"

    {finish}
]],
      {
        className = i(1, 'ClassName'),
        modelType = c(2, { t 'Model', t 'AbstractModel', t 'TransientModel' }),
        newOrInherit = c(3, { t '_name', t '_inherit' }),
        modelName = f(transform_model_to_technical, { 1 }),
        finish = i(0),
      }
    )
  )
)

table.insert(
  snippets,
  s(
    { trig = 'omodf', name = 'Odoo Model File', desc = 'Odoo Imports and Model Body' },
    fmt(
      [[
from odoo import _, api, fields, models

class {className}(models.{modelType}):
    {newOrInherit} = "{modelName}"

    {finish}

]],
      {
        className = i(1, 'ClassName'),
        modelType = c(2, { t 'Model', t 'AbstractModel', t 'TransientModel' }),
        newOrInherit = c(3, { t '_name', t '_inherit' }),
        modelName = f(transform_model_to_technical, { 1 }),
        finish = i(0),
      }
    )
  )
)

for _, key in pairs { 'binary', 'boolean', 'char', 'date', 'datetime', 'float', 'html', 'integer', 'monetary', 'text' } do
  table.insert(
    snippets,
    s(('of' .. key), {
      i(1, 'field_name'),
      t(' = fields.' .. string.gsub(key, '^%l', string.upper) .. '(string="'),
      f(transform_snake_to_words, { 1 }),
      t '"',
      i(0),
      t ')',
    })
  )

  table.insert(
    snippets,
    s(('ofr' .. key), {
      i(1, 'field_name'),
      t(' = fields.' .. string.gsub(key, '^%l', string.upper) .. '(string="'),
      f(transform_snake_to_words, { 1 }),
      t '", related="',
      i(2, 'related_field.field_name'),
      t '"',
      i(0),
      t ')',
    })
  )

  table.insert(
    snippets,
    s(
      ('ofc' .. key),
      fmt(
        [[
        {fieldName} = fields.{fieldType}(string="{fieldString}", compute="_compute_{fieldName}")

        @api.depends("{depends}")
        def _compute_{fieldName}(self):
          for record in self:
            record.{fieldName} = {fieldValue}
      ]],
        {
          fieldName = i(1, 'field_name'),
          fieldType = string.gsub(key, '^%l', string.upper),
          fieldString = f(transform_snake_to_words, { 1 }),
          depends = i(2, 'field1'),
          fieldValue = i(3, 'x'),
        },
        { repeat_duplicates = true }
      )
    )
  )

  table.insert(
    snippets,
    s(
      ('ofci' .. key),
      fmt(
        [[
        {fieldName} = fields.{fieldType}(string="{fieldString}", compute="_compute_{fieldName}", inverse="_inverse_{fieldName}")

        @api.depends("{depends}")
        def _compute_{fieldName}(self):
          for record in self:
            {fieldValue}

        def _inverse_{fieldName}(self):
          for record in self:
            {eos}
      ]],
        {
          fieldName = i(1),
          fieldType = string.gsub(key, '^%l', string.upper),
          fieldString = f(transform_snake_to_words, { 1 }),
          depends = i(2, 'field1'),
          fieldValue = i(3, 'pass'),
          eos = i(0, 'pass'),
        },
        { repeat_duplicates = true }
      )
    )
  )
end

local odoo_field_parameters = function()
  local common_params = {
    sn(nil, { t 'string="', i(1, 'Name'), t '"' }),
    sn(nil, { t 'help="', i(1, 'help text'), t '"' }),
    sn(nil, { t 'invisible=', i(1, 'False') }),
    sn(nil, { t 'required=', i(1, 'False') }),
    sn(nil, { t 'index=', i(1), c(2, { t 'False', t '"btree"', t '"btree_not_null"', t '"trigram"' }) }),
    sn(nil, { t 'default=', i(1, 'none') }),
    sn(nil, { t 'states=', t '{ "', i(1, 'state_name'), t '": [("readonly", False), ("required", False), ("invisible", False)] }' }),
    sn(nil, { t 'groups="', i(1, 'base.group_users'), t '"' }),
    sn(nil, { t 'company_dependent=', i(1, 'True') }),
    sn(nil, { t 'copy=', i(1, 'True') }),
    sn(nil, { t 'store=', i(1, 'True') }),
    sn(nil, {
      t 'group_operator=',
      i(1),
      c(2, { t '"array_agg"', t '"count"', t '"count_distinct"', t '"bool_and"', t '"bool_or"', t '"max"', t '"min"', t '"avg"', t '"sum"' }),
    }),
    sn(nil, { t 'group_expand="', i(1, '_read_group_method'), t '"' }),
  }
  local special_params = {
    Binary = {
      sn(nil, { t 'attachment=', i(1, 'True') }),
    },
    Char = {
      sn(nil, { t 'size=', i(1, '256') }),
      sn(nil, { t 'trim=', i(1, 'True') }),
      sn(nil, { t 'translate=', i(1, 'False') }),
    },
    Float = {
      sn(nil, { t 'digits=(', i(1, '8, 2'), t ')' }),
    },
    Html = {
      sn(nil, { t 'sanitize=', i(1, 'True') }),
      sn(nil, { t 'sanitize_overridable=', i(1, 'False') }),
      sn(nil, { t 'sanitize_tags=', i(1, 'True') }),
      sn(nil, { t 'sanitize_attributes=', i(1, 'True') }),
      sn(nil, { t 'sanitize_style=', i(1, 'False') }),
      sn(nil, { t 'strip_style=', i(1, 'False') }),
      sn(nil, { t 'strip_classes=', i(1, 'False') }),
    },
    Image = {
      sn(nil, { t 'max_width=', i(1, '0') }),
      sn(nil, { t 'max_height=', i(1, '0') }),
      sn(nil, { t 'verify_resolution=', i(1, 'True') }),
    },
    Monetary = {
      sn(nil, { t 'currency_field=', i(1, '"currency_id"') }),
    },
    Text = {
      sn(nil, { t 'translate=', i(1, 'False') }),
    },
  }
  local node = vim.treesitter.get_node()
  if not node or tostring(node:type()) ~= 'argument_list' then
    vim.notify 'Not in a function call'
    return sn(nil, t '')
  end
  local previous_node = node:prev_sibling()
  if not previous_node or tostring(previous_node:type()) ~= 'attribute' or previous_node:named_child_count() ~= 2 then
    vim.notify 'Not in a field function call'
    return sn(nil, t '')
  end
  local maybe_attribute_node = previous_node:named_child(1)
  if not maybe_attribute_node then
    vim.notify 'Not in a field function call'
    return sn(nil, t '')
  end
  if tostring(maybe_attribute_node:type()) ~= 'identifier' then
    vim.notify('Not in a field function call' .. maybe_attribute_node:type())
    return sn(nil, t '')
  end

  local field_type_table = special_params[vim.treesitter.get_node_text(maybe_attribute_node, 0)]
  if not field_type_table then
    field_type_table = {}
  end
  for idx = 1, #common_params do
    field_type_table[#field_type_table + 1] = common_params[idx]
  end
  return sn(nil, c(1, field_type_table))
end

table.insert(snippets, s({ trig = 'ofparam', name = 'field function params' }, { d(1, odoo_field_parameters) }))

table.insert(
  snippets,
  s('ofone2many', { i(1, 'field_name'), t ' = fields.One2many(string="', f(transform_snake_to_words, { 1 }), t '", comodel_name="', i(2), t '"', i(0), t ')' })
)
table.insert(
  snippets,
  s('ofmany2one', {
    i(1, 'field_name'),
    t ' = fields.Many2one(string="',
    f(transform_snake_to_words, { 1 }),
    t '", comodel_name="',
    i(2),
    t '", inverse_name="',
    i(3),
    t '"',
    i(0),
    t ')',
  })
)
table.insert(
  snippets,
  s(
    'ofmany2many',
    { i(1, 'field_name'), t ' = fields.Many2many(string="', f(transform_snake_to_words, { 1 }), t '", comodel_name="', i(2), t '"', i(0), t ')' }
  )
)
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
        fieldName = i(1, 'field_name'),
        fieldString = f(transform_snake_to_words, { 1 }),
        fieldSelection = i(2, '("key1", "value1"), ("key2", "value2")'),
        fieldDefault = d(3, get_keys, { 2 }),
        fieldDefaultEnd = i(0),
      }
    )
  )
)

table.insert(
  snippets,
  s({ trig = 'ofonchange', name = 'onchange method', desc = 'onchange method which is executed on field change' }, {
    t '@api.onchange("',
    i(1, 'field_name'),
    t { '")', 'def _onchange_' },
    rep(1),
    t { '(self):', '    ' },
    i(0, 'pass'),
  })
)
return snippets, autosnippets
