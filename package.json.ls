name: 'optionator'
version: '0.9.4'

author: 'George Zahariev <z@georgezahariev.com>'
description: 'option parsing and help generation'
homepage: 'https://github.com/gkz/optionator'
keywords:
  'options'
  'flags'
  'option parsing'
  'cli'
files:
  'lib'
  'README.md'
  'LICENSE'
main: './lib/'

bugs: 'https://github.com/gkz/optionator/issues'
license: 'MIT'
engines:
  node: '>= 0.8.0'
repository:
  type: 'git'
  url: 'git://github.com/gkz/optionator.git'
scripts:
  test: "make test"

dependencies:
  'prelude-ls': '^1.2.1'
  'deep-is': '^0.1.3'
  'word-wrap': '^1.2.5'
  'type-check': '^0.4.0'
  levn: '^0.4.1'
  'fast-levenshtein': '^2.0.6'

dev-dependencies:
  livescript: '^1.6.0'
  mocha: '^10.4.0'
