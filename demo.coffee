
createArtPacks = require './'

aps = createArtPacks ['test2.zip', 'test.zip', 'testsnd.zip']
aps.on 'loaded', (packs) ->
  return if packs.length != 3 # not all loaded yet

  console.log(aps)
  for name in ['dirt', 'i/stick', 'misc/shadow', 'minecraft:dirt', 'somethingelse:dirt', 'invalid']
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

  for name in ['ambient/cave/cave1', 'damage/hit2']
    document.body.appendChild document.createTextNode 'sound ' + name + ' = '
    blob = aps.getSound(name)

    if not blob?
      document.body.appendChild document.createTextNode '(not found)'
    else
      url = URL.createObjectURL(blob)

      audio = document.createElement 'audio'
      audio.src = url
      audio.controls = true
      audio.title = name

      document.body.appendChild audio

      #URL.revokeObjectURL(url) # TODO?


    document.body.appendChild document.createElement 'br'
