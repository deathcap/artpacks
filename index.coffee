
AdmZip = require 'adm-zip'
path = require 'path'

readResourcePack = (zip, names) ->
  results = {}
  namespaces = getNamespaces_RP(zip)
  zipEntries = zip.getEntries()

  for name in names
    pathRP = nameToPath_RP(name)

    found = false

    # expand namespace wildcard, if any
    if pathRP.indexOf('*') == -1
      tryPaths = [pathRP]
    else
      tryPaths = (pathRP.replace('*', namespace) for namespace in namespaces)


    for tryPath in tryPaths
      zipEntry = zip.getEntry(tryPath)
      if zipEntry?
        console.log 'FOUND',pathRP,'AT',zipEntry.entryName
        #console.log zipEntry
        data = zipEntry.getData()
        console.log "decompressed #{zipEntry.entryName} to #{data.length}"

        results[name] = data
        found = true
        break

    if not found
      console.log "ERROR: couldn't find #{pathRP} anywhere in zip! (tried #{tryPaths})"
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

  pathRP = "assets/#{namespace}/textures/#{category}/#{name}.png"
  #return [category,namespace,name]
  
  return pathRP

# Get list of "namespaces" with a resourcepack
# all of assets/<foo>
getNamespaces_RP = (zip) ->
  zipEntries = zip.getEntries()

  namespaces = {}

  for zipEntry in zipEntries
    parts = zipEntry.entryName.split(path.sep)
    continue if parts.length < 2
    continue if parts[0] != 'assets'
    continue if parts[1].length == 0

    namespaces[parts[1]] = true

  return Object.keys(namespaces)

console.log nameToPath_RP('dirt')
console.log nameToPath_RP('i/stick')
console.log nameToPath_RP('misc/shadow')
console.log nameToPath_RP('minecraft:dirt')
console.log nameToPath_RP('somethingelse:dirt')

zip = new AdmZip('test.zip')

results = readResourcePack zip, ['dirt', 'i/stick', 'misc/shadow', 'minecraft:dirt', 'somethingelse:dirt']
console.log 'results=',results

