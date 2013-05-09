# other simple objects in the scene

class window.Enter
  constructor: (config, state) ->
    @config = config

    @img = new paper.Raster("img/enter.png")
    @img.setMatrix(new paper.Matrix().translate(60, @config.height / 2))

  step: (dt) ->


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
    opened = @state.get() == "play-unlocked"
    @open.visible = opened
    @closed.visible = not opened