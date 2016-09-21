optionator = require '..'
{strict-equal: equal, deep-equal, throws}:assert = require 'assert'

q = (args, options, more = {}, parse-options) ->
  more <<< {options}
  {parse} = optionator more
  parse args, parse-options

eq = (expected-options, expected-positional, args, options, more, parse-options) ->
  result = q args, options, more, parse-options
  deep-equal result._, expected-positional
  delete result._
  deep-equal result, expected-options

suite 'misc' ->
  test 'version' ->
    equal optionator.VERSION, (require '../package.json').version

suite 'boolean flags' ->
  opts =
    * option: 'help'
      alias: 'h'
      type: 'Boolean'
    * option: 'match'
      alias: ['m', 't']
      type: 'Boolean'

  test 'long' ->
    eq {help: true}, [], '--help', opts

  test 'short' ->
    eq {help: true}, [], '-h', opts
    eq {match: true}, [], '-m', opts
    eq {match: true}, [], '-m', opts

  test 'short with --' ->
    eq {help: true}, [], '--h', opts

  test 'multiple' ->
    eq {help: true, match: true}, [], '-hm', opts

  test 'negative' ->
    eq {match: false}, [], '--no-match', opts

  test 'redefine' ->
    eq {match: false}, [], '--match --no-match', opts
    eq {match: true}, [], '--no-match --match', opts

  test 'using = true' ->
    eq {match: true}, [], '--match=true', opts
    eq {match: true}, [], '--no-match=false', opts

  test 'using = true, short' ->
    eq {match: true}, [], '-m=true', opts

  test 'using = negated' ->
    eq {match: false}, [], '--match=false', opts
    eq {match: false}, [], '--no-match=true', opts

  test 'using = false, short' ->
    eq {match: false}, [], '-m=false', opts

suite 'argument' ->
  opts =
    * option: 'context'
      alias: 'C'
      type: 'Number'
    * option: 'name'
      alias: 'A'
      type: 'String'
    * option: 'destroy'
      alias: 'd'
      type: 'Boolean'

  test 'simple long' ->
    eq {context: 2}, [], '--context 2', opts

  test 'simple short' ->
    eq {context: 2}, [], '-C 2', opts

  test 'grouped short, when last' ->
    eq {destroy: true, context: 2}, [], '-dC 2', opts

  test 'multiple' ->
    eq {context: 2, name: 'Arnie'}, [], '--context 2 --name Arnie', opts

  test 'with boolean flag' ->
    eq {context: 2, destroy: true}, [], '--destroy --context 2', opts
    eq {context: 2, destroy: true}, [], '--context 2 --destroy', opts

  test 'using =' ->
    eq {context: 2}, [], '--context=2', opts

  test 'using = complex' ->
    eq {name: 'Arnie S'}, [], '--name="Arnie S"', opts

  test 'using = no value' ->
    throws (-> q '--context=', opts), /No value for 'context' specified/

  test 'using = short' ->
    eq {context: 2}, [], '-C=2', opts
    eq {context: 2, destroy: true}, [], '-dC=2', opts

  test 'using = short no value' ->
    throws (-> q '-C=', opts), /No value for 'C' specified/

  test 'value for prop required' ->
    throws (-> q '--context', opts), /Value for 'context' of type 'Number' required./
    throws (-> q '--context --destroy', opts), /Value for 'context' of type 'Number' required./

  test 'can\'t set flag val when not last' ->
    throws (-> q '-Cd 2', opts), /Can't set argument 'C' when not last flag in a group of short flags./

  test 'no- prefix only on boolean options' ->
    throws (-> q '--no-context 2', opts), /Only use 'no-' prefix for Boolean options, not with 'context'./

  test 'redefine' ->
    eq {context: 5}, [], '--context 4 --context 5', opts
    eq {context: 5}, [], '-C 4 --context 5', opts

  test 'invalid type' ->
    throws (-> q '--ends 20-11', [option: 'ends', type: 'Date']), /expected type Date/
    throws (-> q '--pair "true"', [option: 'pair', type: '(Boolean, Number)']), /expected type \(Boolean, Number\)/
    throws (-> q '--pair "true, 2, hider"', [option: 'pair', type: '(Boolean, Number)']), /expected type \(Boolean, Number\)/
    throws (-> q '--props "x:1,fake:yo"', [option: 'props', type: '{x:Number}']), /expected type {x:Number}/

