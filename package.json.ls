name: 'optionator'
version: '0.6.0'

author: 'George Zahariev <z@georgezahariev.com>'
description: 'option parsing and help generation'
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
    url: 'https://raw.githubusercontent.com/gkz/optionator/master/LICENSE'
  ...
engines:
  node: '>= 0.8.0'
repository:
  type: 'git'
  url: 'git://github.com/gkz/optionator.git'
scripts:
  test: "make test"

dependencies:
  'prelude-ls': '~1.1.2'
  'deep-is': '~0.1.3'
  wordwrap: '~1.0.0'
  'type-check': '~0.3.1'
  levn: '~0.2.5'
  'fast-levenshtein': '~1.0.6'

dev-dependencies:
  livescript: '~1.4.0'
  mocha: '~2.2.5'
  istanbul: '~0.3.14'
