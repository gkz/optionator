{map, sort-by} = require 'prelude-ls'
ld = require 'levenshtein-damerau'

closest-string = (possibilities, input) ->
  return unless possibilities.length
  distances = possibilities |> map ->
    [longer, shorter] = if input.length > it.length then [input, it] else [it, input]
    {string: it, distance: ld longer, shorter}

  {string, distance} = sort-by (.distance), distances .0
  string

name-to-raw = (name) -> if name.length is 1 or name is 'NUM' then  "-#name" else "--#name"

# 'dashed-string' to dashedString
camelize = (.replace /-[a-z]/ig -> it.char-at 1 .to-upper-case!)

dasherize = (string) ->
  # PascalCase strings are as is
  if /^[A-Z]/.test string
    string
  # convert camelCase to camel-case, and setJSON to set-JSON
  else
    string.replace /[A-Z]{2,}/g, -> "-#it"
          .replace /([a-z])([A-Z])/g, (,lower, upper) -> "#{lower}-#{upper.to-lower-case!}"

module.exports = {closest-string, name-to-raw, camelize, dasherize}
