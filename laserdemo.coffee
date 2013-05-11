
$ ->
  canvas = document.getElementById("game")
  canvas.width = 600
  canvas.height = 500
  setup = paper.setup(canvas)
  view = setup.view

  ras = new paper.Raster("img/laserdust.png")
  @dust = new paper.Symbol(ras)
  ras.onLoad = =>
    @dustTiles = new paper.Group()
    @dustTiles.addChild(@dust.place(new paper.Point(250, 200)))
    @dustTiles.addChild(@dust.place(new paper.Point(250, 200 + ras.height)))
    @dustTiles.addChild(@dust.place(new paper.Point(250, 200 + ras.height * 2)))
    @dustTiles.addChild(@dust.place(new paper.Point(250, 200 + ras.height * 3)))

    @beam = new paper.Group()
    @beam.addChild(new paper.Path.Line([5, 200], [600, 100]))
    @beam.addChild(new paper.Path.Line([5, 200], [600, 300]))
    
    @beam.style = {
      strokeWidth: 2
      strokeColor: 'red'
    }
    @dustLayer = new paper.Layer(@dustTiles)
    black = new paper.Path.Rectangle(view.bounds)
    black.style = {fillColor: 'green'}
    @beamLayer = new paper.Layer([black, @beam])
    @beamLayer.blendMode = 'multiply'

    view.onFrame = (ev) =>
      ms = +new Date()
      @dustTiles.position = new paper.Point(350, 0 + ((50 * ms / 5000) % ras.height))


  