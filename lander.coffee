reconnectingWebSocket = (url, onMessage) ->
  connect = ->
    ws = new WebSocket(url)
    ws.onopen = ->
      $("#status").text "connected"

    ws.onerror = (e) ->
      $("#status").text "error: " + e

    ws.onclose = ->
      pong = 1 - pong
      $("#status").text "disconnected (retrying " + ((if pong then "😼" else "😺")) + ")"
      
      # this should be under a requestAnimationFrame to
      # save resources
      setTimeout connect, 2000

    ws.onmessage = (evt) ->
      onMessage JSON.parse(evt.data)
  pong = 0
  connect()

class Ship
  constructor: ->
    @item = new paper.Group([])

    @item.addChild(new paper.Raster('ship1.png').scale(.3))
    @item.translate(new paper.Point(0, paper.view.size.height / 2))

  step: (dt) ->
    @item.translate([10 * dt, 0])

  position: -> @item.matrix.translation

class Column
  #
  # x1 -----w--->
  # |
  # |
  # *------------ y
  #              gap
  # +------------  
  # |
  # |
  # 
  constructor: (x1, w) ->
    [@x1, @w] = [x1, w]
    @item = new paper.Group()
    # item's origin is at the * in the diagram
    @top = new paper.Group()
    @bottom = new paper.Group()
    @item.addChild(@top)
    @item.addChild(@bottom)

    @y = 200 + Math.random() * 200
    @gap = 100

    @sliderOffset = Math.random() * .4 - .2

    @makeRocks()

    @rockAreas = [
      new paper.Rectangle(new paper.Point([0,0]), new paper.Size(@w, -1000)),
      new paper.Rectangle(new paper.Point([0,@gap]), new paper.Size(@w, 1000))]

    @previewArea = new paper.CompoundPath(
         [new paper.Path.Rectangle(r) for r in @rockAreas])
    @item.addChild(@previewArea)

    @item.style = {strokeColor: 'black', strokeWidth: 1}
 
    hue = 20 + Math.random() * 20
    @top.style = @bottom.style = {
      fillColor: new paper.HslColor(hue, .66, .41),
      strokeColor: new paper.HslColor(hue, .66, .20),
      strokeWidth: 2
      }
    @item.position = new paper.Point([@x1, @y])
   
    @item.translate(new paper.Point(@w/2, @gap/2)) # fixes some other error

  makeRocks: ->
    rad = 10
    @top.addChild(new paper.Path.Circle([
      Math.random() * @w,
      -Math.pow(Math.random(), 1.5) * 500], rad)) for i in [1..100]

    @bottom.addChild(new paper.Path.Circle([
      Math.random() * @w,
      @gap + Math.pow(Math.random(), 1.5) * 500], rad)) for i in [1..100]

  gapCenter: ->
    new paper.Point([@x1 + @w / 2, @y + @gap / 2])

  setFromSlider: (sliderValueNorm) ->
    # incoming is 0.0 for top, 1.0 for bottom
    correctCenter = paper.view.size.height / 2 - @gap / 2
    trueOffset = (sliderValueNorm - .5) * 2 # -1 to 1
    bumpedOffset = trueOffset + @sliderOffset
    @y = correctCenter + 300 * bumpedOffset

  step: (dt) ->
    0#@item.position.y = @y

class Columns
  constructor: ->
    @item = new paper.Group()

    w = 97
    @cols = [
      new Column(1*100, w)
      new Column(2*100, w)
      new Column(3*100, w)
      new Column(4*100, w)
      new Column(5*100, w)
      new Column(6*100, w)
      new Column(7*100, w)
      new Column(8*100, w)
      ]

    @item.addChild(c.item) for c in @cols

    @_bestPath = new paper.Path()
    @_bestPath.style = {strokeColor: 'yellow', strokeWidth: 3}

  updateBestPath: (ship) ->
    # maintain a Path from the given ship pos to the end, as far as we can go
    @_bestPath.removeSegments()
    @_bestPath.add(ship.position())
    x = ship.position().x
    for col in @cols
      if col.x1 > x
        @_bestPath.add(col.gapCenter())
    #@_bestPath.smooth()
    @_bestPath

  byNum: (n) ->
    @cols[n - 1]

  step: (dt) ->
    c.step(dt) for c in @cols

$ ->
  canvas = document.getElementById("game")
  setup = paper.setup(canvas) 
  view = setup.view

  ship = new Ship()
  columns = new Columns()

  onMessage = (d) ->
    if d.sliderEvent
      se = d.sliderEvent
      n = parseInt(se.name.replace("slider", ""))
      columns.byNum(n).setFromSlider((127 - se.value) / 127)
  reconnectingWebSocket "ws://localhost:9990/sliders", onMessage

  view.onFrame = (ev) ->
    ship.step(ev.delta)
    columns.step(ev.delta)
    columns.updateBestPath(ship)

  #view.onKeyDown = (ev) -> console.log("down", ev);
  view.onMouseDown = (ev) -> console.log("drag", ev);