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


showPreviews = false


class Exhaust
  constructor: (getSource) ->
    @getSource = getSource

    @img = new paper.Raster('smoke1.png')
    @img.opacity = .2

    @pts = []
    @bornPerSec = 2
    @totalAlive = 500
    @driftVel = 1.3
  step: (dt) ->
    s = @getSource()
    for i in [0...@bornPerSec*dt]
      p = @img.clone()
      p.rotation = Math.random() * 360
      p.position = s.add(paper.Point.random().multiply(8))
      p.vel = paper.Point.random().multiply(@driftVel * 2).subtract(@driftVel)
      @pts.push(p)
    for p in @pts
      p.position = p.position.add(p.vel.multiply(dt))
    if @pts.length > @totalAlive
      for p in @pts[0..@pts.length-@totalAlive]
        p.remove()
  
      @pts[0..@pts.length-@totalAlive] = []

class Ship
  constructor: (columns) ->
    @columns = columns
    @item = new paper.Group([])

    @img = new paper.Raster('ship1.png')
    @img.scale(.3)
    @item.addChild(@img)
    @item.translate(new paper.Point(0, paper.view.size.height / 2))

    @heading = new paper.Point(90, 0)
    @accel = new paper.Point(0, 0)

    @flyToward = new paper.Point(500, 100)
  
    if showPreviews
      @flyTowardPreview = new paper.Path.Circle(@flyToward, 9)
      @flyTowardPreview.style = {strokeColor: 'white'}

      @idealPreview = new paper.Path.Line([0,0], [0,0])
      @idealPreview.style = {strokeColor: 'green'}

      @currentPreview = new paper.Path.Line([0,0], [0,0])
      @currentPreview.style = {strokeColor: 'blue'}

  getExhaustSource: ->
    @item.matrix.translation # should be the rotated tail point with direction
  
  updateFlyToward: ->
