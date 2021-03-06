
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
  constructor: (config, onSprites, sliderNum, x1, w, gapHeight) ->
    [@config, @x1, @w, @gapHeight] = [config, x1, w, gapHeight]
    # item's origin is at the * in the diagram
    @sliderNum = sliderNum
    @onSprites = onSprites

    @y = 200 + Math.random() * 200
    @moved = false

    @sliderOffset = Math.random() * 1.6 - .8
    @correctCenter = @config.height / 2 - @gapHeight / 2
   
    @rockAreas = [
      new paper.Rectangle(new paper.Point([0,0]), new paper.Size(@w, -1600)),
      new paper.Rectangle(new paper.Point([0,@gapHeight]), new paper.Size(@w, 1600))]

  createCargoShadow: () =>
    @shadow = new paper.Group()
    @shadow.translate(@x1, @y)
    
  createCargo: () =>
    @cargo = new paper.Group()
    @cargo.translate(@x1, @y)
    @addPreviews() if @config.showPreviews
    


    @top = new paper.Group()
    @bottom = new paper.Group()
    @cargo.addChild(@top)
    @cargo.addChild(@bottom)

    if @config.enableColumnTextures
      @addRockImages(1, @onSprites)

  addPreviews: =>
    previewArea = new paper.Group()
    previewArea.addChild(new paper.Path.Rectangle(r)) for r in @rockAreas
    previewArea.style = {strokeColor: 'white', strokeWidth: 2}
    @cargo.addChild(previewArea)

  addRockImages: (i, onSprites) =>

    onSprites (sprites) =>

      grid = @config.columnWidth

      randomSprite = () -> sprites[_.random(sprites.length - 1)]

      for y in [0..Math.ceil(@config.height / grid)]
        placed = randomSprite().place([0,0])
        placed.fitBounds(new paper.Rectangle(0, grid * (-y - 1), grid, grid))
        @top.addChild(placed)

        placed = randomSprite().place([0,0])
        placed.fitBounds(new paper.Rectangle(0, @gapHeight + grid * y, grid, grid))
        @bottom.addChild(placed)

      rasterizeGroup(@top)
      rasterizeGroup(@bottom)
      
  
  getGap: =>
    # returns gap rectangle in world space
    new paper.Rectangle([@x1, @y], [@w, @gapHeight])

  allWalls: =>
    # as an optimization, this could take the ship pos and only return walls that are facing that way
    [
      new paper.Line([@x1, 0], [@x1, @y], false), # top L
      new paper.Line([@x1 + @w, 0], [@x1 + @w, @y], false), # top R
      new paper.Line([@x1, @y], [@x1 + @w, @y], false), # gaptop
      new paper.Line([@x1, @y + @gapHeight], [@x1 + @w, @y + @gapHeight], false), # gapbottom
      new paper.Line([@x1, @y + @gapHeight], [@x1, 999], false), # bot L
      new paper.Line([@x1 + @w, @y + @gapHeight], [@x1 + @w, 999], false), # bot R
    ]
    
  offsetY: (dy) =>
    @y += dy
    @moved = true

  setFromSlider: (sliderValueNorm) =>
    # incoming is 0.0 for top, 1.0 for bottom
    trueOffset = (sliderValueNorm - .5) * 2 # -1 to 1
    bumpedOffset = trueOffset + @sliderOffset
    oldy = @y
    @y = @correctCenter + @config.height/2 * bumpedOffset
    @moved = @moved || Math.abs(oldy - @y) > 4

  getNormSlider: =>
    # returns 0 if the slider should be at the top ... 1 for bottom
    return ((@y - @correctCenter) / (@config.height/2) - @sliderOffset) / 2 + .5

  step: (dt) =>
    @y = clamp(@y, -@gapHeight, @config.height)
    # this don't-translate-by-0 is a major performance boost
    if (dy = @y - @cargo.matrix.translateY) != 0
      @cargo.translate(0, dy)
      @shadow.translate(0, dy)

class window.Columns
  constructor: (config, state) ->
    [@config, @state] = [config, state]

    # i think this is just a reimplementation of Deferred
    @sprites = []
    spritesReady = false
    waitingForSprites = []
    @loadSprites =>
      spritesReady = true
      w(@sprites) for w in waitingForSprites
    onSprites = (cb) =>
      if spritesReady
        cb(@sprites)
      else
        waitingForSprites.push(cb)

    w = @config.columnWidth
    gh1 = @config.column.startGapShips * @config.ship.collisionRadius
    gh2 = @config.column.endGapShips * @config.ship.collisionRadius

    @cols = [
      new Column(config, onSprites, 1, config.introColumn + 0 * w, w, tween(gh1, gh2, 0.0))
      new Column(config, onSprites, 2, config.introColumn + 1 * w, w, tween(gh1, gh2, 0.1))
      new Column(config, onSprites, 3, config.introColumn + 2 * w, w, tween(gh1, gh2, 0.2))
      new Column(config, onSprites, 4, config.introColumn + 3 * w, w, tween(gh1, gh2, 0.4))
      new Column(config, onSprites, 5, config.introColumn + 4 * w, w, tween(gh1, gh2, 0.6))
      new Column(config, onSprites, 6, config.introColumn + 5 * w, w, tween(gh1, gh2, 0.7))
      new Column(config, onSprites, 7, config.introColumn + 6 * w, w, tween(gh1, gh2, 0.8))
      new Column(config, onSprites, 8, config.introColumn + 7 * w, w, tween(gh1, gh2, 1.0))
      ]
    @introColumn =
      getGap: -> new paper.Rectangle([0, 0], [config.introColumn, 0]) # height = config.height

  createCargoShadows: () =>
    c.createCargoShadow() for c in @cols

  createCargo: () =>
    c.createCargo() for c in @cols
    return
    
    @item = new paper.Group()

    @item.addChild(c.item) for c in @cols
    @state.onEnter("finish", () => (c.moved = false) for c in @cols)

  loadSprites: (cb) =>
    sources = {
      "img/cargo-barrels.png": {
        size: [229, 229]
        offsets: [[86, 5], [325, 5], [90, 244], [325, 244]]
      }
      "img/cargo-rocks.png": {
        size: [223, 223]
        offsets: [[91, 9], [326, 9], [95, 248], [326, 248]]
      }
      "img/cargo-jewels.png": {
        size: [227, 227]
        offsets: [[89, 8], [324, 8], [88, 246], [323, 246]]
      }
    }
    allSpriteFuncs = []
    for path, s of sources
      ((path, s) ->
        s.tileSource = new TileSource(path)
        s.offsets.forEach((offset) ->
          allSpriteFuncs.push((cb) =>
            s.tileSource.getSymbol(new paper.Point(offset), new paper.Size(s.size), (err, sym) =>
              sym.offset = offset
              cb(err, sym)
            )
          )
        )
      )(path, s)
    async.parallel(allSpriteFuncs, (err, results) =>
      @sprites = results
      cb(null, @sprites)
    )


  checkMovement: ->
    for i in [0 ... @cols.length]
      if @cols[i].moved
        return true
    return false

  scramble: =>
    prev = 0
    for col in @cols
      yy = prev
      while Math.abs(yy - prev) < .1
        yy = Math.random()

      col.setFromSlider(yy)
      col.moved = false
      prev = yy

  setDebug: (ys) =>
    for col, i in @cols
      col.y = ys[i]

  getColumnNum: (x) ->
    # 1-based index
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
    # n is 1-based index
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
        if @state.elapsedMs() > 4000 && @checkMovement()
          (c.moved = false) for c in @cols
          @state.set("menu")
