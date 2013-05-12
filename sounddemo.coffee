$ ->

  context = new webkitAudioContext()

  explodeBuffer = null

  if true
    request = new XMLHttpRequest()
    request.open('GET', "snd/explode.wav", true);
    request.responseType = 'arraybuffer';

    request.onload = () ->
      context.decodeAudioData(request.response, ((buffer) ->
        explodeBuffer = buffer;
      ), () ->)

    request.send()
  
  $("#explode").click ->
    source = context.createBufferSource()
    source.buffer = explodeBuffer
    source.connect(context.destination)
    source.start(0)

    