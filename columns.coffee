
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
  constructor: (config, num, x1, w, gap) ->
    # i is 1-based index
    [@config, @num, @x1, @w] = [config, num, x1, w]
    @item = new paper.Group()
    # item's origin is at the * in the diagram

    @y = 200 + Math.random() * 200
    @moved = false
    @gapHeight = gap

    @sliderOffset = Math.random() * 1.6 - .8
    @correctCenter = @config.height / 2 - @gapHeight / 2

    @rockAreas = [
      new paper.Rectangle(new paper.Point([0,0]), new paper.Size(@w, -1000)),
      new paper.Rectangle(new paper.Point([0,@gapHeight]), new paper.Size(@w, 1000))]

    @addPreviews() if @config.showPreviews

    @top = new paper.Group()
    @bottom = new paper.Group()
    @item.addChild(@top)
    @item.addChild(@bottom)

    @addRockImages(num)

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

  allWalls: ->
    [
      new paper.Line([@x1, 0], [@x1, @y], false), # top L
      new paper.Line([@x1 + @w, 0], [@x1 + @w, @y], false), # top R
      new paper.Line([@x1, @y], [@x1 + @w, @y], false), # gaptop
      new paper.Line([@x1, @y + @gapHeight], [@x1 + @w, @y + @gapHeight], false), # gapbottom
      new paper.Line([@x1, @y + @gapHeight], [@x1, 999], false), # bot L
      new paper.Line([@x1 + @w, @y + @gapHeight], [@x1 + @w, 999], false), # bot R
    ]
    

  offsetY: (dy) ->
    @y += dy
    @moved = true

  setFromSlider: (sliderValueNorm) ->
    # incoming is 0.0 for top, 1.0 for bottom
    trueOffset = (sliderValueNorm - .5) * 2 # -1 to 1
    bumpedOffset = trueOffset + @sliderOffset
    oldy = @y
    @y = @correctCenter + @config.height/2 * bumpedOffset
    @moved = @moved || Math.abs(oldy - @y) > 4

  getNormSlider: ->
    # returns 0 if the slider should be at the top ... 1 for bottom
    return ((@y - @correctCenter) / (@config.height/2) - @sliderOffset) / 2 + .5

  step: (dt) ->
    @y = clamp(@y, -@gapHeight, @config.height)
    @item.matrix.translateY = @y



class window.Columns
  constructor: (config, state) ->
    [@config, @state] = [config, state]
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
      getGap: -> new paper.Rectangle([0, 0], [config.introColumn, 0]) # height = config.height

    @item.addChild(c.item) for c in @cols
    @state.onEnter("finish", () => (c.moved = false) for c in @cols)

  checkMovement: ->
    for i in [0 ... @cols.length]
      if @cols[i].moved
        return true
    return false

  scramble: ->
    prev = 0
    for col in @cols
      yy = prev
      while Math.abs(yy - prev) < .1
        yy = Math.random()

      col.setFromSlider(yy)
      col.moved = false
      prev = yy

  getColumnNum: (x) ->
    for i in [0 ... @cols.length]
      if @cols[i].x1 <= x < @cols[i].x1 + @cols[i].w
        return i + 1
    return -1

  withinColumn: (x) ->
    for col in @cols
      if col.x1 <= x < col.x1 + col.w
        return col
    return null

  byNum: (n) ->
    @cols[n - 1]

  allWalls: () ->
    # array of Line for every edge of every wall
    ret = []
    for col in @cols
      ret.push.apply(ret, col.allWalls())
    ret

  step: (dt) =>
    c.step(dt) for c in @cols

    switch @state.get()
      when "menu"
        if @state.elapsedMs() > 1000 && @checkMovement()
          (c.moved = false) for c in @cols
          @state.set("menu-away")
      when "finish"
        if @state.elapsedMs() > 1000 && @checkMovement()
          (c.moved = false) for c in @cols
          @state.set("menu")
