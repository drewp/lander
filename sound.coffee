class window.Sound
  constructor: ->
    @context = new webkitAudioContext()

    @effects = {
      explode: @load("snd/explode.mp3")
    }

  play: (name, onFinished) =>
    if @effects[name].buffer == null
      console.log(name+" not loaded yet, skipping")
      return
    source = @context.createBufferSource()
    source.buffer = @effects[name].buffer
    source.connect(@context.destination)
    source.start(0)
    setTimeout((() ->
        onFinished() if onFinished?
      ), source.buffer.duration * 1000)

  load: (path) =>
    result = {buffer: null}
    request = new XMLHttpRequest()
    request.open('GET', path, true);
    request.responseType = 'arraybuffer';

    request.onload = () =>
      @context.decodeAudioData(request.response, ((buffer) =>
        result.buffer = buffer
      ), () =>)

    request.send()
    result