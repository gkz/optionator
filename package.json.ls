name: 'optionator'
version: '0.1.1'

author: 'George Zahariev <z@georgezahariev.com>'
description: 'option parsing'
homepage: 'https://github.com/gkz/optionator'
keywords:
  'options'
files:
  'lib'
  'README.md'
  'LICENSE'
main: './lib/'

bugs: 'https://github.com/gkz/optionator/issues'
licenses:
  * type: 'MIT'
    url: 'https://raw.github.com/gkz/optionator/master/LICENSE'
  ...
engines:
  node: '>= 0.8.0'
repository:
  type: 'git'
  url: 'git://github.com/gkz/optionator.git'
scripts:
  test: "make test"

dependencies:
  'prelude-ls': '~1.0.3'
  'deep-is': '~0.1.2'
  wordwrap: '~0.0.2'
  'type-check': '~0.3.0'
  levn: '~0.2.1'
  'levenshtein-damerau': '~0.1.0'

dev-dependencies:
  LiveScript: '~1.2.0'
  mocha: '~1.8.2'
  istanbul: '~0.1.43'