suite 'enum' ->
  enum-opt = [option: 'size', type: 'String', enum: <[ small medium large ]>]
  test 'enum' ->
    eq {size: 'medium'}, [], '--size medium', enum-opt

  test 'invalid enum' ->
    throws (-> q '--size Hello', enum-opt), /Option size: 'Hello' not one of small, medium, or large/

suite 'argument names' ->
  opts =
    * option: 'after-context'
      type: 'Number'
    * option: 'is-JSON'
      type: 'Boolean'
    * option: 'HiThere'
      type: 'Boolean'
    * option: 'context2'
      type: 'Number'

  test 'dash to camel' ->
    eq {after-context: 99}, [], '--after-context 99', opts
    eq {is-JSON: true}, [], '--is-JSON', opts

  test 'preserve PascalCase' ->
    eq {HiThere: true}, [], '--HiThere', opts

  test 'numbers' ->
    eq {context2: 1}, [], '--context2 1', opts

suite '-NUM' ->
  test 'no -NUM option defined' ->
    throws (-> q '-1', []), /No -NUM option defined./

  test 'no aliases allowed' ->
    throws (-> q '', [option: 'NUM', type: 'Number', alias: 'n']), /-NUM option can't have aliases/

  suite 'number' ->
    opts = [{option: 'NUM', type: 'Number'}]

    test '0' ->
      eq {NUM: 0}, [], '-0', opts

    test '1' ->
      eq {NUM: 1}, [], '-1', opts

    test 'multi digit' ->
      eq {NUM: 10}, [], '-10', opts

    test 'float' ->
      eq {NUM: 1.0}, [], '-1.0', opts

  suite 'float' ->
    opts = [{option: 'NUM', type: 'Float'}]

    test 'float basic' ->
      eq {NUM: 1.2}, [], '-1.2', opts

    test 'float from int' ->
      eq {NUM: 1.0}, [], '-1', opts

  suite 'int' ->
    opts = [{option: 'NUM', type: 'Int'}]

    test 'int basic' ->
      eq {NUM: 1}, [], '-1', opts

suite 'positional' ->
  opts =
    * option: 'flag'
      alias: 'f'
      type: 'Boolean'
    * option: 'cc'
      type: 'Number'
    * option: 'help'
      alias: 'h'
      type: 'Boolean'
      rest-positional: true
    * option: 'help-two'
      alias: 'H'
      type: 'String'
      rest-positional: true

  test 'basic' ->
    eq {}, ['boom'], 'boom', opts

  test 'anywhere' ->
    eq {flag: true, cc: 42}, ['boom', '2', 'hi'], 'boom --flag 2 --cc 42 hi', opts

  test 'not anywhere' ->
    eq {flag: true, cc: 42}, ['hi', '--xx'], '--flag --cc 42 hi --xx', opts, {positional-anywhere: false}

  test '--' ->
    eq {flag: true}, ['--flag', '2', 'boom'], '--flag -- --flag 2 boom', opts

  test 'rest positional boolean' ->
    eq {help: true}, ['--flag', '2', 'boom'], '--help --flag 2 boom', opts

  test 'rest positional value' ->
    eq {help-two: 'lalala'}, ['--flag', '2', 'boom'], '--help-two lalala --flag 2 boom', opts

  test 'rest positional flags simple' ->
    eq {help: true}, ['--flag', '2', 'boom'], '-h --flag 2 boom', opts
    eq {help-two: 'lalala'}, ['--flag', '2', 'boom'], '-H lalala --flag 2 boom', opts

  test 'rest positional flags grouped' ->
    eq {help: true, flag: true}, ['--cc', '2', 'boom'], '-fh --cc 2 boom', opts
    eq {help-two: 'lalala', flag: true}, ['--cc', '2', 'boom'], '-fH lalala --cc 2 boom', opts

  test 'rest positional flags grouped complex' ->
    eq {help: true}, ['f', '--cc', '2', 'boom'], '-hf --cc 2 boom', opts

