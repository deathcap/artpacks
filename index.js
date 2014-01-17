// Generated by CoffeeScript 1.6.3
(function() {
  var ArtPackArchive, ArtPacks, EventEmitter, ZIP, aps, binaryXHR, fs, path, splitNamespace,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ZIP = require('zip');

  path = require('path');

  fs = require('fs');

  binaryXHR = require('binary-xhr');

  EventEmitter = (require('events')).EventEmitter;

  ArtPacks = (function(_super) {
    __extends(ArtPacks, _super);

    function ArtPacks(packs) {
      var pack, _i, _len;
      this.packs = [];
      this.pending = {};
      for (_i = 0, _len = packs.length; _i < _len; _i++) {
        pack = packs[_i];
        this.addPack(pack);
      }
    }

    ArtPacks.prototype.addPack = function(pack) {
      var _this = this;
      if (pack instanceof ArrayBuffer) {
        return this.packs.push(new ArtPackArchive(pack));
      } else if (typeof pack === 'string') {
        this.pending[pack] = true;
        return binaryXHR(pack, function(err, packData) {
          _this.packs.push(new ArtPackArchive(packData));
          delete _this.pending[pack];
          return _this.emit('loaded', _this.packs);
        });
      } else {
        return this.packs.push(pack);
      }
    };

    ArtPacks.prototype.getTexture = function(name) {
      return this.getArt(name, 'textures');
    };

    ArtPacks.prototype.getSound = function(name) {
      return this.getArt(name, 'sounds');
    };

    ArtPacks.prototype.getArt = function(name, type) {
      var blob, pack, _i, _len, _ref;
      _ref = this.packs;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        pack = _ref[_i];
        blob = pack.getBlob(name, type);
        if (blob != null) {
          return blob;
        }
      }
      return void 0;
    };

    return ArtPacks;

  })(EventEmitter);

  splitNamespace = function(name) {
    var a, namespace;
    a = name.split(':');
    if (a.length > 1) {
      namespace = a[0], name = a[1];
    }
    if (namespace == null) {
      namespace = '*';
    }
    return [namespace, name];
  };

  ArtPackArchive = (function() {
    function ArtPackArchive(packData) {
      var _this = this;
      if (packData instanceof ArrayBuffer) {
        packData = new Buffer(new Uint8Array(packData));
      }
      this.zip = new ZIP.Reader(packData);
      this.zipEntries = {};
      this.zip.forEach(function(entry) {
        return _this.zipEntries[entry.getName()] = entry;
      });
      this.namespaces = this.scanNamespaces();
      this.namespaces.push('foo');
    }

    ArtPackArchive.prototype.scanNamespaces = function() {
      var namespaces, parts, zipEntryName, _i, _len, _ref;
      namespaces = {};
      _ref = Object.keys(this.zipEntries);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        zipEntryName = _ref[_i];
        parts = zipEntryName.split(path.sep);
        if (parts.length < 2) {
          continue;
        }
        if (parts[0] !== 'assets') {
          continue;
        }
        if (parts[1].length === 0) {
          continue;
        }
        namespaces[parts[1]] = true;
      }
      return Object.keys(namespaces);
    };

    ArtPackArchive.prototype.nameToPath = {
      textures: function(fullname) {
        var a, basename, category, namespace, partname, pathRP, _ref, _ref1;
        a = fullname.split('/');
        if (a.length > 1) {
          category = a[0], partname = a[1];
        }
        category = (_ref = {
          undefined: 'blocks',
          'i': 'items'
        }[category]) != null ? _ref : category;
        if (partname == null) {
          partname = fullname;
        }
        _ref1 = splitNamespace(partname), namespace = _ref1[0], basename = _ref1[1];
        pathRP = "assets/" + namespace + "/textures/" + category + "/" + basename + ".png";
        console.log(fullname, [category, namespace, basename]);
        return pathRP;
      },
      sounds: function(fullname) {
        var name, namespace, pathRP, _ref;
        _ref = splitNamespace(fullname), namespace = _ref[0], name = _ref[1];
        return pathRP = "assets/" + namespace + "/sounds/" + name + ".ogg";
      }
    };

    ArtPackArchive.prototype.mimeTypes = {
      textures: 'image/png',
      sounds: 'audio/ogg'
    };

    ArtPackArchive.prototype.getArrayBuffer = function(name, type) {
      var data, found, namespace, pathRP, tryPath, tryPaths, zipEntry, _i, _len;
      pathRP = this.nameToPath[type](name);
      found = false;
      if (pathRP.indexOf('*') === -1) {
        tryPaths = [pathRP];
      } else {
        tryPaths = (function() {
          var _i, _len, _ref, _results;
          _ref = this.namespaces;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            namespace = _ref[_i];
            _results.push(pathRP.replace('*', namespace));
          }
          return _results;
        }).call(this);
      }
      for (_i = 0, _len = tryPaths.length; _i < _len; _i++) {
        tryPath = tryPaths[_i];
        zipEntry = this.zipEntries[tryPath];
        if (zipEntry != null) {
          data = zipEntry.getData();
          return data;
        }
      }
      return void 0;
    };

    ArtPackArchive.prototype.getBlob = function(name, type) {
      var arrayBuffer;
      arrayBuffer = this.getArrayBuffer(name, type);
      if (arrayBuffer == null) {
        return void 0;
      }
      return new Blob([arrayBuffer], {
        type: this.mimeTypes[type]
      });
    };

    return ArtPackArchive;

  })();

  aps = new ArtPacks(['test2.zip', 'test.zip', 'testsnd.zip']);

  aps.on('loaded', function(packs) {
    var audio, blob, img, name, url, _i, _j, _len, _len1, _ref, _ref1, _results;
    if (packs.length !== 3) {
      return;
    }
    console.log(aps);
    _ref = ['dirt', 'i/stick', 'misc/shadow', 'minecraft:dirt', 'somethingelse:dirt', 'invalid'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      name = _ref[_i];
      document.body.appendChild(document.createTextNode(name + ' = '));
      blob = aps.getTexture(name);
      if (blob == null) {
        document.body.appendChild(document.createTextNode('(not found)'));
      } else {
        url = URL.createObjectURL(blob);
        img = document.createElement('img');
        img.src = url;
        img.title = name;
        document.body.appendChild(img);
      }
      document.body.appendChild(document.createElement('br'));
    }
    _ref1 = ['ambient/cave/cave1', 'damage/hit2'];
    _results = [];
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      name = _ref1[_j];
      document.body.appendChild(document.createTextNode('sound ' + name + ' = '));
      blob = aps.getSound(name);
      if (blob == null) {
        document.body.appendChild(document.createTextNode('(not found)'));
      } else {
        url = URL.createObjectURL(blob);
        audio = document.createElement('audio');
        audio.src = url;
        audio.controls = true;
        audio.title = name;
        document.body.appendChild(audio);
      }
      _results.push(document.body.appendChild(document.createElement('br')));
    }
    return _results;
  });

}).call(this);
