'use strict';

const createArtPacks = require('./');

//urls = ['test2.zip', 'test.zip', 'testsnd.zip'];
//urls = ['test2.zip', 'test.zip'];
const urls = ['https://dl.dropboxusercontent.com/u/258156216/artpacks/ProgrammerArt-2.2-dev-ResourcePack-20140308.zip', 'invalid.zip', 'README.md'];

const container = document.createElement('div');
container.style.position = 'absolute';
container.style.height = '90%';
container.style.width = '90%';
container.style.border = '5px dotted black';
document.body.appendChild(container);

const packs = createArtPacks(urls);
packs.on('loadedURL', (url) => {
  console.log('Loaded ',url);
});

// show some sample textures
// TODO: show _all_? In a grid? might be handy
function showTextures() {
  for (let name of [
    'dirt',         // block, any namespace
    'blocks/dirt',  // longhand block
    'i/stick',      // item shorthand, any namespace
    'items/stick',  // longhand item
    'misc/shadow', // other texture type
    'minecraft:dirt',   // explicit namespace, block
    'grass_top',    // colorize
    'water_flow',   // animated
    //'somethingelse:dirt',   // non-existent namespace
    'invalid'               // non-existent block
    ]) {
    show(name);
  }
}

function show(name) {
  packs.getTextureImage(name, (img) => {
    if (Array.isArray(img)) {
      container.appendChild(document.createTextNode(`${name} = (animated ${img.length}) `));
      for (let im of img) {
        im.title = name;
        container.appendChild(im);
        container.appendChild(document.createTextNode(', '));
      }
    } else {
      container.appendChild(document.createTextNode(`${name} = `));
      img.title = name;
      container.appendChild(img);
      container.appendChild(document.createElement('br'));
    }
  }, (err) => {
    container.appendChild(document.createTextNode(name + ' = '));
    container.appendChild(document.createTextNode('(not found)'));
    container.appendChild(document.createElement('br'));
  });
}

function showSounds() {
  for (let name of ['liquid/splash']) {
    container.appendChild(document.createTextNode(`sound: ${name} = `));
    const url = packs.getSound(name);

    if (url === undefined) {
      container.appendChild(document.createTextNode('(not found)'));
    } else {
      console.log(url);

      const audio = document.createElement('audio');
      audio.src = url;
      audio.controls = true;
      audio.title = name;

      container.appendChild(audio);
    }

    container.appendChild(document.createElement('br'));
  }
}


function showControls() {
  const controls = document.createElement('div');

  const input = document.createElement('input');
  input.setAttribute('id', 'input');
  controls.appendChild(input);

  controls.appendChild(document.createTextNode(' = '));

  const img = document.createElement('img');
  img.setAttribute('id', 'outputImg');
  img.style.visibility = 'hidden';
  controls.appendChild(img);

  const audio = document.createElement('audio');
  audio.setAttribute('id', 'outputAudio');
  audio.controls = true;
  audio.style.visibility = 'hidden';
  controls.appendChild(audio);

  function showSample() {
    let url = packs.getTexture(input.value);
    console.log(`lookup ${input.value} = ${url}`);
    if (url === undefined) {
      img.src = url;
      img.style.visibility = '';
    } else {
      img.style.visibility = 'hidden';
      // maybe it is a sound? (note: different namespaces, obviously)
      url = packs.getSound(input.value);
      if (url === undefined) {
        audio.src = url;
        audio.style.visibility = '';
      } else {
        audio.style.visibility = 'hidden';
      }
    }
  }

  document.body.addEventListener('keyup', showSample);
  input.value = 'stone';
  container.appendChild(controls);
  showSample();
}

function showInfo() {
  const ps = packs.getLoadedPacks();
  let s = `Loaded ${ps.length} packs: `;
  for (let p of ps) {
    s += `${p} `;
  }

  container.appendChild(document.createTextNode(s));
  container.appendChild(document.createElement('br'));
  container.appendChild(document.createTextNode('Drop a pack here to load (hold shift to replace), or enter a name in text box below to lookup:'));
  container.appendChild(document.createElement('br'));
  container.appendChild(document.createElement('br'));
}

packs.on('loadedAll', (packs) => {
  console.log("Loaded all packs");
  while (container.firstChild) {
    container.removeChild(container.firstChild);
  }

  showInfo();
  showTextures();
  showSounds();
  showControls();
});


function dragover(ev) {
  ev.stopPropagation();
  ev.preventDefault();
  container.style.border = '5px dashed black';
}

function dragleave(ev) {
  ev.stopPropagation();
  ev.preventDefault();
  container.style.border = '5px dotted black';
}

function drop(mouseEvent) {
  dragleave(mouseEvent);

  const files = mouseEvent.target.files || mouseEvent.dataTransfer.files;
  console.log('Dropped',files);
  for (let i = 0; i < files.length; ++i) {
    const file = files[i];
    console.log('Reading dropped',file);
    const reader = new FileReader();
    reader.addEventListener('load', (readEvent) => {
      if (readEvent.total !== readEvent.loaded) return; // TODO: progress bar

      const arrayBuffer = readEvent.currentTarget.result;

      if (mouseEvent.shiftKey) {
        // if shift is held down: start over, replacing all current packs
        packs.clear();
      }

      packs.addPack(arrayBuffer, file.name);
    });

    reader.readAsArrayBuffer(file);
  }
}

container.addEventListener('dragover', dragover, false);
container.addEventListener('dragleave', dragleave, false);
container.addEventListener('drop', drop, false);
