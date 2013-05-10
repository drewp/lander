# other simple objects in the scene

blink = (item, periodMs, onTimeMs, fade) ->
  now = +(new Date())
  item.opacity = fade * item.opacity + (1 - fade) * ((now % periodMs) > onTimeMs)
  

class window.Enter
  constructor: (config, state) ->
    [@config, @state] = [config, state]

    @img = new paper.Raster("img/enter.png")
    @lights = new paper.Raster("img/enter-lights.png")
    @grp = new paper.Group([@img, @lights])

    window.enter = @grp
    @img.onLoad = =>
      @grp.translate(@config.introColumn / 2 - 8, @config.height / 2)
      @grp.scale(@config.height / @img.height)

  step: (dt) =>
    if (@state.get() in ["menu", "menu-away"] ||
        (@state.get() == "play" && @state.elapsedMs() < 2000))
      @lights.visible = true
      blink(@lights, 2000, 1000, .3)
    else
      @lights.visible = false

class window.Exit
  constructor: (config, state) ->
    [@config, @state] = [config, state]


    @exit = new paper.Raster("img/exit.png")
    @bottom = new paper.Raster("img/exitdoor-bottom.png")
    @top = new paper.Raster("img/exitdoor-top.png")
    @lights = new paper.Raster("img/exit-lights.png")

    @grp = new paper.Group([@bottom, @top, @exit, @lights])

    @exit.onLoad = () =>
      @grp.scale(@config.height / @exit.height)
      @grp.translate([@config.introColumn +
                      @config.columnCount * @config.columnWidth +
                      @config.exitColumn / 2 - 15,
                      @config.height / 2])

  step: (dt) =>
    if @state.get() in ["play", "play-unlocked", "finish"]
      @lights.visible = true
      blink(@lights, 800, 400, .3)
    else
      @lights.visible = false

    if @state.get() == "play-unlocked"
      @bottom.matrix.translateY = clamp(@state.elapsedMs() / 10, 0, 60)
      @top.matrix.translateY = -@bottom.matrix.translateY
    else
      @top.matrix.translateY = 0
      @bottom.matrix.translateY = 0
    #opened = @state.get() == "play-unlocked" || @state.get() == "finish"
    #@open.visible = opened
    #@closed.visible = not opened