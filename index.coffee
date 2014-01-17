
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

  getTexture: (name) -> @getArt name, 'textures'
  getSound: (name) -> @getArt name, 'sounds'

  getArt: (name, type) ->
    for pack in @packs    # search packs in order
      blob = pack.getBlob(name, type)
      return blob if blob?

    return undefined


# optional 'namespace:' prefix (as in namespace:foo), defaults to anything
splitNamespace = (name) ->
  a = name.split ':'
  [namespace, name] = a if a.length > 1
  namespace ?= '*'

  return [namespace, name]


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

  nameToPath:
    textures: (fullname) ->
      a = fullname.split '/'
      [category, partname] = a if a.length > 1
      # optional category/ prefix, defaults to blocks, i/ shortcut
      category = {undefined:'blocks', 'i':'items'}[category] ? category
      partname ?= fullname

      [namespace, basename] = splitNamespace partname

      pathRP = "assets/#{namespace}/textures/#{category}/#{basename}.png"
      console.log fullname,[category,namespace,basename]
      
      return pathRP

    sounds: (fullname) ->
      [namespace, name] = splitNamespace fullname
      # TODO: optional categories to search all

      pathRP = "assets/#{namespace}/sounds/#{name}.ogg"

  mimeTypes:
    textures: 'image/png'
    sounds: 'audio/ogg'

  getArrayBuffer: (name, type) ->
    pathRP = @nameToPath[type](name)

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

  getBlob: (name, type) ->
    arrayBuffer = @getArrayBuffer name, type
    return undefined if not arrayBuffer?

    return new Blob [arrayBuffer], {type: @mimeTypes[type]}

#console.log nameToPath_RP('dirt')
#console.log nameToPath_RP('i/stick')
#console.log nameToPath_RP('misc/shadow')
#console.log nameToPath_RP('minecraft:dirt')
#console.log nameToPath_RP('somethingelse:dirt')

binaryXHR 'test.zip', (err, pack1) ->
  return console.log err if err
  binaryXHR 'test2.zip', (err, pack2) ->
    return console.log err if err

    binaryXHR 'testsnd.zip', (err, pack3) ->
      return console.log err if err

      aps = new ArtPacks [pack2, pack1, pack3]

      console.log(aps)
      for name in ['dirt', 'i/stick', 'misc/shadow', 'minecraft:dirt', 'somethingelse:dirt', 'invalid']
        document.body.appendChild document.createTextNode name + ' = '

        blob = aps.getTexture(name)
        if not blob?
          document.body.appendChild document.createTextNode '(not found)'
        else
          url = URL.createObjectURL(blob)

          img = document.createElement 'img'
          img.src = url
          img.title = name

          document.body.appendChild img

          #URL.revokeObjectURL(url) # TODO?

        document.body.appendChild document.createElement 'br'

      for name in ['ambient/cave/cave1', 'damage/hit2']
        document.body.appendChild document.createTextNode 'sound ' + name + ' = '
        blob = aps.getSound(name)

        if not blob?
          document.body.appendChild document.createTextNode '(not found)'
        else
          url = URL.createObjectURL(blob)

          audio = document.createElement 'audio'
          audio.src = url
          audio.controls = true
          audio.title = name

          document.body.appendChild audio

          #URL.revokeObjectURL(url) # TODO?


        document.body.appendChild document.createElement 'br'
