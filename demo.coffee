
createArtPacks = require './'

#urls = ['test2.zip', 'test.zip', 'testsnd.zip']
#urls = ['test2.zip', 'test.zip']
urls = ['https://dl.dropboxusercontent.com/u/258156216/artpacks/ProgrammerArt-2.1-dev-ResourcePack-20140116.zip']

aps = createArtPacks urls
aps.on 'loaded', (packs) ->
  return if packs.length != urls.length  # not all loaded yet

  console.log(aps)
  for name in [
    'dirt',         # block, any namespace
    'blocks/dirt',  # longhand block
    'i/stick',      # item shorthand, any namespace
    'items/stick',  # longhand item
    #'misc/shadow', # other texture type
    'minecraft:dirt',   # explicit namespace, block
    'somethingelse:dirt',   # non-existent namespace
    'invalid'               # non-existent block
    ]

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

  for name in ['liquid/splash']
    document.body.appendChild document.createTextNode 'sound: ' + name + ' = '
    blob = aps.getSound(name)

    if not blob?
      document.body.appendChild document.createTextNode '(not found)'
    else
      url = URL.createObjectURL(blob)
      console.log url

      audio = document.createElement 'audio'
      audio.src = url
      audio.controls = true
      audio.title = name

      document.body.appendChild audio

      #URL.revokeObjectURL(url) # TODO?


    document.body.appendChild document.createElement 'br'
