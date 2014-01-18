# artpacks

Cascading texture/sounds artwork pack loader

## Usage

    var createArtpacks = require('artpacks');

    var artpacks = createArtpacks([url1, url2, url3, ...]);

    blob = artpacks.getTexture('name');
    blob = artpacks.getTexture('category/name');
    blob = artpacks.getTexture('namespace:category/name');
    blob = artpacks.getTexture('namespace:name');
    blob = artpacks.getSound('name');

The given URLs are loaded using binary XHR. A `loadedAll` event is emitted in case
you want to do something after all of the packs are loaded.

`getTexture` and `getSound` both return `Blob` objects per the W3C [File API](http://www.w3.org/TR/FileAPI/).
You can use `URL.createObjectURL(blob)` in the browser to get a `blob:` URL usable for `img` or `audio` src, etc.

Texture and sound names are accepted with or without a "namespace" prefix; if omitted, any namespace is accepted.
The loaded packs are searched until a match is found (cascading similar to Cascading Style Sheets), so you can 
load multiple packs and they will be logically combined together.

## Supported artpack formats

**ResourcePack**: a hierarchical zip archive format supporting textures, sounds, and other resources, 
developed by Mojang for Minecraft 1.6+. Many resource packs developed for Minecraft therefore should be compatible
with this module. If you're looking for a free artwork pack for voxel-related games, check out [ProgrammerArt](https://github.com/deathcap/ProgrammerArt),
specifically the ResourcePack distribution.

(Minecraft is property of Mojang specifications)

**Other formats**: 

## Example

Visit the online [demo](http://deathcap.github.io/artpacks/), or download some packs (not included) and then run `npm start`


## License

MIT

