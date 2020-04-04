VERSION = '0.9.1'

{id, map, compact, any, group-by, partition, chars, is-it-NaN, keys, Obj, camelize} = require 'prelude-ls'
deep-is = require 'deep-is'
{closest-string, name-to-raw, dasherize, natural-join} = require './util'
{generate-help, generate-help-for-option} = require './help'
{parsed-type-check, parse-type} = require 'type-check'
{parsed-type-parse: parse-levn} = require 'levn'

camelize-keys = (obj) -> {[(camelize key), value] for key, value of obj}

parse-string = (string) ->
  assign-opt = '--?[a-zA-Z][-a-z-A-Z0-9]*='
  regex = //
      (?:#assign-opt)?(?:'(?:\\'|[^'])+'|"(?:\\"|[^"])+")
    | [^'"\s]+
  //g
  replace-regex = //^(#assign-opt)?['"]([\s\S]*)['"]$//
  result = map (.replace replace-regex, '$1$2'), (string.match regex or [])
  result

main = (lib-options) ->
  opts = {}
  defaults = {}
  required = []
  if typeof! lib-options.stdout is 'Undefined'
    lib-options.stdout = process.stdout

  lib-options.positional-anywhere ?= true
  lib-options.type-aliases ?= {}
  lib-options.defaults ?= {}
  if lib-options.concat-repeated-arrays?
    lib-options.defaults.concat-repeated-arrays = lib-options.concat-repeated-arrays
  if lib-options.merge-repeated-objects?
    lib-options.defaults.merge-repeated-objects = lib-options.merge-repeated-objects

  traverse = (options) !->
    throw new Error 'No options defined.' unless typeof! options is 'Array'

    for option in options when not option.heading?
      name = option.option
      throw new Error "Option '#name' already defined." if opts[name]?

      for k, v of lib-options.defaults
        option[k] ?= v

      option.boolean ?= true if option.type is 'Boolean'

      unless option.parsed-type?
        throw new Error "No type defined for option '#name'." unless option.type
        try
            type = if lib-options.type-aliases[option.type]? then that else option.type
            option.parsed-type = parse-type type
        catch
          throw new Error "Option '#name': Error parsing type '#{option.type}': #{e.message}"

      if option.default
        try
          defaults[name] = parse-levn option.parsed-type, option.default
        catch
          throw new Error "Option '#name': Error parsing default value '#{option.default}' for type '#{option.type}': #{e.message}"

      if option.enum and not option.parsed-possiblities
        parsed-possibilities = []
        parsed-type = option.parsed-type
        for possibility in option.enum
          try
              parsed-possibilities.push parse-levn parsed-type, possibility
          catch
            throw new Error "Option '#name': Error parsing enum value '#possibility' for type '#{option.type}': #{e.message}"
        option.parsed-possibilities = parsed-possibilities

      if option.depends-on
        if that.length
          [raw-depends-type, ...depends-opts] = [].concat option.depends-on
          depends-type = raw-depends-type.to-lower-case!
          if depends-opts.length
            if depends-type in <[ and or ]>
              option.depends-on = [depends-type, ...depends-opts]
            else
              throw new Error "Option '#name': If you have more than one dependency, you must specify either 'and' or 'or'"
          else
            if depends-type.to-lower-case! in <[ and or ]>
              option.depends-on = null
            else
              option.depends-on = ['and', raw-depends-type] # if only one dependency, doesn't matter and/or
        else
          option.depends-on = null

      required.push name if option.required

      opts[name] = option

      if option.concat-repeated-arrays?
        cra = option.concat-repeated-arrays
        if 'Boolean' is typeof! cra
          option.concat-repeated-arrays = [cra, {}]
        else if cra.length is 1
          option.concat-repeated-arrays = [cra.0, {}]
        else if cra.length isnt 2
          throw new Error "Invalid setting for concatRepeatedArrays"

      if option.alias or option.aliases
        throw new Error "-NUM option can't have aliases." if name is 'NUM'
        option.aliases ?= [].concat option.alias if option.alias
        for alias in option.aliases
          throw new Error "Option '#alias' already defined." if opts[alias]?
          opts[alias] = option
        [short-names, long-names] = partition (.length is 1), option.aliases
        option.short-names ?= short-names
        option.long-names ?= long-names

      if (not option.aliases or option.short-names.length is 0)
         and option.type is 'Boolean' and option.default is 'true'
          option.negate-name = true

  traverse lib-options.options

  get-option = (name) ->
    opt = opts[name]
    unless opt?
      possibly-meant = closest-string (keys opts), name
      throw new Error "Invalid option '#{ name-to-raw name}'#{ if possibly-meant then " - perhaps you meant '#{ name-to-raw possibly-meant }'?" else '.'}"
    opt

  parse = (input, {slice} = {}) ->
    obj = {}
    positional = []
    rest-positional = false
    override-required = false
    prop = null

    set-value = (name, value) !->
      opt = get-option name
      if opt.boolean
        val = value
      else
        try
          cra = opt.concat-repeated-arrays
          if cra? and cra.0 and cra.1.one-value-per-flag
          and opt.parsed-type.length is 1 and opt.parsed-type.0.structure is 'array'
            val = [parse-levn opt.parsed-type.0.of, value]
          else
            val = parse-levn opt.parsed-type, value
        catch
          throw new Error "Invalid value for option '#name' - expected type #{opt.type}, received value: #value."
        if opt.enum and not any (-> deep-is it, val), opt.parsed-possibilities
          throw new Error "Option #name: '#val' not one of #{ natural-join opt.enum }."

      current-type = typeof! obj[name]
      if obj[name]?
        if opt.concat-repeated-arrays? and opt.concat-repeated-arrays.0 and current-type is 'Array'
          obj[name] ++= val
        else if opt.merge-repeated-objects and current-type is 'Object'
          obj[name] <<< val
        else
          obj[name] = val
      else
        obj[name] = val
      rest-positional := true if opt.rest-positional
      override-required := true if opt.override-required

    set-defaults = !->
      for name, value of defaults
        unless obj[name]?
          obj[name] = value

    check-required = !->
      return if override-required
      for name in required
        throw new Error "Option #{ name-to-raw name} is required." unless obj[name]

    mutually-exclusive-error = (first, second) ->
        throw new Error "The options #{ name-to-raw first } and #{ name-to-raw second } are mutually exclusive - you cannot use them at the same time."

    check-mutually-exclusive = !->
      rules = lib-options.mutually-exclusive
      return unless rules

      for rule in rules
        present = null
        for element in rule
          if typeof! element is 'Array'
            for opt in element
              if opt of obj
                if present?
                  mutually-exclusive-error present, opt
                else
                  present = opt
                  break
          else
            if element of obj
              if present?
                mutually-exclusive-error present, element
              else
                present = element

    check-dependency = (option) ->
      depends-on = option.depends-on
      return true if not depends-on or option.dependencies-met
      [type, ...target-option-names] = depends-on
      for target-option-name in target-option-names
        target-option = obj[target-option-name]
        if target-option and check-dependency target-option
          return true if type is 'or' # we only need one dependency to be met for "or"
        else if type is 'and'
          throw new Error "The option '#{option.option}' did not have its dependencies met."
      if type is 'and'
        true # no errors with "and", thus we're good
      else # type is 'or' - no dependencies were met, thus no good
        throw new Error "The option '#{option.option}' did not meet any of its dependencies."

    check-dependencies = !->
      for name of obj
        check-dependency opts[name]

    check-prop = !->
      if prop
        throw new Error "Value for '#prop' of type '#{ get-option prop .type}' required."

    switch typeof! input
    | 'String'
      args = parse-string input.slice slice ? 0
    | 'Array'
      args = input.slice (slice ? 2) # slice away "node" and "filename" by default
    | 'Object'
      obj = {}
      for key, value of input when key isnt '_'
        option = get-option (dasherize key)
        if parsed-type-check option.parsed-type, value
          obj[option.option] = value
        else
          throw new Error "Option '#{option.option}': Invalid type for '#value' - expected type '#{option.type}'."
      check-mutually-exclusive!
      check-dependencies!
      set-defaults!
      check-required!
      return (camelize-keys obj) <<< {_: input._ or []}
    | otherwise
      throw new Error "Invalid argument to 'parse': #input."

    for arg in args
      if arg is '--'
        rest-positional := true
      else if rest-positional
        positional.push arg
      else
        if arg.match /^(--?)([a-zA-Z][-a-zA-Z0-9]*)(=)?(.*)?$/
          result = that
          check-prop!

          short = result.1.length is 1
          arg-name = result.2
          using-assign = result.3?
          val = result.4
          throw new Error "No value for '#arg-name' specified." if using-assign and not val?

          if short
            flags = chars arg-name
            len = flags.length
            for flag, i in flags
              opt = get-option flag
              name = opt.option
              if rest-positional
                positional.push flag
              else if i is len - 1
                if using-assign
                  val-prime = if opt.boolean then parse-levn [type: 'Boolean'], val else val
                  set-value name, val-prime
                else if opt.boolean
                  set-value name, true
                else
                  prop := name
              else if opt.boolean
                set-value name, true
              else
                throw new Error "Can't set argument '#flag' when not last flag in a group of short flags."
          else
            negated = false
            if arg-name.match /^no-(.+)$/
              negated = true
              noed-name = that.1
              opt = get-option noed-name
            else
              opt = get-option arg-name

            name = opt.option
            if opt.boolean
              val-prime = if using-assign then parse-levn [type: 'Boolean'], val else true
              if negated
                set-value name, not val-prime
              else
                set-value name, val-prime
            else
              throw new Error "Only use 'no-' prefix for Boolean options, not with '#noed-name'." if negated
              if using-assign
                set-value name, val
              else
                prop := name
        else if arg.match /^-([0-9]+(?:\.[0-9]+)?)$/
          opt = opts.NUM
          throw new Error 'No -NUM option defined.' unless opt
          set-value opt.option, that.1
        else
          if prop
            set-value prop, arg
            prop := null
          else
            positional.push arg
            rest-positional := true if not lib-options.positional-anywhere

    check-prop!

    check-mutually-exclusive!
    check-dependencies!
    set-defaults!
    check-required!
    (camelize-keys obj) <<< {_: positional}

  parse: parse
  parse-argv: -> parse it, slice: 2
  generate-help: generate-help lib-options
  generate-help-for-option: generate-help-for-option get-option, lib-options

main <<< {VERSION}
module.exports = main
