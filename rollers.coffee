
class window.Rollers
  constructor: (config, state, lyr) ->
    [@config, @state] = [config, state]
    @img = new paper.Raster("img/rollerbracketstatic.png")

    @img.onLoad = =>
      [w, h] = [@img.width, @img.height]

      scl = @config.columnWidth / w
      @img.scale(scl)
      sym = new paper.Symbol(@img)
      x = @config.introColumn  + @config.columnWidth / 2
      while x < @config.width - @config.exitColumn
        ras = @bakeColumn(sym, h, scl)
        ras.translate(x, 0)
        lyr.addChild(ras)
        #ras.opacity = .3
        x += @config.columnWidth

  bakeColumn: (sym, h, scl) =>
    rollerColumn = new paper.Group()
    y = 0
    while y < @config.height
      rollerColumn.addChild(sym.place(new paper.Point(0, y)))
      y += h * scl
    rasterizeGroup(rollerColumn)

  step: (dt) =>
    