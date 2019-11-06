{id, find, sort, min, max, map, unlines} = require 'prelude-ls'
{name-to-raw, dasherize, natural-join} = require './util'
word-wrap = require 'word-wrap'

wordwrap = (a, b) ->
  [indent, width] = if b == undefined then
    ['', a - 1]
  else
    [' ' * a, b - a - 1]
  (text) -> word-wrap text, {indent, width, trim: true}

get-pre-text = (
  {option: main-name, short-names = [], long-names = [], type, description}:option,
  {alias-separator, type-separator, initial-indent}
  max-width
) ->
  if option.negate-name
      main-name = "no-#main-name"
      long-names = (map (-> "no-#it"), long-names) if long-names

  names = if main-name.length is 1
    [main-name] ++ short-names ++ long-names
  else
    short-names ++ [main-name] ++ long-names

  names-string = (map name-to-raw, names).join alias-separator
  names-string-len = names-string.length
  type-separator-string = if main-name is 'NUM' then '::' else type-separator
  type-separator-string-len = type-separator-string.length

  if max-width? and not option.boolean
  and initial-indent + names-string-len + type-separator-string-len + type.length > max-width
    wrap = wordwrap (initial-indent + names-string-len + type-separator-string-len), max-width
    "#names-string#type-separator-string#{ wrap type .replace /^\s+/ ''}"
  else
    "#names-string#{ if option.boolean then '' else "#type-separator-string#type" }"

set-help-style-defaults = (help-style) !->
  help-style.alias-separator ?= ', '
  help-style.type-separator ?= ' '
  help-style.description-separator ?= '  '
  help-style.initial-indent ?= 2
  help-style.secondary-indent ?= 4
  help-style.max-pad-factor ?= 1.5

generate-help-for-option = (get-option, {stdout, help-style = {}}) ->
  set-help-style-defaults help-style
  (option-name) ->
    max-width = if stdout?.isTTY then stdout.columns - 1 else null
    wrap = if max-width then wordwrap max-width else id

    try
      option = get-option(dasherize option-name)
    catch
      return e.message

    pre = get-pre-text option, help-style

    default-string = if option.default and not option.negate-name
      "\ndefault: #{option.default}"
    else
      ''

    rest-positional-string = if option.rest-positional then 'Everything after this option is considered a positional argument, even if it looks like an option.' else ''
    description = option.long-description or option.description and sentencize option.description
    full-description = if description and rest-positional-string
      "#description #rest-positional-string"
    else if description or rest-positional-string
      that
    else
      ''
    pre-description = 'description:'
    description-string = if not full-description
      ''
    else if max-width and full-description.length - 1 - pre-description.length > max-width
      "\n#pre-description\n#{ wrap full-description }"
    else
      "\n#pre-description #full-description"

    example-string = if option.example
      examples = [].concat that
      if examples.length > 1
        "\nexamples:\n#{ unlines examples }"
      else
        "\nexample: #{examples.0}"
    else
      ''

    seperator = if default-string or description-string or example-string then "\n#{ '=' * pre.length }" else ''
    "#pre#seperator#default-string#description-string#example-string"

generate-help = ({options, prepend, append, help-style = {}, stdout}) ->
  set-help-style-defaults help-style
  {
    alias-separator, type-separator, description-separator,
    max-pad-factor, initial-indent, secondary-indent
  } = help-style

  ({show-hidden, interpolate} = {}) ->
    max-width = if stdout?.isTTY then stdout.columns - 1 else null

    output = []
    out = -> output.push it ? ''

    if prepend
      out (if interpolate then interp prepend, interpolate else prepend)
      out!

    data = []
    option-count = 0
    total-pre-len = 0
    pre-lens = []

    for item in options when show-hidden or not item.hidden
      if item.heading
        data.push {type: 'heading', value: that}
      else
        pre = get-pre-text item, help-style, max-width
        desc-parts = []
        desc-parts.push that if item.description?
        desc-parts.push "either: #{ natural-join that }" if item.enum
        desc-parts.push "default: #{item.default}" if item.default and not item.negate-name
        desc = desc-parts.join ' - '
        data.push {type: 'option', pre, desc: desc, desc-len: desc.length}
        pre-len = pre.length
        option-count++
        total-pre-len += pre-len
        pre-lens.push pre-len

    sorted-pre-lens = sort pre-lens
    max-pre-len = sorted-pre-lens[*-1]

    pre-len-mean = initial-indent + total-pre-len / option-count
    x = if option-count > 2 then min pre-len-mean * max-pad-factor, max-pre-len else max-pre-len

    for pre-len in sorted-pre-lens by -1
      if pre-len <= x
        pad-amount = pre-len
        break

    desc-sep-len = description-separator.length

    if max-width?
      full-wrap-count = 0
      partial-wrap-count = 0
      for item in data when item.type is 'option'
        {pre, desc, desc-len} = item
        if desc-len is 0
          item.wrap = 'none'
        else
          pre-len = (max pad-amount, pre.length) + initial-indent + desc-sep-len
          total-len = pre-len + desc-len
          if total-len > max-width
            if desc-len / 2.5 > max-width - pre-len
              full-wrap-count++
              item.wrap = 'full'
            else
              partial-wrap-count++
              item.wrap = 'partial'
          else
            item.wrap = 'none'

    initial-space = ' ' * initial-indent
    wrap-all-full = option-count > 1 and full-wrap-count + partial-wrap-count * 0.5 > option-count * 0.5

    for item, i in data
      if item.type is 'heading'
        out! unless i is 0
        out "#{item.value}:"
      else
        {pre, desc, desc-len, wrap} = item
        if max-width?
          if wrap-all-full or wrap is 'full'
            wrap = wordwrap (initial-indent + secondary-indent), max-width
            out "#initial-space#pre\n#{ wrap desc }"
            continue
          else if wrap is 'partial'
            wrap = wordwrap (initial-indent + desc-sep-len + max pad-amount, pre.length), max-width
            out "#initial-space#{ pad pre, pad-amount }#description-separator#{ wrap desc .replace /^\s+/, ''}"
            continue
        if desc-len is 0
          out "#initial-space#pre"
        else
          out "#initial-space#{ pad pre, pad-amount }#description-separator#desc"

    if append
      out!
      out (if interpolate then interp append, interpolate else append)

    unlines output

function pad str, num
  len = str.length
  pad-amount = (num - len)
  "#str#{ ' ' * (if pad-amount > 0 then pad-amount else 0)}"

function sentencize str
  first = str.char-at 0 .to-upper-case!
  rest = str.slice 1
  period = if /[\.!\?]$/.test str then '' else '.'
  "#first#rest#period"

function interp string, object
  string.replace /{{([a-zA-Z$_][a-zA-Z$_0-9]*)}}/g, (, key) -> object[key] ? "{{#key}}"

module.exports = {generate-help, generate-help-for-option}
