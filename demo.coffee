
createArtPacks = require './'

#urls = ['test2.zip', 'test.zip', 'testsnd.zip']
#urls = ['test2.zip', 'test.zip']
urls = ['https://dl.dropboxusercontent.com/u/258156216/artpacks/ProgrammerArt-2.1-dev-ResourcePack-20140116.zip', 'invalid.zip', 'README.md']

container = document.createElement 'div'
container.style.position = 'absolute'
container.style.height = '90%'
container.style.width = '90%'
container.style.border = '5px dotted black'
document.body.appendChild(container)

aps = createArtPacks urls
aps.on 'loadedURL', (url) ->
  console.log 'Loaded ',url

showTextures = (aps) ->
  for name in [
    'dirt',         # block, any namespace
    'blocks/dirt',  # longhand block
    'i/stick',      # item shorthand, any namespace
    'items/stick',  # longhand item
    'misc/shadow', # other texture type
    'minecraft:dirt',   # explicit namespace, block
    #'somethingelse:dirt',   # non-existent namespace
    'invalid'               # non-existent block
    ]

    container.appendChild document.createTextNode name + ' = '

    url = aps.getTexture(name)
    if not url?
      container.appendChild document.createTextNode '(not found)'
    else
      img = document.createElement 'img'
      img.src = url
      img.title = name

      container.appendChild img

      #URL.revokeObjectURL(url) # TODO?

    container.appendChild document.createElement 'br'

showSounds = (aps) ->
  for name in ['liquid/splash']
    container.appendChild document.createTextNode 'sound: ' + name + ' = '
    url = aps.getSound(name)

    if not url?
      container.appendChild document.createTextNode '(not found)'
    else
      console.log url

      audio = document.createElement 'audio'
      audio.src = url
      audio.controls = true
      audio.title = name

      container.appendChild audio


    container.appendChild document.createElement 'br'


aps.on 'loadedAll', (packs) ->
  console.log(aps)
  container.removeChild(container.firstChild) while container.firstChild
  showTextures(aps)
  showSounds(aps)


dragover = (ev) ->
  ev.stopPropagation()
  ev.preventDefault()
  container.style.border = '5px dashed black'

dragleave = (ev) ->
  ev.stopPropagation()
  ev.preventDefault()
  container.style.border = '5px dotted black'

drop = (mouseEvent) ->
  dragleave(mouseEvent)

  files = mouseEvent.target.files || mouseEvent.dataTransfer.files
  console.log 'Dropped',files
  for file in files
    console.log 'Reading dropped',file
    reader = new FileReader()
    reader.addEventListener 'load', (readEvent) ->
      return if readEvent.total != readEvent.loaded # TODO: progress bar

      arrayBuffer = readEvent.currentTarget.result

      if not mouseEvent.shiftKey
        # start over, replacing all current packs - unless shift is held down (then add to)
        aps.clear()

      aps.addPack arrayBuffer

    reader.readAsArrayBuffer(file)

container.addEventListener 'dragover', dragover, false
container.addEventListener 'dragleave', dragleave, false
container.addEventListener 'drop', drop, false



