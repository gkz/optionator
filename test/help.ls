optionator = require '..'
{strict-equal: equal} = require 'assert'

q = (expected, options, args) ->
  {generate-help} = optionator options
  help-text = generate-help args
  try
    equal help-text, expected
  catch
    console.log '# Result:'
    console.log help-text
    console.log '# Expected:'
    console.log expected
    throw e

qo = (expected, option-name, options) ->
  {generate-help-for-option} = optionator options
  help-text = generate-help-for-option option-name
  try
    equal help-text, expected
  catch
    console.log '# Result:'
    console.log help-text
    console.log '# Expected:'
    console.log expected
    throw e

suite 'help' ->
  help-option =
    option: 'help'
    type: 'Boolean'
    description: 'recieve help - print this info'
  count-option =
    option: 'count'
    type: 'Number'
    description: 'count of stuff that is to be counted'
  obj-option =
    option: 'obj'
    type: '{x: Number, y: Boolean, z: Object}'
    description: 'an object full of things and stuff'

  test 'single basic option' ->
    q '  --help  recieve help - print this info', options: [help-option]

  test 'prepend/append' ->
    q '''
      cmd

        --help  recieve help - print this info

      version 0.1.0
      ''', {
      prepend: 'cmd'
      append: 'version 0.1.0'
      options: [help-option]
    }

  test 'heading' ->
    q '''
      Options:
        --help  recieve help - print this info
      ''', {
      options:
        * heading: 'Options'
        * help-option
    }

  test 'heading with prepend' ->
    q '''
      cmd

      Options:
        --help  recieve help - print this info
      ''', {
      prepend: 'cmd'
      options:
        * heading: 'Options'
        * help-option
    }

  test 'two options' ->
    q '  --help          recieve help - print this info
     \n  --count Number  count of stuff that is to be counted', {
      options: [help-option, count-option]
    }

  test 'headings' ->
    q '''
      Options:
        --help          recieve help - print this info

      More Options:
        --count Number  count of stuff that is to be counted
      ''', {
      options:
        * heading: 'Options'
        * help-option
        * heading: 'More Options'
        * count-option
    }

  test 'greatly differnt lengths' ->
    q '''
      cmd

        --help          recieve help - print this info
        --count Number  count of stuff that is to be counted
        --obj {x: Number, y: Boolean, z: Object}  an object full of things and stuff
      ''', {
      prepend: 'cmd'
      options: [help-option, count-option, obj-option]
    }

  test 'short main name' ->
    q '  -h  help me', options: [{
      option: 'h'
      type: 'Boolean'
      description: 'help me'
    }]

  test 'one alias' ->
    q '  -h, -H, --help  help me', options: [{
      option: 'help'
      alias: ['h' 'H']
      type: 'Boolean'
      description: 'help me'
    }]

  test 'enum type' ->
    q '  --size String  shirt size - either: small, medium, or large', options: [{
      option: 'size'
      type: 'String'
      enum: <[ small medium large ]>
      description: 'shirt size'
    }]

  test 'enum type, just two' ->
    q '  --size String  shirt size - either: small or large', options: [{
      option: 'size'
      type: 'String'
      enum: <[ small large ]>
      description: 'shirt size'
    }]

  test 'default' ->
    q '  --count Number  count of stuff that is to be counted - default: 2', options: [{
      option: 'count'
      type: 'Number'
      description: 'count of stuff that is to be counted'
      default: '2'
    }]

  test 'default with no description' ->
    q '  --count Number  default: 2', options: [{
      option: 'count'
      type: 'Number'
      default: '2'
    }]

  test 'default - boolean with true when no short alias' ->
    q '  --no-colour', options: [{
      option: 'colour'
      type: 'Boolean'
      default: 'true'
    }]

  test 'default - boolean with true when no short alias but long aliases' ->
    q '  --no-colour, --no-color', options: [{
      option: 'colour'
      type: 'Boolean'
      alias: 'color'
      default: 'true'
    }]

  test 'default - boolean with true with short alias' ->
    q '  -c, --colour  default: true', options: [{
      option: 'colour'
      alias: 'c'
      type: 'Boolean'
      default: 'true'
    }]

  test 'many aliases' ->
    q '  -h, -H, --halp, --help  halp me', options: [{
      option: 'halp'
      alias: ['help' 'h' 'H']
      type: 'Boolean'
      description: 'halp me'
    }]

  test 'aliases prop predefined' ->
    q '  -h, -H, --halp, --help  halp me', options: [{
      option: 'halp'
      aliases: ['help' 'h' 'H']
      type: 'Boolean'
      description: 'halp me'
    }]

  test 'NUM' ->
    q '  -NUM::Int  the number', options: [{
      option: 'NUM'
      type: 'Int'
      description: 'the number'
    }]

  test 'show hidden' ->
    opts =
      options:
        * option: 'hidden'
          type: 'Boolean'
          description: 'magic'
          hidden: true
        * option: 'visible'
          type: 'Boolean'
          description: 'boring'

    q '  --visible  boring', opts
    q '  --hidden   magic\n  --visible  boring', opts, {+show-hidden}

  suite 'interpolation' ->
    opts =
      prepend: 'usage {{x}}'
      options: [{heading: 'Options'}]
      append: 'version {{version}}'

    test 'none' ->
      q '''
        usage {{x}}

        Options:

        version {{version}}
        ''', opts

    test 'partial' ->
      q '''
        usage cmd

        Options:

        version {{version}}
        ''', opts, {interpolate: {x: 'cmd'}}

    test 'basic' ->
      q '''
        usage cmd

        Options:

        version 2
        ''', opts, {interpolate: {x: 'cmd', version: 2}}

    test 'with empty string' ->
      q '''
        usage 

        Options:

        version 
        ''', opts, {interpolate: {x: '', version: ''}}

    test 'more than once, with number' ->
      opts =
        prepend: 'usage {{$0}}, {{$0}}'
        options: [{heading: 'Options'}]
        append: '{{$0}} and {{$0}}'
      q '''
        usage xx, xx

        Options:

        xx and xx
        ''', opts, {interpolate: {$0: 'xx'}}

  test 'no stdout' ->
    q '''
      cmd

        --obj {x: Number, y: Boolean, z: Object}  an object full of things and stuff
      ''', {
      prepend: 'cmd'
      options: [obj-option]
      stdout: null
    }

  test 'no description' ->
    q '''
      cmd

        --help
      ''', {
      prepend: 'cmd'
      options: [{
        option: 'help'
        type: 'Boolean'
      }]
    }

  suite 'wrapping' ->
    test 'basic with max-width' ->
      q '''
        cmd

          --help  recieve help - print this info
        ''', {
        prepend: 'cmd'
        options: [help-option]
        stdout: {isTTY: true, columns: 250}
      }

    test 'partial single' ->
      q '''
        cmd

          --obj {x: Number, y: Boolean, z: Object}  an object full of
                                                    things and stuff
        ''', {
        prepend: 'cmd'
        options: [obj-option]
        stdout: {isTTY: true, columns: 68}
      }

    test 'full single' ->
      q '''
        cmd

          --obj {x: Number, y: Boolean, z: Object}
              an object full of things and stuff
        ''', {
        prepend: 'cmd'
        options: [obj-option]
        stdout: {isTTY: true, columns: 50}
      }

    test 'partial several' ->
      q '''
        cmd

        Options:
          --help          recieve help - print this info
          --count Number  count of stuff that is to be counted
          --obj {x: Number, y: Boolean, z: Object}  an object full of things
                                                    and stuff
        ''', {
        prepend: 'cmd'
        options:
          * heading: 'Options'
          * help-option
          * count-option
          * obj-option
        stdout: {isTTY: true, columns: 70}
      }

    test 'full several' ->
      q '''
        cmd

        Options:
          --help          recieve help - print this info
          --count Number  count of stuff that is to be counted
          --obj {x: Number, y: Boolean, z: Object}
              an object full of things and stuff
        ''', {
        prepend: 'cmd'
        options:
          * heading: 'Options'
          * help-option
          * count-option
          * obj-option
        stdout: {isTTY: true, columns: 55}
      }

    test 'partial all' ->
      q '''
        cmd

          --help          recieve help - print this
                          info
          --count Number  count of stuff that is to
                          be counted
        ''', {
        prepend: 'cmd'
        options:
          * help-option
          * count-option
        stdout: {isTTY: true, columns: 46}
      }

    test 'full all' ->
      q '''
        cmd

          --help
              recieve help -
              print this info
          --count Number
              count of stuff
              that is to be
              counted
        ''', {
        prepend: 'cmd'
        options:
          * help-option
          * count-option
        stdout: {isTTY: true, columns: 26}
      }

    test 'type' ->
      q '''
        cmd

          --obj {x: Number, y:
                Boolean, z: Object}
              an object full of things
              and stuff
        ''', {
        prepend: 'cmd'
        options: [obj-option]
        stdout: {isTTY: true, columns: 32}
      }

  suite 'for option' ->
    opts =
      options:
        * option: 'times-num'
          type: 'Number'
          description: 'times to do something.'
          example: '--times-num 23'
        * option: 'input'
          alias: 'i'
          type: 'OBJ::Object'
          description: 'the input that you want'
          example: '--input "x: 52, y: [1,2,3]"'
          default: '{a: 1}'
        * option: 'nope'
          type: 'Boolean'
          description: 'nothing at all'
          long-description: 'really nothing at all'
        * option: 'nope2'
          type: 'Boolean'

    test 'times' ->
      qo '''
         --times-num Number
         ==================
         description: Times to do something.
         example: --times-num 23
         ''', 'times-num', opts

    test 'input' ->
      qo '''
         -i, --input OBJ::Object
         =======================
         default: {a: 1}
         description: The input that you want.
         example: --input "x: 52, y: [1,2,3]"
         ''', 'input', opts
      qo '''
         -i, --input OBJ::Object
         =======================
         default: {a: 1}
         description: The input that you want.
         example: --input "x: 52, y: [1,2,3]"
         ''', 'i', opts

    test 'no example - long description' ->
      qo '''
         --nope
         ======
         description: really nothing at all
         ''', 'nope', opts

    test 'long description text with max width' ->
      opts =
        options: [
          option: 'long'
          type: 'String'
          description: 'it goes on and on my friends, some people started singing it not knowing what it was'
        ]
        stdout: {isTTY: true, columns: 50}
      qo '''
         --long String
         =============
         description:
         It goes on and on my friends, some people
         started singing it not knowing what it was.
         ''', 'long', opts

      opts.stdout = null
      qo '''
         --long String
         =============
         description: It goes on and on my friends, some people started singing it not knowing what it was.
         ''', 'long', opts

    test 'multiple examples' ->
      qo '''
         --op
         ====
         description: The thing.
         examples:
         cmd --op
         cmd --no-op
         ''', 'op', {options: [{
           option: 'op'
           type: 'Boolean'
           description: 'the thing'
           example:
             'cmd --op'
             'cmd --no-op'
      }]}

    test 'rest positional' ->
      opts =
        options: [{
           option: 'rest'
           type: 'Boolean'
           description: 'The rest'
           rest-positional: true
        }]
        stdout: {isTTY: false}
      qo '''
         --rest
         ======
         description: The rest. Everything after this option is considered a positional argument, even if it looks like an option.
         ''', 'rest', opts

      # no description
      delete opts.options.0.description
      qo '''
         --rest
         ======
         description: Everything after this option is considered a positional argument, even if it looks like an option.
         ''', 'rest', opts

    test 'no description or rest positional' ->
      qo '--nope2', 'nope2', opts

    test 'invalid option' ->
      qo "Invalid option '--FAKE' - perhaps you meant '-i'?", 'FAKE', opts

  suite 'help style settings' ->
    test 'all different' ->
      opts =
        help-style:
          alias-separator: '|'
          type-separator: ': '
          description-separator: ' > '
          initial-indent: 1
          secondary-indent: 2
          max-pad-factor: 10
        prepend: 'cmd'
        options:
          *  option: 'help'
             alias: 'h'
             type: 'Boolean'
             description: 'recieve help - print this info'
          * count-option
          * obj-option

      q '''
        cmd

         -h|--help                                 > recieve help - print this info
         --count: Number                           > count of stuff that is to be counted
         --obj: {x: Number, y: Boolean, z: Object} > an object full of things and stuff
        ''', opts
