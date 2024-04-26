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

local function transform_snake_to_dot(args, _)
  return string.gsub(args[1][1], '_', '.')
end

table.insert(
  snippets,
  s({ trig = 'odoo' }, {
    t { '<?xml version="1.0" encoding="UTF-8"?>', '<odoo>', '    ' },
    i(0),
    t { '', '</odoo>' },
  })
)

table.insert(
  snippets,
  s({ trig = 'odata' }, {
    t { '<data' },
    c(1, { t ' noupdate="1"', t '' }),
    t { '>', '    ' },
    i(0),
    t { '', '</data>' },
  })
)

local odoo_view_attributes = function()
  local all_attribute_values = {
    activity = { 'string' },
    calendar = {
      'date_start',
      'date_stop',
      'date_delay',
      'color',
      'form_view_id',
      'event_open_popup',
      'quick_add',
      'create_name_field',
      'all_day',
      'mode',
      'scales',
      'create',
      'delete',
      'field',
    },
    cohort = { 'string', 'date_start', 'date_stop', 'mode', 'timeline', 'interval', 'measure', 'field' },
    gant = {
      'date_start',
      'date_stop',
      'dependency_field',
      'dependency_inverted_field',
      'color',
      'decoration-danger',
      'decoration-info',
      'decoration-secondary',
      'decoration-success',
      'decoration-warning',
      'default_group_by',
      'disable_drag_drop',
      'consolidation',
      'consolidation_max',
      'consolidation_exclude',
      'create',
      'cell_create',
      'edit',
      'delete',
      'plan',
      'offset',
      'progress',
      'string',
      'precision',
      'total_row',
      'collapse_first_level',
      'display_unavailability',
      'default_scale',
      'scales',
      'templates',
      'form_view_id',
      'dynamic_range',
      'pill_label',
      'thumbnails',
    },
    graph = { 'type', 'stacked', 'disable_linking', 'order', 'string' },
    grid = {
      'string',
      'create',
      'edit',
      'delete',
      'adjustment',
      'adjust_name',
      'hide_line_total',
      'hide_column_total',
      'barchart_total',
      'create_inline',
      'display_empty',
    },
    kanban = {
      'default_group_by',
      'default_order',
      'class',
      'examples',
      'group_create',
      'group_delete',
      'group_edit',
      'archivable',
      'quick_create',
      'quick_create_view',
      'records_draggable',
      'groups_draggable',
    },
    map = { 'res_partner', 'default_order', 'routing', 'hide_name', 'hide_address', 'hide_title', 'panel_title', 'limit' },
    pivot = { 'disable_linking', 'disable_quantity', 'default_order' },
    tree = {
      'editable',
      'multi_edit',
      'default_order',
      'decoration-danger',
      'decoration-info',
      'decoration-muted',
      'decoration-primary',
      'decoration-success',
      'decoration-warning',
      'create',
      'edit',
      'delete',
      'import',
      'export_xlsx',
      'limit',
      'groups_limit',
      'expand',
    },
    search = {},
  }
  local node = vim.treesitter.get_node()
  if not node then
    vim.notify 'No node'
    return sn(nil, t '')
  end
  while tostring(node:type()) ~= 'STag' do
    if tostring(node:type()) == 'element' and node:named_child_count() >= 1 and tostring(node:named_child(0):type()) == 'STag' then
      node = node:named_child(0)
    else
      node = node:parent()
    end
    if not node then
      vim.notify 'No parent'
      return sn(nil, t '')
    end
  end
  if node:named_child_count() < 1 then
    vim.notify 'Not enough children in STag'
    return sn(nil, t '')
  end
  local view_name = vim.treesitter.get_node_text(node:named_child(0), 0)
  local available_attributes = all_attribute_values[view_name]
  if not available_attributes then
    return sn(nil, t '')
  end
  local result = {}
  for _, attribute in pairs(available_attributes) do
    table.insert(result, sn(nil, { t(attribute .. '="'), i(1), t '"' }))
  end
  return sn(nil, c(1, result))
end

table.insert(snippets, s({ trig = 'oattr' }, { d(1, odoo_view_attributes) }))

