
AdmZip = require 'adm-zip'

readResourcePack = (zip, names) ->
  zipEntries = zip.getEntries()

  for zipEntry in zipEntries
    console.log zipEntry.toString()

nameToPath_RP = (name) ->
  a = name.split '/'
  [category, name] = a if a.length > 1
  # optional category/ prefix, defaults to blocks, i/ shortcut
  category = {undefined:'blocks', 'i':'items'}[category] ? category

  # optional namespace: prefix, for ResourcePack defaults to anything
  a = name.split ':'
  [namespace, name] = a if a.length > 1
  namespace ?= '*'

  return [category,namespace,name]

console.log nameToPath_RP('dirt')
console.log nameToPath_RP('i/stick')
console.log nameToPath_RP('misc/shadow')
console.log nameToPath_RP('minecraft:dirt')
console.log nameToPath_RP('somethingelse:dirt')

zip = new AdmZip('test.zip')
#readResourcePack zip, ['dirt', 'stone']
