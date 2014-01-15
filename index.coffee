
AdmZip = require 'adm-zip'
match = require 'minimatch'

readResourcePack = (zip, names) ->
  results = {}
  zipEntries = zip.getEntries()

  for name in names
    pathRP = nameToPath_RP(name)

    found = false
    for zipEntry in zipEntries    # TODO: could possibly optimize, instead of matching for '*', enumerate all namespaces and test each with most likely first
      if match(zipEntry.entryName, pathRP)
        console.log 'FOUND',pathRP,'AT',zipEntry.entryName
        #console.log zipEntry
        data = zipEntry.getData()
        console.log "decompressed #{zipEntry.entryName} to #{data.length}"

        results[name] = data
        found = true
    if not found
      console.log "ERROR: couldn't find #{pathRP} in zip!"
      results[name] = null
      # TODO: not really an error; fallthrough to next possible artpack

  return results

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
results = readResourcePack zip, ['dirt', 'i/stick', 'misc/shadow', 'minecraft:dirt', 'somethingelse:dirt']
console.log 'results=',results

