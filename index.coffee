
AdmZip = require 'adm-zip'
match = require 'minimatch'

readResourcePack = (zip, names) ->
  zipEntries = zip.getEntries()

  paths = (nameToPath_RP(name) for name in names)
  console.log 'PATHS=',paths

  for path in paths
    for zipEntry in zipEntries    # TODO: could possibly optimize, instead of matching for '*', enumerate all namespaces and test each with most likely first
      if match(zipEntry.entryName, path)
        console.log 'FOUND',path,'AT',zipEntry.entryName
        #console.log zipEntry.toString()

nameToPath_RP = (name) ->
  a = name.split '/'
  [category, name] = a if a.length > 1
  # optional category/ prefix, defaults to blocks, i/ shortcut
  category = {undefined:'blocks', 'i':'items'}[category] ? category

  # optional namespace: prefix, for ResourcePack defaults to anything
  a = name.split ':'
  [namespace, name] = a if a.length > 1
  namespace ?= '*'

  ext = '.png'

  path = "assets/#{namespace}/textures/#{category}/#{name}.png"
  #return [category,namespace,name]
  
  return path

console.log nameToPath_RP('dirt')
console.log nameToPath_RP('i/stick')
console.log nameToPath_RP('misc/shadow')
console.log nameToPath_RP('minecraft:dirt')
console.log nameToPath_RP('somethingelse:dirt')

zip = new AdmZip('test.zip')
readResourcePack zip, ['dirt', 'i/stick', 'misc/shadow', 'minecraft:dirt', 'somethingelse:dirt']

