'use strict';

const ZIP = require('zip');
const path = require('path');
const fs = require('fs');
const binaryXHR = require('binary-xhr');
const EventEmitter = (require('events').EventEmitter);
const getFrames = require('mcmeta');
const getPixels = require('get-pixels');
const savePixels = require('save-pixels');
const graycolorize = require('graycolorize');

// convert UTF-8 ArrayBuffer to string - see http://stackoverflow.com/questions/17191945/conversion-between-utf-8-arraybuffer-and-string
function arrayBufferToString(arrayBuffer) {
  return String.fromCharCode.apply(null, new Uint8Array(arrayBuffer));
}

class ArtPacks extends EventEmitter {
  constructor(packs) {
    super();
    this.packs = [];
    this.pending = {};
    this.blobURLs = {};
    this.shouldColorize = { 'grass_top':true, 'leaves_oak':true };  // TODO: more comprehensive, configurable

    this.setMaxListeners(0);    // since each texture can this.on 'loadedAll'.. it adds up

    for (let pack of packs) {
      this.addPack(pack);
    }
  }

  addPack(x, name) {
    if (x instanceof ArrayBuffer) {
      const rawZipArchiveData = x;
      this.packs.push(new ArtPackArchive(rawZipArchiveData, name ? name : `(${rawZipArchiveData.byteLength} raw bytes)`));
      this.refresh();
      this.emit('loadedRaw', rawZipArchiveData);
      this.emit('loadedAll');
    } else if (typeof x === 'string') {
      const url = x;

      if (window.XMLHttpRequest === undefined) {
        throw new Error(`artpacks unsupported addPack url ${x} without XMLHttpRequest`);
      }

      this.pending[url] = true;
      packIndex = this.packs.length;
      this.packs[packIndex] = null; // save place while loading
      this.emit('loadingURL', url);
      binaryXHR(url, (err, packData) => {
        if (this.packs[packIndex] != null) {
          console.log(`artpacks warning: index ${packIndex} occupied, expected to be empty while loading ${url}`);
        }

        if (err || !packData) {
          console.log(`artpack failed to load #${packIndex} - ${url}: ${err}`);
          this.emit('failedURL', url, err);
          delete this.pending[url];
          return;
          // this.packs[packIndex] stays null
        }

        try {
          this.packs[packIndex] = new ArtPackArchive(packData, url);
          this.refresh();
        } catch (e) {
          console.log(`artpack failed to parse #${packIndex} - ${url}: ${e}`);
          this.emit('failedURL', url, e);
          // fallthrough
        }

        delete this.pending[url];

        console.log('artpacks loaded pack:',url);
        this.emit('loadedURL', url);
        if (Object.keys(this.pending).length === 0) {
          this.emit('loadedAll');
        }
      }
    } else {
      const pack = x;
      this.emit('loadedPack', pack);
      this.emit('loadedAll');
      this.packs.push(pack);  // assumed to be ArtPackArchive
      this.refresh();
    }
  }


  // swap the ordering of two loaded packs
  swap(i, j) {
    if (i === j) return;

    const temp = this.packs[i];
    this.packs[i] = this.packs[j];
    this.packs[j] = temp;
    this.refresh();
  }

  colorize(img, onload, onerror) {
    getPixels(img.src, (err, pixels) => {
      if (err) {
        return onerror(err, img);
      }

      // see https://en.wikipedia.org/wiki/HSL_color_space#HSV_.28Hue_Saturation_Value.29
      if (this.colorMap === undefined) {
        this.colorMap = graycolorize.generateMap(120/360, 0.7);
      }

      graycolorize(pixels, this.colorMap);

      const img2 = new Image();
      img2.src = savePixels(pixels, 'canvas').toDataURL();
      img2.onload = () => onload(img2);
      img2.onerror = (err) => onerror(err, img2);
    });
  }

  getTextureNdarray(name, onload, onerror) {
    function onload2(img) {
      if (Array.isArray(img)) {
        // TODO: support multiple textures (animation frame strips), add another dimension to the ndarray? (always)
        // currently, only using first frame
        img = img[0];
      }

      // get as [m,n,4] RGBA ndarray
      getPixelsx(img.src, (err, pixels) => {
        if (err) {
          return onerror(err, img)
        }

        onload(pixels);
      });
    }

    this.getTextureImage(name, onload2, onerror);
  }

  // TODO: refactor to operate on ndarray directly
  getTextureImage(name, onload, onerror) {
    const img = new Image();

    function load() {
      const url = this.getTexture name;
      if (!url) {
        return onerror(`no such texture in artpacks: ${name}`, img);
      }

      img.src = url;
      img.onload = () => {
        if (this.shouldColorize[name]) {
          return this.colorize(img, onload, onerror);
        }

        if (img.height === img.width) {
          // assumed static image
          onload(img);
        } else {
          // possible multi-frame texture strip; read .mcmeta file
          const json = this.getMeta(name, 'textures');
          console.log('.mcmeta=',json);

          getPixels(img.src, (err, pixels) => {
            if (err) {
              return onerror(err, img);
            }

            const frames = getFrames(pixels, json);
            let loaded = 0;
            let frameImgs = [];

            // load each frame
            frames.forEach((frame) => {
              const frameImg = new Image()
              const frameImg.src = frame.image;

              frameImg.onerror = (err) => {
                onerror(err, img, frameImg);
              };
              frameImg.onload = () => {
                frameImgs.push(frameImg);

                if (frameImgs.length === frames.length) {
                  if (frameImgs.length === 1) {
                    onload(frameImgs[0]);
                  } else {
                    // array of frames
                    onload(frameImgs);
                  }
                }
              }
            });
          });
        }
      }

      img.onerror = (err) => {
        onerror(err, img);
      }
    }

    if (this.isQuiescent()) {
      load();
    } else {
      this.on('loadedAll', load);
    }
  }

  getTexture(name) {
    return this.getURL(name, 'textures');
  }

  getSound(name) {
    return this.getURL(name, 'sounds');
  }

  getURL: (name, type) ->
    # already have URL?
    url = this.blobURLs[type + ' ' + name]
    return url if url?

    # get a blob
    blob = this.getBlob(name, type)
    return undefined if not blob?

    # create URL and return
    url = URL.createObjectURL(blob)
    this.blobURLs[type + ' ' + name] = url
    return url

  mimeTypes:
    textures: 'image/png'
    sounds: 'audio/ogg'

  getBlob: (name, type) ->
    arrayBuffer = this.getArrayBuffer name, type, false
    return undefined if not arrayBuffer?

    return new Blob [arrayBuffer], {type: this.mimeTypes[type]}

  getArrayBuffer: (name, type, isMeta) ->
    for pack in this.packs.slice(0).reverse()     # search packs in reverse order
      continue if !pack
      arrayBuffer = pack.getArrayBuffer(name, type, isMeta)
      return arrayBuffer if arrayBuffer?

    return undefined

  getMeta: (name, type) ->
    arrayBuffer = this.getArrayBuffer name, type, true
    return undefined if not arrayBuffer?

    encodedString = arrayBufferToString arrayBuffer
    decodedString = decodeURIComponent(escape(encodedString))

    json = JSON.parse(decodedString)

    return json

  # revoke all URLs to reload from packs list
  refresh: () ->
    for url in this.blobURLs
      URL.revokeObjectURL(url)
    this.blobURLs = []
    this.emit 'refresh'

  # delete all loaded packs
  clear: () ->
    this.packs = []
    this.refresh()

  getLoadedPacks: () ->
    ret = []
    for pack in this.packs.slice(0).reverse()
      ret.push pack if pack?
    return ret

  isQuiescent: () -> # have at least 1 pack loaded, and no more left to go
    return this.getLoadedPacks().length > 0 and Object.keys(this.pending).length == 0

# optional 'namespace:' prefix (as in namespace:foo), defaults to anything
splitNamespace = (name) ->
  a = name.split ':'
  [namespace, name] = a if a.length > 1
  namespace ?= '*'

  return [namespace, name]


class ArtPackArchive
  # Load pack given binary data + optional informative name
  constructor: (packData, this.name=undefined) ->
    if packData instanceof ArrayBuffer
      # zip with bops uses Uint8Array data view
      packData = new Uint8Array(packData)
    this.zip = new ZIP.Reader(packData)

    this.zipEntries = {}
    this.zip.forEach (entry) =>
      this.zipEntries[entry.getName()] = entry

    this.namespaces = this.scanNamespaces()
    this.namespaces.push 'foo'  # test

  toString: () -> this.name ? 'ArtPack'  # TODO: maybe call getDescription()

  # Get list of "namespaces" with a resourcepack
  # all of assets/<foo>
  scanNamespaces: () -> # TODO: only if RP
    namespaces = {}

    for zipEntryName in Object.keys(this.zipEntries)
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

    pathRP = this.nameToPath[type](name)
    pathRP += '.mcmeta' if isMeta

    found = false

    # expand namespace wildcard, if any
    if pathRP.indexOf('*') == -1
      tryPaths = [pathRP]
    else
      tryPaths = (pathRP.replace('*', namespace) for namespace in this.namespaces)

    for tryPath in tryPaths
      zipEntry = this.zipEntries[tryPath]
      if zipEntry?
        return zipEntry.getData()

    return undefined # not found

  getFixedPathArrayBuffer: (path) -> this.zipEntries[path]?.getData()
  getPackLogo: () ->
    return this.logoURL if this.logoURL

    arrayBuffer = this.getFixedPathArrayBuffer 'pack.png'
    if arrayBuffer?
      blob = new Blob [arrayBuffer], {type: 'image/png'}
      this.logoURL = URL.createObjectURL blob
    else
      # placeholder for no pack image
      # solid gray 2x2 processed with `pngcrush -rem alla -rem text` (for some reason, 1x1 doesn't crush)
      this.logoURL = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAEUlEQVQYV2N48uTJfxBmgDEAg3wOrbpADeoAAAAASUVORK5CYII='

  getPackJSON: () ->
    return this.json if this.json?

    arrayBuffer = this.getFixedPathArrayBuffer 'pack.mcmeta'
    return {} if not arrayBuffer?

    str = arrayBufferToString arrayBuffer
    this.json = JSON.parse str

  getDescription: () ->
    return this.getPackJSON()?.pack?.description ? this.name

module.exports = (opts) ->
  return new ArtPacks(opts)


