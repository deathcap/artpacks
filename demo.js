// Generated by CoffeeScript 1.6.3
(function() {
  var aps, createArtPacks;

  createArtPacks = require('./');

  aps = createArtPacks(['test2.zip', 'test.zip', 'testsnd.zip']);

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
