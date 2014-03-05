
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

packs = createArtPacks urls
packs.on 'loadedURL', (url) ->
  console.log 'Loaded ',url

# show some sample textures
# TODO: show _all_? In a grid? might be handy
showTextures = () ->
  for name in [
    'dirt',         # block, any namespace
    'blocks/dirt',  # longhand block
    'i/stick',      # item shorthand, any namespace
    'items/stick',  # longhand item
    'misc/shadow', # other texture type
    'minecraft:dirt',   # explicit namespace, block
    'water_flow',   # animated
    #'somethingelse:dirt',   # non-existent namespace
    'invalid'               # non-existent block
    ]

    container.appendChild document.createTextNode name + ' = '

    url = packs.getTexture(name)
    if not url?
      container.appendChild document.createTextNode '(not found)'
    else
      img = document.createElement 'img'
      img.src = url
      img.title = name

      container.appendChild img

      #URL.revokeObjectURL(url) # TODO?

    container.appendChild document.createElement 'br'

showSounds = () ->
  for name in ['liquid/splash']
    container.appendChild document.createTextNode 'sound: ' + name + ' = '
    url = packs.getSound(name)

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


showControls = () ->
  input = document.createElement 'input'
  input.setAttribute 'id', 'input'
  container.appendChild input

  container.appendChild document.createTextNode ' = '

  img = document.createElement 'img'
  img.setAttribute 'id', 'outputImg'
  img.style.visibility = 'hidden'
  container.appendChild img

  audio = document.createElement 'audio'
  audio.setAttribute 'id', 'outputAudio'
  audio.controls = true
  audio.style.visibility = 'hidden'
  container.appendChild audio

  showSample = () ->
    url = packs.getTexture(input.value)
    console.log "lookup #{input.value} = #{url}"
    if url?
      img.src = url
      img.style.visibility = ''
    else
      img.style.visibility = 'hidden'
      # maybe it is a sound? (note: different namespaces, obviously)
      url = packs.getSound(input.value)
      if url?
        audio.src = url
        audio.style.visibility = ''
      else
        audio.style.visibility = 'hidden'

  document.body.addEventListener 'keyup', showSample
  input.value = 'stone'
  showSample()

showInfo = () ->
  ps = packs.getLoadedPacks()
  s = "Loaded #{ps.length} packs: "
  for p in ps
    s += "#{p} "

  container.appendChild document.createTextNode s
  container.appendChild document.createElement 'br'
  container.appendChild document.createTextNode 'Drop a pack here to load (hold shift to append), or enter a name in text box below to lookup:'
  container.appendChild document.createElement 'br'
  container.appendChild document.createElement 'br'

packs.on 'loadedAll', (packs) ->
  console.log "Loaded all packs"
  container.removeChild(container.firstChild) while container.firstChild

  showInfo()
  showTextures()
  showSounds()
  showControls()


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
        packs.clear()

      packs.addPack arrayBuffer, file.name

    reader.readAsArrayBuffer(file)

container.addEventListener 'dragover', dragover, false
container.addEventListener 'dragleave', dragleave, false
container.addEventListener 'drop', drop, false