suite 'defaults' ->
  test 'basic' ->
    opt = [option: 'go', type: 'String', default: 'boom']
    eq {go: 'boom'}, [], '', opt
    eq {go: 'haha'}, [], '--go haha', opt

  test 'array' ->
    opt = [option: 'list', type: 'Array', default: '1,2']
    eq {list: [1,2]}, [], '', opt
    eq {list: [8,9]}, [], '--list 8,9', opt

suite 'array/object input' ->
  opts =
    * option: 'el'
      type: 'Number'
    * option: 'hasta-la-vista'
      alias: 'h'
      type: 'String'
    * option: 'is-JSON'
      type: 'Boolean'
    * option: 'test'
      type: 'RegExp'
    * option: 'HiThere'
      type: 'Boolean'
    * option: 'day'
      type: 'Date'
    * option: 'list'
      alias: 'l'
      type: '[Int]'
    * option: 'pair'
      type: '(Int,String)'
    * option: 'map'
      type: '{a:Int,b:Boolean}'

  test 'array' ->
    eq {el: 5}, [], ['node', 'cmd.js', '--el', '5'], opts

  test 'object' ->
    eq {el: 5}, [], {el: 5}, opts

  test 'object set positional' ->
    eq {el: 5}, ['haha'], {el: 5, _:['haha']}, opts

  test 'object - camelCase keys' ->
    eq {hasta-la-vista: 'baby'}, [], {hasta-la-vista: 'baby'}, opts
    eq {is-JSON: true}, [], {is-JSON: true}, opts

  test 'object - dashed-case keys' ->
    eq {hasta-la-vista: 'baby'}, [], {'hasta-la-vista': 'baby'}, opts

  test 'object - PascalCase keys' ->
    eq {HiThere: true}, [], {HiThere: true}, opts

  test 'object -aliases' ->
    eq {hasta-la-vista: 'lala', list: [1,2,3]}, [], {h: 'lala', l: [1,2,3]}, opts

  test 'regexp object' ->
    eq {test: /I'll be back/g}, [], {test: /I'll be back/g}, opts

  test 'date object' ->
    eq {day: new Date '2011-11-11'}, [], {day: new Date '2011-11-11'}, opts

  test 'array object' ->
    eq {list: [1,2,3]}, [], {list: [1,2,3]}, opts

  test 'tuple object' ->
    eq {pair: [1, '52']}, [], {pair: [1, '52']}, opts

  test 'object object' ->
    eq {map: {a: 1, b: true}}, [], {map: {a: 1, b: true}}, opts

  test 'invalid object' ->
    throws (-> q {el: 'hi'}, opts), /Option 'el': Invalid type for 'hi' - expected type 'Number'/

suite 'slicing' ->
  test 'string slice' ->
    eq {b: 2}, ['c'], 'cmd -b 2 c', [{option: 'b', type: 'Number'}], , {slice: 3}

  test 'array slice' ->
    eq {b: 2}, ['c'], ['cmd' '-b' '2' 'c'], [{option: 'b', type: 'Number'}], , {slice: 1}

suite 'parse-argv' ->
  test 'slices two' ->
    {parse-argv} = optionator do
      options: [
        option: 'a'
        type: 'Boolean'
      ]
    o = parse-argv <[ a b c d -a ]>
    deep-equal o._, <[ c d ]>
    equal o.a, true

suite 'errors in defining options' ->
  test 'no options defined' ->
    throws (-> q ''), /No options defined/

  test 'option already defined' ->
    throws (-> q '', [option: 'opt', type: '*'; option: 'opt', type: '*']), /Option 'opt' already defined/
    throws (-> q '', [option: 'opt', type: '*'; option: 'top', type: '*', alias: 'opt'])
         , /Option 'opt' already defined/

  test 'no type defined' ->
    throws (-> q '', [option: 'opt']), /No type defined for option 'opt'./

  test 'error parsing type' ->
    throws (-> q '', [option: 'opt', type: '[Int']), /Option 'opt': Error parsing type '\[Int'/

  test 'error parsing default value' ->
    throws (-> q '', [option: 'opt', type: 'Number', default: 'hi'])
         , /Option 'opt': Error parsing default value 'hi' for type 'Number':/

  test 'error parsing enum value' ->
    throws (-> q '', [option: 'opt', type: 'Number', enum: ['hi']])
         , /Option 'opt': Error parsing enum value 'hi' for type 'Number':/

