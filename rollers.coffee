
loadRollerFrames = (cb) ->
  paths = []
  for frameNum in ['001', '002', '003', '004', '005', '006', '007', '008', '009', '010', '011', '012']
    paths.push("img/rollers."+frameNum+".png") 
  calls = []
  for p in paths
    calls.push(((p) -> ((cb2) -> loadSymbol(p, cb2)))(p))
  async.parallel(calls, cb)  
      
class RollerColumn
  # one column of animating rollers, origin is top-left
  constructor: (config, state, grp, rollerSymbols, offset) ->
    [@config, @state] = [config, state]

    @frames = []
    @grp = grp
    grid = @config.columnWidth
    rows = Math.ceil(@config.height / grid)
    offsets = (_.random(0, 20) for i in [0...rows])

    for i in [0...rollerSymbols.length]
      frame = new paper.Group()

      for row in [0...rows]
        y = row * grid

        offsetFrame = Math.floor(i + offsets[row]) % rollerSymbols.length
        tile = rollerSymbols[offsetFrame].place()
        tile.fitBounds(new paper.Rectangle(0, y, grid, grid))
        frame.addChild(tile)
      
      #rasterizeGroup(frame)
      #frame.visible = false
      @frames.push(frame)
      @grp.addChild(frame)
    @setPhase(.5)
    @grp.translate(offset)

  setPhase: (frac) =>
    # set roller angle, [0..1)
    chosen = clamp(Math.floor(frac * @frames.length), 0, @frames.length - 1)
    for i in [0...@frames.length]
      @frames[i].visible = i == chosen 
      
class window.Rollers
  # the whole floor under all the columns. bg + shadows
  constructor: (config, state, lyr) ->
    [@config, @state] = [config, state]

    @cols = ((new paper.Group()) for g in [0...@config.columnCount])
    loadRollerFrames((err, rollerSymbols) =>
      console.log("syms", rollerSymbols)

      for i in [0...@config.columnCount]
        
        col = new RollerColumn(config, state, @cols[i], rollerSymbols,
                               new paper.Point(@config.introColumn + @config.columnWidth * i, 0))
        #turn = ((col) => (() =>
        #  col.setPhase((+new Date() / 2000) % 1.0)))(col)
        #setInterval(turn, 10)
    )



  bakeColumn: (sym, h, scl) =>
    rollerColumn = new paper.Group()
    y = 0
    while y < @config.height
      rollerColumn.addChild(sym.place(new paper.Point(0, y)))
      y += h * scl
    rasterizeGroup(rollerColumn)

  step: (dt) =>
    