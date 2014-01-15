
AdmZip = require 'adm-zip'
path = require 'path'

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

class ArtPack
  constructor: (@filename) ->
    @zip = new AdmZip(@filename)
    @zipEntries = @zip.getEntries()
    @namespaces = @scanNamespaces()
    @namespaces.push 'foo'  # test

  # Get list of "namespaces" with a resourcepack
  # all of assets/<foo>
  scanNamespaces: () -> # TODO: only if RP
    namespaces = {}

    for zipEntry in @zipEntries
      parts = zipEntry.entryName.split(path.sep)
      continue if parts.length < 2
      continue if parts[0] != 'assets'
      continue if parts[1].length == 0

      namespaces[parts[1]] = true

    return Object.keys(namespaces)

  read: (name) ->
    pathRP = nameToPath_RP(name)

    found = false

    # expand namespace wildcard, if any
    if pathRP.indexOf('*') == -1
      tryPaths = [pathRP]
    else
      tryPaths = (pathRP.replace('*', namespace) for namespace in @namespaces)

    for tryPath in tryPaths
      zipEntry = @zip.getEntry(tryPath)
      if zipEntry?
        console.log 'FOUND',pathRP,'AT',zipEntry.entryName
        #console.log zipEntry
        data = zipEntry.getData()
        console.log "decompressed #{zipEntry.entryName} to #{data.length}"

        return data

    return undefined # not found

  readAll: (names) ->
    results = {}
    for name in names
      data = @read(name)
      if not data?
        console.log "WARNING: nothing found for #{name}"  # TODO: try next
      results[name] = data

    return results


console.log nameToPath_RP('dirt')
console.log nameToPath_RP('i/stick')
console.log nameToPath_RP('misc/shadow')
console.log nameToPath_RP('minecraft:dirt')
console.log nameToPath_RP('somethingelse:dirt')

ap = new ArtPack('test.zip')

results = ap.readAll ['dirt', 'i/stick', 'misc/shadow', 'minecraft:dirt', 'somethingelse:dirt', 'invalid']
console.log 'results=',results