suite 'errors parsing options' ->
  test 'invalid argument to parse' ->
    throws (-> q 2, []), /Invalid argument to 'parse': 2./

  test 'invalid option' ->
    opts = [option: 'rake', type: 'Boolean'; option: 'kare', type: 'Boolean']
    throws (-> q '--fake', opts), /Invalid option '--fake' - perhaps you meant '--rake'\?/
    throws (-> q '--arket', opts), /Invalid option '--arket' - perhaps you meant '--rake'\?/
    throws (-> q '-k', opts), /Invalid option '-k' - perhaps you meant '--rake'\?/

  test 'invalid option - no additional help' ->
    throws (-> q '--fake', []), /Invalid option '--fake'/

  test 'is required' ->
    opts = [option: 'req-opt', type: 'Boolean', required: true]
    eq {reqOpt: true}, [], {+reqOpt}, opts
    throws (-> q '', opts), /Option --req-opt is required/

  test 'override required' ->
    opts =
      * option: 'req-opt'
        type: 'Boolean'
        required: true
      * option: 'help'
        type: 'Boolean'
        override-required: true

    throws (-> q '', opts), /Option --req-opt is required/
    eq {help: true}, [], '--help', opts

  test 'is mutually exclusive' ->
    opts =
      * option: 'aa-aa'
        type: 'Boolean'
      * option: 'bb'
        type: 'Boolean'
      * option: 'cc'
        type: 'Boolean'
      * option: 'dd'
        type: 'Boolean'
      * option: 'ee'
        type: 'Boolean'

    more =
      mutually-exclusive:
        <[ aa-aa bb ]>
        [<[ bb cc ]> <[ dd ee ]>]

    throws (-> q '--aa-aa --bb', opts, more), /The options --aa-aa and --bb are mutually exclusive - you cannot use them at the same time/
    throws (-> q '--bb --ee', opts, more), /The options --bb and --ee are mutually exclusive - you cannot use them at the same time/
    throws (-> q '--cc --dd', opts, more), /The options --cc and --dd are mutually exclusive - you cannot use them at the same time/
    throws (-> q {aaAa: true, bb: true}, opts, more), /The options --aa-aa and --bb are mutually exclusive - you cannot use them at the same time/

suite 'concat repeated arrays' ->
  opts =
    * option: 'nums'
      alias: 'n'
      type: '[Number]'
    * option: 'x'
      type: 'Number'

  more = {+concat-repeated-arrays}

  test 'basic' ->
    eq {nums: [1,2,3]}, [], '-n 1 -n 2 -n 3', opts, more

  test 'overwrites non-array' ->
    eq {x: 3}, [], '-x 1 -x 2 -x 3', opts, more

  test 'per option' ->
    opts =
      * option: 'x'
        type: '[Number]'
        concat-repeated-arrays: true
      * option: 'y'
        type: '[Number]'
    eq {x: [1, 2, 3]}, [], '-x 1 -x 2 -x 3', opts
    eq {y: [3]}, [], '-y 1 -y 2 -y 3', opts

  test 'using defaults' ->
    opts =
      * option: 'x'
        type: '[Number]'
      * option: 'y'
        type: '[Number]'
        concat-repeated-arrays: false
    more =
      defaults: {+concat-repeated-arrays}

    eq {x: [1, 2, 3]}, [], '-x 1 -x 2 -x 3', opts, more
    eq {y: [3]}, [], '-y 1 -y 2 -y 3', opts, more

  test 'one value per flag' ->
    opts =
      * option: 'x'
        type: '[String]'
        concat-repeated-arrays: [true, {+one-value-per-flag}]
      ...

    eq {x: ['a,b', 'c,d', 'e,f']}, [], '-x "a,b" -x "c,d" -x "e,f"', opts

  test 'set with array, len is 1' ->
    opts =
      * option: 'x'
        type: '[String]'
        concat-repeated-arrays: [true]
      ...
    eq {x: <[ a b c d ]>}, [], '-x "a,b" -x "c,d"', opts

  test 'invalid setting' ->
    opts =
      * option: 'x'
        type: '[String]'
        concat-repeated-arrays: []
      ...
    throws (-> q '', opts), /Invalid setting for concatRepeatedArrays/

