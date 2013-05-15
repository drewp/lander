class window.TileSource
  # like a raster, but you can get Symbol rasters from sub-rectangles of this image
  constructor: (imgPath) ->
    @masterImg = new paper.Raster(imgPath)
    @masterImg.visible = false
    @pending = []
    @loaded = false
    @masterImg.onLoad = =>
      p() for p in @pending
      @loaded = true

  getSymbol: (topLeft, size, cb) =>
    # a slice of this image that can be place() like a Symbol. Async
    # because we need the image to be loaded. 

    makeSymbol = (topLeft, size, cb) =>
      crop = new paper.Path.Rectangle(topLeft, size)

      subImage = crop.rasterize()
      subImage.matrix.reset()
      subImage.setImageData(@masterImg.getImageData(crop), topLeft.multiply(-1))
      sym = new paper.Symbol(subImage)
      cb(null, {
        realSymbol: sym
        place: (pt) =>
          # I don't know why this offset seems to help. But, you might
          # pass pt=null and just use fitBounds, and then it won't
          # even matter.
          sym.place(@masterImg.bounds.bottomRight.add(pt))
      })

    if @loaded
      makeSymbol(topLeft, size, cb)
    else
      @pending.push(=> makeSymbol(topLeft, size, cb))


window.loadSymbol = (path, cb) ->
  ras = new paper.Raster(path)
  sym = new paper.Symbol(ras)
  ras.onLoad = () ->
    cb(null, sym)
  return

window.rasterizeGroup = (g, rasterizeRes) ->
  # replace g children with one rasterized version
  r = g.rasterize(rasterizeRes)
  g.removeChildren()
  g.addChild(r)
  g
