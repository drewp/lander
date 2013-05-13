
$ ->
  canvas = document.getElementById("game")
  canvas.width = 600
  canvas.height = 500
  setup = paper.setup(canvas)
  view = setup.view

  cargoSource = new window.TileSource("img/cargo-barrels.png")

  cargoSource.getSymbol(new paper.Point(86, 5), new paper.Size(229, 229), (err, sym) ->
    sym.place(new paper.Point(0, 0))
    sym.place().fitBounds(new paper.Rectangle(new paper.Point(229,0), new paper.Size(229, 229)))
  )

  