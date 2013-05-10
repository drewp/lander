# other simple objects in the scene

class window.Enter
  constructor: (config, state) ->
    [@config, @state] = [config, state]

    @img = new paper.Raster("img/enter.png")
    @lights = new paper.Raster("img/enter-lights.png")
    @grp = new paper.Group([@img, @lights])

    window.enter = @grp
    @img.onLoad = =>
      @grp.translate(@config.introColumn / 2 + 70, @config.height / 2)
      @grp.scale(@config.height / @img.height)

  step: (dt) =>
    if (@state.get() in ["menu", "menu-away"] ||
      (@state.get() == "play" && @state.elapsedMs() < 2000))
      now = +(new Date())
      @lights.visible = true
      @lights.opacity = .3 * @lights.opacity + .7 * ((now % 2000) > 1000)
    else
      @lights.visible = false

class window.Exit
  constructor: (config, state) ->
    [@config, @state] = [config, state]

    @img = new paper.Group()
    @closed = new paper.Raster("img/exit-closed.png")
    @open = new paper.Raster("img/exit-open.png")
    @img.addChild(@closed)
    @img.addChild(@open)
    @closed.onLoad = () =>
      @img.translate([@config.introColumn +
                      @config.columnCount * @config.columnWidth +
                      @closed.bounds.width / 2,
                      @config.height / 2])

  step: (dt) =>
    opened = @state.get() == "play-unlocked" || @state.get() == "finish"
    @open.visible = opened
    @closed.visible = not opened