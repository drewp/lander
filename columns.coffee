
class Column
  #
  # x1 -----w--->
  # |
  # |
  # *------------ y
  #        gapHeight
  # +------------
  # |
  # |
  #
  constructor: (config, i, x1, w, gap) ->
    # i is 1-based index
    [@config, @x1, @w] = [config, x1, w]
    @item = new paper.Group()
    # item's origin is at the * in the diagram

    @y = 200 + Math.random() * 200
    @gapHeight = gap

    @sliderOffset = Math.random() * .4 - .2

    @rockAreas = [
      new paper.Rectangle(new paper.Point([0,0]), new paper.Size(@w, -1000)),
      new paper.Rectangle(new paper.Point([0,@gapHeight]), new paper.Size(@w, 1000))]

    @addPreviews() if @config.showPreviews

    @top = new paper.Group()
    @bottom = new paper.Group()
    @item.addChild(@top)
    @item.addChild(@bottom)

    @addRockImages(i)

    @item.translate(@x1, @y)

  addPreviews: ->
    previewArea = new paper.Group()
    previewArea.addChild(new paper.Path.Rectangle(r)) for r in @rockAreas
    previewArea.style = {strokeColor: 'white', strokeWidth: 1}
    @item.addChild(previewArea)

  addRockImages: (i) ->
    img = "img/rock"+i+".png"
    r = new paper.Raster(img)
    rw = 100
    rh = 1200
    @top.addChild(r.scale([@config.columnWidth / rw, 1]).translate([@w / 2, -rh / 2]))
    r = new paper.Raster(img)
    @bottom.addChild(r.scale([@config.columnWidth / rw, 1]).translate([@w / 2, @gapHeight + rh / 2]))

  getGap: ->
    # returns gap rectangle in world space
    new paper.Rectangle([@x1, @y], [@w, @gapHeight])

  offsetY: (dy) ->
    @y += dy

  setFromSlider: (sliderValueNorm) ->
    # incoming is 0.0 for top, 1.0 for bottom
    correctCenter = paper.view.size.height / 2 - @gapHeight / 2
    trueOffset = (sliderValueNorm - .5) * 2 # -1 to 1
    bumpedOffset = trueOffset + @sliderOffset
    @y = correctCenter + 300 * bumpedOffset

  step: (dt) ->
    @y = clamp(@y, @config.minVisibleRock, @config.height - @config.minVisibleRock - @gapHeight)
    @item.matrix.translateY = @y



class window.Columns
  constructor: (config) ->
    @config = config
    @item = new paper.Group()

    w = @config.columnWidth
    gh1 = @config.startingGap
    gh2 = @config.ship.collisionRadius * 3
    @cols = [
      new Column(config, 1, config.introColumn + 0 * w, w, tween(gh1, gh2, 0.0))
      new Column(config, 2, config.introColumn + 1 * w, w, tween(gh1, gh2, 0.1))
      new Column(config, 3, config.introColumn + 2 * w, w, tween(gh1, gh2, 0.2))
      new Column(config, 4, config.introColumn + 3 * w, w, tween(gh1, gh2, 0.4))
      new Column(config, 5, config.introColumn + 4 * w, w, tween(gh1, gh2, 0.6))
      new Column(config, 6, config.introColumn + 5 * w, w, tween(gh1, gh2, 0.7))
      new Column(config, 7, config.introColumn + 6 * w, w, tween(gh1, gh2, 0.8))
      new Column(config, 8, config.introColumn + 7 * w, w, tween(gh1, gh2, 1.0))
      ]
    @introColumn =
      getGap: -> new paper.Rectangle([0, 0], [config.introColumn, config.height])


    @item.addChild(c.item) for c in @cols

  nextColumns: (x) ->
    # [null, null] if we're in or beyond the last column. Otherwise
    # [this,next] Column objects.
    for i in [0 ... @cols.length]
      if @cols[i].x1 > x + @config.columnLookAhead
        cur = if i == 0 then @introColumn else @cols[i - 1]
        return [cur, @cols[i]]
    return [null, null]

  withinColumn: (x) ->
    for col in @cols
      if col.x1 <= x < col.x1 + col.w
        return col
    return null

  byNum: (n) ->
    @cols[n - 1]

  step: (dt) ->
    c.step(dt) for c in @cols
