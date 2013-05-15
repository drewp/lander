window.makeStaticBg = (config) ->
  grp = new paper.Group()

  async.parallel({
    entryBracket: ((cb) ->
      loadSymbol("img/rollerbracket.jpg", (err, sym) =>
        grid = config.introColumn
        y = 0
        while y < config.height
          p = sym.place()
          p.fitBounds(new paper.Rectangle(0, y, grid, grid))
          grp.addChild(p)
          y += grid
        cb(null)
      )
    ),
    
    exitBracket: ((cb) ->   
      exitBox = new paper.Rectangle(new paper.Point(config.width - config.exitColumn, 0),
                                    new paper.Size(config.exitColumn, config.height))

      bg = new paper.Raster("img/rollerbracketb.jpg")
      bg.onLoad = =>
        bg.scale(config.exitColumn / bg.width, config.height / bg.height)
        bg.translate(exitBox.center)
        cb(null)
      grp.addChild(bg)
    ),
    
    rollerBgs: ((cb) ->
      async.parallel({
        bg: (cb2) -> loadSymbol("img/rollerbracket.jpg", cb2)
        shadow: (cb2) -> loadSymbol("img/rollers-shadow.png", cb2)
      }, (err, syms) =>
        grid = config.columnWidth

        for col in [0...config.columnCount]
          x = config.introColumn + col * config.columnWidth
          y = 0
          colTile = new paper.Group()
          while y < config.height + grid 
            fullTile = new paper.Group()
            
            tile = syms.bg.place()
            tile.fitBounds(new paper.Rectangle(x, y, grid, grid))
            fullTile.addChild(tile)

            tile = syms.shadow.place()
            tile.fitBounds(new paper.Rectangle(x, y, grid, grid))
            fullTile.addChild(tile)

            rasterizeGroup(fullTile)
            colTile.addChild(fullTile.firstChild)
            y += grid
          rasterizeGroup(colTile)
          grp.addChild(colTile)
        cb(null)
      )
    )},
    (err, results) ->
      rasterizeGroup(grp)
  )
      
  grp
