
ZIP = require 'zip'
path = require 'path'
fs = require 'fs'
binaryXHR = require 'binary-xhr'
EventEmitter = (require 'events').EventEmitter
getFrames = require 'mcmeta'
getPixels = require 'get-pixels'
savePixels = require 'save-pixels'
graycolorize = require 'graycolorize'

# convert UTF-8 ArrayBuffer to string - see http://stackoverflow.com/questions/17191945/conversion-between-utf-8-arraybuffer-and-string
arrayBufferToString = (arrayBuffer) -> String.fromCharCode.apply(null, new Uint8Array(arrayBuffer))

class ArtPacks extends EventEmitter
  constructor: (packs) ->
    @packs = []
    @pending = {}
    @blobURLs = {}
    @shouldColorize = { 'grass_top':true, 'leaves_oak':true }  # TODO: more comprehensive, configurable

    @setMaxListeners 0    # since each texture can @on 'loadedAll'.. it adds up

    for pack in packs
      @addPack pack

  addPack: (x, name=undefined) ->
    if x instanceof ArrayBuffer
      rawZipArchiveData = x
      @packs.push new ArtPackArchive(rawZipArchiveData, name ? "(#{rawZipArchiveData.byteLength} raw bytes)")
      @refresh()
      @emit 'loadedRaw', rawZipArchiveData
      @emit 'loadedAll'
    else if typeof x == 'string'
      url = x

      if not XMLHttpRequest?
        throw new Error "artpacks unsupported addPack url #{x} without XMLHttpRequest"

      @pending[url] = true
      packIndex = @packs.length
      @packs[packIndex] = null # save place while loading
      @emit 'loadingURL', url
      binaryXHR url, (err, packData) =>
        if @packs[packIndex] != null
          console.log "artpacks warning: index #{packIndex} occupied, expected to be empty while loading #{url}"

        if err || !packData
          console.log "artpack failed to load \##{packIndex} - #{url}: #{err}"
          @emit 'failedURL', url, err
          delete @pending[url]
          return
          # @packs[packIndex] stays null

        try
          @packs[packIndex] = new ArtPackArchive(packData, url)
          @refresh()
        catch e
          console.log "artpack failed to parse \##{packIndex} - #{url}: #{e}"
          @emit 'failedURL', url, e
          # fallthrough

        delete @pending[url]

        console.log 'artpacks loaded pack:',url
        @emit 'loadedURL', url
        @emit 'loadedAll' if Object.keys(@pending).length == 0
    else
      pack = x
      @emit 'loadedPack', pack
      @emit 'loadedAll'
      @packs.push pack  # assumed to be ArtPackArchive
      @refresh()

  # swap the ordering of two loaded packs
  swap: (i, j) ->
    return if i == j

    temp = @packs[i]
    @packs[i] = @packs[j]
    @packs[j] = temp
    @refresh()

  colorize: (img, onload, onerror) ->
    getPixels img.src, (err, pixels) ->
      if err
        return onerror(err, img)

      # see https://en.wikipedia.org/wiki/HSL_color_space#HSV_.28Hue_Saturation_Value.29
      @colorMap ?= graycolorize.generateMap 120/360, 0.7

      graycolorize pixels, @colorMap

      img2 = new Image()
      img2.src = savePixels(pixels, 'canvas').toDataURL()
      img2.onload = () -> onload(img2)
      img2.onerror = (err) -> onerror(err, img2)

  getTextureNdarray: (name, onload, onerror) ->
    onload2 = (img) ->
      if Array.isArray(img)
        # TODO: support multiple textures (animation frame strips), add another dimension to the ndarray? (always)
        # currently, only using first frame
        img = img[0]

      # get as [m,n,4] RGBA ndarray
      getPixels img.src, (err, pixels) ->
        if err
          return onerror(err, img)

        onload(pixels)

    @getTextureImage name, onload2, onerror

  # TODO: refactor to operate on ndarray directly
  getTextureImage: (name, onload, onerror) ->
    img = new Image()

    load = () =>
      url = @getTexture name
      if not url?
        return onerror("no such texture in artpacks: #{name}", img)

      img.src = url
      img.onload = () =>
        if @shouldColorize[name]
          return @colorize(img, onload, onerror)

        if img.height == img.width
          # assumed static image
          onload(img)
        else
          # possible multi-frame texture strip; read .mcmeta file
          json = @getMeta name, 'textures'
          console.log('.mcmeta=',json)

          getPixels img.src, (err, pixels) ->
            if err
              return onerror(err, img)

            frames = getFrames pixels, json
            loaded = 0
            frameImgs = []

            # load each frame
            frames.forEach (frame) ->
              frameImg = new Image()
              frameImg.src = frame.image

              frameImg.onerror = (err) ->
                onerror(err, img, frameImg)
              frameImg.onload = () ->
                frameImgs.push frameImg

                if frameImgs.length == frames.length
                  if frameImgs.length == 1
                    onload frameImgs[0]
                  else
                    # array of frames
                    onload frameImgs
         
      img.onerror = (err) ->
        onerror(err, img)

    if @isQuiescent()
      load()
    else
      @on 'loadedAll', load

  getTexture: (name) -> @getURL name, 'textures'
  getSound: (name) -> @getURL name, 'sounds'

  getURL: (name, type) ->
    # already have URL?
    url = @blobURLs[type + ' ' + name]
    return url if url?

    # get a blob
    blob = @getBlob(name, type)
    return undefined if not blob?

    # create URL and return
    url = URL.createObjectURL(blob)
    @blobURLs[type + ' ' + name] = url
    return url

  mimeTypes:
    textures: 'image/png'
    sounds: 'audio/ogg'

  getBlob: (name, type) ->
    arrayBuffer = @getArrayBuffer name, type, false
    return undefined if not arrayBuffer?

    return new Blob [arrayBuffer], {type: @mimeTypes[type]}

  getArrayBuffer: (name, type, isMeta) ->
    for pack in @packs.slice(0).reverse()     # search packs in reverse order
      continue if !pack
      arrayBuffer = pack.getArrayBuffer(name, type, isMeta)
      return arrayBuffer if arrayBuffer?

    return undefined

  getMeta: (name, type) ->
    arrayBuffer = @getArrayBuffer name, type, true
    return undefined if not arrayBuffer?

    encodedString = arrayBufferToString arrayBuffer
    decodedString = decodeURIComponent(escape(encodedString))

    json = JSON.parse(decodedString)

    return json

  # revoke all URLs to reload from packs list
  refresh: () ->
    for url in @blobURLs
      URL.revokeObjectURL(url)
    @blobURLs = []
    @emit 'refresh'

  # delete all loaded packs
  clear: () ->
    @packs = []
    @refresh()

  getLoadedPacks: () ->
    ret = []
    for pack in @packs.slice(0).reverse()
      ret.push pack if pack?
    return ret

  isQuiescent: () -> # have at least 1 pack loaded, and no more left to go
    return @getLoadedPacks().length > 0 and Object.keys(@pending).length == 0