for _, view_type in pairs { 'activity', 'calendar', 'cohort', 'form', 'gant', 'graph', 'grid', 'kanban', 'map', 'pivot', 'tree', 'search' } do
  local mandatory_attribute_values = {
    activity = sn(nil, { t ' string="', i(1), t '"' }),
    calendar = sn(nil, { t ' date_start="', i(1, 'date_field'), t '"' }),
    cohort = sn(nil, { t ' string="', i(1), t '" date_start="', i(2, 'date_field'), t '" date_stop="', i(3, 'date_field'), t '"' }),
    form = sn(nil, {}),
    gant = sn(nil, { t ' date_start="', i(1, 'date_field'), t '"' }),
    graph = sn(nil, {}),
    grid = sn(nil, { t ' string="', i(1), t '"' }),
    kanban = sn(nil, {}),
    map = sn(nil, {}),
    pivot = sn(nil, {}),
    tree = sn(nil, {}),
    search = sn(nil, {}),
  }

  local mandatory_attributes = function(_, _, _, view_type_name)
    return mandatory_attribute_values[view_type_name]
  end
  table.insert(
    snippets,
    s(
      ('o' .. view_type),
      fmt(
        [[
          <record id="{modelSnake}_view_{viewType}" model="ir.ui.view">
              <field name="name">{name}</field>
              <field name="model">{modelDot}</field>
              <field name="arch" type="xml">
                  <{viewType}{mandatoryAttributes}>
                    {finish}
                  </{viewType}>
              </field>
          </record>
          ]],
        {
          modelSnake = i(1, 'model_name'),
          viewType = t { view_type },
          name = i(2, 'View Name'),
          modelDot = f(transform_snake_to_dot, { 1 }),
          mandatoryAttributes = d(3, mandatory_attributes, {}, { user_args = { view_type } }),
          finish = i(0),
        },
        { repeat_duplicates = true }
      )
    )
  )

  table.insert(
    snippets,
    s(
      ('o' .. view_type .. 'i'),
      fmt(
        [[
          <record id="{modelSnake}_view_{viewType}" model="ir.ui.view">
              <field name="name">{name}</field>
              <field name="inherit_id" ref="{inheritId}"/>
              <field name="model">{modelDot}</field>
              <field name="arch" type="xml">
                  {finish}
              </field>
          </record>
          ]],
        {
          modelSnake = i(1, 'model_name'),
          viewType = t { view_type },
          name = i(2, 'View Name'),
          inheritId = i(3, 'inherit_id'),
          modelDot = f(transform_snake_to_dot, { 1 }),
          finish = i(0),
        }
      )
    )
  )
end

table.insert(
  snippets,
  s(
    { trig = 'oform' },
    fmt(
      [[
  <record id="{modelSnake}_view_form" model="ir.ui.view">
      <field name="name">{name}</field>
      <field name="model">{modelDot}</field>
      <field name="arch" type="xml">
          <form string="{formString}">{maybeHeader}
              <sheet>{maybeButtonBox}
                  <group>
                      <group>
                          <field name="{finish}" />
                      </group>
                  </group>
              </sheet>
          </form>
      </field>
  </record>
  ]],
      {
        modelSnake = i(1, 'model_name'),
        name = i(2, 'Form Name'),
        modelDot = f(transform_snake_to_dot, { 1 }),
        formString = i(3, 'Form String'),
        maybeHeader = c(4, { t { '', '            <header>', '            </header>' }, t '' }),
        maybeButtonBox = c(5, { t { '', '                <div class="oe_button_box">', '                </div>' }, t '' }),
        finish = i(0),
      }
    )
  )
)

table.insert(
  snippets,
  s(
    { trig = 'onote', name = 'Form Notebook' },
    fmt(
      [[
    <notebook>
      <page string="{pageName}">
        <group>
          <field name="{finish}" />
        </group>
      </page>
    </notebook>
]],
      { pageName = i(1, 'Page1'), finish = i(0) }
    )
  )
)

table.insert(
  snippets,
  s(
    { trig = 'osheet', name = 'Form Sheet' },
    fmt(
      [[
  <sheet>
      <group>
          <group>
              <field name="{finish}" />
          </group>
      </group>
  </sheet>
]],
      { finish = i(0) }
    )
  )
)

table.insert(snippets, s({ trig = 'ofield' }, { t '<field name="', i(0, 'field_name'), t '" />' }))
table.insert(
  snippets,
  s({ trig = 'ofattr', name = 'Field Attributes' }, {
    c(1, {
      sn(nil, { t 'widget="', i(1), t '"' }),
      sn(nil, { t 'groups="', i(1), t '"' }),
      sn(nil, { t 'on_change="', i(1), t '"' }),
      sn(nil, { t 'attrs="', i(1), t '"' }),
      sn(nil, { t 'domain="[', i(1), t ']"' }),
      sn(nil, { t 'context="{', i(1), t '}"' }),
      sn(nil, { t 'placeholder="', i(1), t '"' }),
      sn(nil, { t 'help="', i(1), t '"' }),
      sn(nil, { t 'mode="', i(1), t '"' }),
      sn(nil, { t 'class="', i(1), t '"' }),
      sn(nil, { t 'options="', i(1), t '"' }),
      sn(nil, { t 'filename="', i(1), t '"' }),
      sn(nil, { t 'readonly="', i(1, '1'), t '"' }),
      sn(nil, { t 'requried="', i(1, '1'), t '"' }),
      sn(nil, { t 'nolabel="', i(1, '1'), t '"' }),
      sn(nil, { t 'password="', i(1, '1'), t '"' }),
    }),
  })
)

return snippets, autosnippets
