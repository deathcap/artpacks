
createArtPacks = require './'

#urls = ['test2.zip', 'test.zip', 'testsnd.zip']
#urls = ['test2.zip', 'test.zip']
urls = ['https://dl.dropboxusercontent.com/u/258156216/artpacks/ProgrammerArt-2.1-dev-ResourcePack-20140116.zip', 'invalid.zip', 'README.md']

aps = createArtPacks urls
aps.on 'loadedURL', (url) ->
  console.log 'Loaded ',url

aps.on 'loadedAll', (packs) ->
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

    url = aps.getTexture(name)
    if not url?
      document.body.appendChild document.createTextNode '(not found)'
    else
      img = document.createElement 'img'
      img.src = url
      img.title = name

      document.body.appendChild img

      #URL.revokeObjectURL(url) # TODO?

    document.body.appendChild document.createElement 'br'

  for name in ['liquid/splash']
    document.body.appendChild document.createTextNode 'sound: ' + name + ' = '
    url = aps.getSound(name)

    if not url?
      document.body.appendChild document.createTextNode '(not found)'
    else
      console.log url

      audio = document.createElement 'audio'
      audio.src = url
      audio.controls = true
      audio.title = name

      document.body.appendChild audio


    document.body.appendChild document.createElement 'br'
