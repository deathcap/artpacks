
ZIP = require 'zip'
path = require 'path'
fs = require 'fs'
binaryXHR = require 'binary-xhr'

class ArtPacks
  constructor: (packs) ->
    @packs = []

    for pack in packs
      @addPack pack

  addPack: (pack) ->
    if pack instanceof ArrayBuffer # raw zip archive data
      @packs.push new ArtPackArchive(pack)
    else
      @packs.push pack  # assumed to be ArtPackArchive

  getTexture: (name) ->
    for pack in @packs    # search packs in order
      blob = pack.getBlob(name)
      return blob if blob?

    return undefined

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

class ArtPackArchive
  constructor: (packData) ->
    if packData instanceof ArrayBuffer
      # convert browser ArrayBuffer to NodeJS Buffer so ZIP recognizes it as data
      packData = new Buffer(new Uint8Array(packData))
    @zip = new ZIP.Reader(packData)

    @zipEntries = {}
    @zip.forEach (entry) =>
      @zipEntries[entry.getName()] = entry

    @namespaces = @scanNamespaces()
    @namespaces.push 'foo'  # test

  # Get list of "namespaces" with a resourcepack
  # all of assets/<foo>
  scanNamespaces: () -> # TODO: only if RP
    namespaces = {}

    for zipEntryName in Object.keys(@zipEntries)
      parts = zipEntryName.split(path.sep)
      continue if parts.length < 2
      continue if parts[0] != 'assets'
      continue if parts[1].length == 0

      namespaces[parts[1]] = true

    return Object.keys(namespaces)

  getArrayBuffer: (name) ->
    pathRP = nameToPath_RP(name)

    found = false

    # expand namespace wildcard, if any
    if pathRP.indexOf('*') == -1
      tryPaths = [pathRP]
    else
      tryPaths = (pathRP.replace('*', namespace) for namespace in @namespaces)

    for tryPath in tryPaths
      zipEntry = @zipEntries[tryPath]
      if zipEntry?
        #console.log 'FOUND',pathRP,'AT',zipEntry.entryName
        #console.log zipEntry
        data = zipEntry.getData()
        #console.log "decompressed #{zipEntry.entryName} to #{data.length}"

        return data

    return undefined # not found

  getBlob: (name) ->
    return new Blob [@getArrayBuffer name]

#console.log nameToPath_RP('dirt')
#console.log nameToPath_RP('i/stick')
#console.log nameToPath_RP('misc/shadow')
#console.log nameToPath_RP('minecraft:dirt')
#console.log nameToPath_RP('somethingelse:dirt')

binaryXHR 'test.zip', (err, pack1) ->
  return console.log err if err
  binaryXHR 'test2.zip', (err, pack2) ->
    return console.log err if err

    aps = new ArtPacks [pack1, pack2]

    console.log(aps)
    for name in ['dirt', 'i/stick', 'misc/shadow', 'minecraft:dirt', 'somethingelse:dirt', 'invalid', 'misc/pumpkinblur']
      blob = aps.getTexture(name)
      console.log name,'=',blob