suite 'merge repeated objects' ->
  opts =
    * option: 'config'
      alias: 'c'
      type: 'Object'
    * option: 'x'
      type: 'Number'

  more = {+merge-repeated-objects}

  test 'basic' ->
    eq {config: {a: 1, b: 2, c: 3}}, [], '-c a:1 -c b:2 -c c:3', opts, more

  test 'same properties' ->
    eq {config: {a: 3}}, [], '-c a:1 -c a:2 -c a:3', opts, more

  test 'multiple properties in one go' ->
    eq {config: {a: 1, b: 2, c: 3, d: 4}}, [], '-c "a:1,b:2" -c "c: 3, d: 4"', opts, more

  test 'overwrites non-array' ->
    eq {x: 3}, [], '-x 1 -x 2 -x 3', opts, more

  opts2 =
    * option: 'c'
      type: 'Object'
      merge-repeated-objects: true
    * option: 'd'
      type: 'Object'

  test 'per option' ->
    eq {c: {a: 1, b: 2, c: 3}}, [], '-c a:1 -c b:2 -c c:3', opts2
    eq {d: {c: 3}}, [], '-d a:1 -d b:2 -d c:3', opts2

suite 'dependency check' ->
  opts =
    * option: 'aa'
      type: 'Boolean'
    * option: 'bb'
      type: 'Boolean'
      depends-on: ['or', 'aa', 'dd']
    * option: 'cc'
      type: 'Boolean'
      depends-on: ['and', 'aa', 'dd']
    * option: 'dd'
      type: 'Boolean'
    * option: 'ff'
      type: 'Boolean'
      depends-on: 'aa'
    * option: 'gg'
      type: 'Boolean'
      depends-on: ['aa']

  test '"and" should pass' ->
    eq {+cc, +aa, +dd}, [], '--cc --aa --dd', opts

  test '"and" should fail' ->
    throws (-> q '--cc', opts), /The option 'cc' did not have its dependencies met/
    throws (-> q '--cc --aa', opts), /The option 'cc' did not have its dependencies met/
    throws (-> q '--cc --dd', opts), /The option 'cc' did not have its dependencies met/

  test '"or" should pass' ->
    eq {+bb, +aa}, [], '--bb --aa', opts
    eq {+bb, +dd}, [], '--bb --dd', opts

  test '"or" should fail' ->
    throws (-> q '--bb', opts), /The option 'bb' did not meet any of its dependencies/

  test 'single dependency, as string' ->
    eq {+ff, +aa}, [], '--ff --aa', opts

  test 'single dependency, in array' ->
    eq {+gg, +aa}, [], '--gg --aa', opts

  test 'just "and"' ->
    opts = [
      option: 'xx'
      type: 'Boolean'
      depends-on: ['and']
    ]
    eq {+xx}, [], '--xx', opts

  test 'empty array' ->
    opts = [
      option: 'xx'
      type: 'Boolean'
      depends-on: []
    ]
    eq {+xx}, [], '--xx', opts

  test 'not using "and" or "or"' ->
    opts = [
      option: 'fail'
      type: 'Boolean'
      depends-on: ['blerg', 'grr']
    ]

    throws (-> q '--fail', opts), /Option 'fail': If you have more than one dependency, you must specify either 'and' or 'or'/

suite 'option defaults' ->
  opts =
    * option: 'a'
    * option: 'b'

  more =
    defaults:
      type: 'Number'

  test 'basic' ->
    eq {a: 5}, [], '-a 5', opts, more
    eq {b: 5}, [], '-b 5', opts, more

suite 'heading' ->
  opts =
    * option: 'aaa'
      type: 'Number'
    * heading: 'mooo'
    * option: 'bbb'
      type: 'String'
    * option: 'ccc'
      type: 'Boolean'

  test 'basic' ->
    eq {aaa: 5}, [], '--aaa 5', opts
    eq {bbb: 'hi'}, [], '--bbb hi', opts
    eq {ccc: true}, [], '--ccc', opts

suite 'type-aliases' ->
  opts =
    * option: 'x'
      type: 'Path'
    * option: 'y'
      type: 'Rules'
  type-aliases =
    Path: 'String'
    Rules: '[String]'

  test 'basic' ->
    eq {x: 'a', y: <[ c d ]>}, [], '-x a -y c,d', opts, {type-aliases}