# optional 'namespace:' prefix (as in namespace:foo), defaults to anything
splitNamespace = (name) ->
  a = name.split ':'
  [namespace, name] = a if a.length > 1
  namespace ?= '*'

  return [namespace, name]


class ArtPackArchive
  # Load pack given binary data + optional informative name
  constructor: (packData, @name=undefined) ->
    if packData instanceof ArrayBuffer
      # zip with bops uses Uint8Array data view
      packData = new Uint8Array(packData)
    @zip = new ZIP.Reader(packData)

    @zipEntries = {}
    @zip.forEach (entry) =>
      @zipEntries[entry.getName()] = entry

    @namespaces = @scanNamespaces()
    @namespaces.push 'foo'  # test

  toString: () -> @name ? 'ArtPack'  # TODO: maybe call getDescription()

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
      console.log 'artpacks texture:',fullname,[category,namespace,basename]
      
      return pathRP

    sounds: (fullname) ->
      [namespace, name] = splitNamespace fullname
      # TODO: optional categories to search all

      pathRP = "assets/#{namespace}/sounds/#{name}.ogg"

  getArrayBuffer: (name, type, isMeta=false) ->
    if typeof name != 'string'
      console.log('invalid artpacks resource name (not a string) requested:',name,type)
      throw new Error("invalid artpacks resource name (not a string) requested: #{JSON.stringify(name)} of #{type}")

    pathRP = @nameToPath[type](name)
    pathRP += '.mcmeta' if isMeta

    found = false

    # expand namespace wildcard, if any
    if pathRP.indexOf('*') == -1
      tryPaths = [pathRP]
    else
      tryPaths = (pathRP.replace('*', namespace) for namespace in @namespaces)

    for tryPath in tryPaths
      zipEntry = @zipEntries[tryPath]
      if zipEntry?
        return zipEntry.getData()

    return undefined # not found

  getFixedPathArrayBuffer: (path) -> @zipEntries[path]?.getData()
  getPackLogo: () ->
    return @logoURL if @logoURL

    arrayBuffer = @getFixedPathArrayBuffer 'pack.png'
    if arrayBuffer?
      blob = new Blob [arrayBuffer], {type: 'image/png'}
      @logoURL = URL.createObjectURL blob
    else
      # placeholder for no pack image
      # solid gray 2x2 processed with `pngcrush -rem alla -rem text` (for some reason, 1x1 doesn't crush)
      @logoURL = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAEUlEQVQYV2N48uTJfxBmgDEAg3wOrbpADeoAAAAASUVORK5CYII='

  getPackJSON: () ->
    return @json if @json?

    arrayBuffer = @getFixedPathArrayBuffer 'pack.mcmeta'
    return {} if not arrayBuffer?

    str = arrayBufferToString arrayBuffer
    @json = JSON.parse str

  getDescription: () ->
    return @getPackJSON()?.pack?.description ? @name

module.exports = (opts) ->
  return new ArtPacks(opts)