#        |              ||               |
#        |              ||               |
#        +--------------+|               |
#                        +---------------+
#             gap1            gap2
#        +--------------+
#        |              |+---------------+
#                        |               |

    [c1, c2] = @columns.nextColumns(@item.matrix.translation.x)
    if c1 == null
      @flyToward = @item.matrix.translation.add([20, 0])
    else
      [gap1, gap2] = [c1.getGap(), c2.getGap()]

      if showPreviews
        @gap1Preview.remove() if @gap1Preview?; 
        @gap2Preview.remove() if @gap2Preview?; 
        (@gap1Preview = new paper.Path.Rectangle(gap1.expand(-2))).style = {strokeColor: '#ff0000'}
        (@gap2Preview = new paper.Path.Rectangle(gap2)).style = {strokeColor: '#ffff00'}

      topInt = paper.Point.max(gap1.topRight, gap2.topLeft)
      botInt = paper.Point.min(gap1.bottomRight, gap2.bottomLeft)

      if topInt.y >= botInt.y
        # stuck; just hover
        @flyToward = gap1.center
      else
        @flyToward = topInt.add(botInt).divide(2)

    @flyTowardPreview.position = @flyToward if @flyTowardPreview?

  updatePreviewLine: (path, pt, angle) ->
    path.firstSegment.point = pt
    path.lastSegment.point = pt.add(new paper.Point([100, 0]).rotate(angle))

  setImageAngle: (angle) ->
    @img.rotate(angle - @img.matrix.rotation)

  updateHeading: (dt) ->
    pos = @item.matrix.translation

    idealAngle = @flyToward.subtract(pos).angle

    $("#ship").text("angle "+Math.round(@heading.angle)+
                    " ideal "+Math.round(idealAngle))
    maxDegPerSec = 30

    clampedIdealAngle = Math.min(80, Math.max(-80, idealAngle))

    requiredTurn = clampedIdealAngle - @heading.angle
    if Math.abs(requiredTurn) > 50
      if @heading.length > .001
        @heading = @heading.multiply(.7)
    else
      if @heading.length < 120
        @heading = @heading.multiply(1.15)
  
    frameTurn = Math.min(maxDegPerSec * dt, Math.max(-maxDegPerSec * dt, requiredTurn))
    @heading = @heading.rotate(frameTurn, [0, 0])
    @setImageAngle(@heading.angle)

    @updatePreviewLine(@idealPreview, pos, clampedIdealAngle) if @idealPreview?
    @updatePreviewLine(@currentPreview, pos, @img.matrix.rotation) if @currentPreview?
  
  step: (dt) ->
    @updateFlyToward()
    @updateHeading(dt)

    @item.translate(@heading.multiply(dt))

  position: -> @item.matrix.translation

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
  constructor: (x1, w, gap) ->
    [@x1, @w] = [x1, w]
    @item = new paper.Group()
    # item's origin is at the * in the diagram
    @top = new paper.Group()
    @bottom = new paper.Group()
    @item.addChild(@top)
    @item.addChild(@bottom)

    @y = 200 + Math.random() * 200
    @gapHeight = gap

    @sliderOffset = Math.random() * .4 - .2

    @makeRocks()

    @rockAreas = [
      new paper.Rectangle(new paper.Point([0,0]), new paper.Size(@w, -1000)),
      new paper.Rectangle(new paper.Point([0,@gapHeight]), new paper.Size(@w, 1000))]

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

    @top.translate(   new paper.Point(@w/2, 0)) # fixes some other error
    @bottom.translate(new paper.Point(@w/2, 0)) # fixes some other error

  makeRocks: ->
    randWithin = (a,b,exp) -> a + (b-a)*Math.pow(Math.random(), exp or 1)

    rad = 16
    n = 60
    @top.addChild(new paper.Path.Circle([
      randWithin(rad, @w - rad),
      randWithin(0 - rad, -400, 1.5)], rad)) for i in [1..n]

    @bottom.addChild(new paper.Path.Circle([
      randWithin(rad, @w - rad),
      randWithin(@gapHeight + rad, 400, 1.5)], rad)) for i in [1..n]

  getGap: ->
    # returns gap rectangle in world space
    new paper.Rectangle(@item.position, [@w, @gapHeight])

  offsetY: (dy) ->
    @y += dy

  setFromSlider: (sliderValueNorm) ->
    # incoming is 0.0 for top, 1.0 for bottom
    correctCenter = paper.view.size.height / 2 - @gapHeight / 2
    trueOffset = (sliderValueNorm - .5) * 2 # -1 to 1
    bumpedOffset = trueOffset + @sliderOffset
    @y = correctCenter + 300 * bumpedOffset

  step: (dt) ->
    @item.position.y = @y

class Columns
  constructor: ->
    @item = new paper.Group()

    w = 100
    @cols = [
      new Column(1*100, w, 100)
      new Column(2*100, w, 90)
      new Column(3*100, w, 80)
      new Column(4*100, w, 70)
      new Column(5*100, w, 60)
      new Column(6*100, w, 50)
      new Column(7*100, w, 40)
      new Column(8*100, w, 30)
      ]

    @item.addChild(c.item) for c in @cols

  nextColumns: (x) ->
    # first column is the one the ship is roughly in, or (just
    # started?) will start in.
    # Second column is the one after that, usually
    for i in [0..@cols.length-1]
      if @cols[i].x1 > x + 10
        return [@cols[Math.max(0, i-1)], @cols[i]]
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

$ ->
  canvas = document.getElementById("game")
  setup = paper.setup(canvas)
  view = setup.view

  columns = new Columns()
  ship = new Ship(columns)
  exhaust = new Exhaust(ship.getExhaustSource.bind(ship))

  onMessage = (d) ->
    if d.sliderEvent
      se = d.sliderEvent
      n = parseInt(se.name.replace("slider", ""))
      columns.byNum(n).setFromSlider((127 - se.value) / 127)
  reconnectingWebSocket "ws://localhost:9990/sliders", onMessage

  view.onFrame = (ev) ->
    ship.step(ev.delta)
    columns.step(ev.delta)
    exhaust.step(ev.delta)

  tool = new paper.Tool()
  tool.onMouseDrag = (ev) ->
    col = columns.withinColumn(ev.point.x)
    if col
      col.offsetY(ev.delta.y)
