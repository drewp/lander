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

config =
  showPreviews: true
  introColumn: 140
  columnCount: 8
  columnWidth: null # computed
  minVisibleRock: 10
  columnLookAhead: 10
  startingGap: 160
  width: 1100
  height: 600
  exhaust:
    opacity: .2
    bornPerSec: 20
    drift:
      min: new paper.Point([20, -4])
      max: new paper.Point([25, 4])
    opacityScalePerSec: .80
    maxAlive: 200
  ship:
    collisionRadius: 15
    imgScale: .3
    steer:
      maxDegPerSec: 30
      maxAbsAngle: 80 
      slowDownAngle: 50 # beyond this, hit the brakes
      minSpeed: .1 # px/sec
      maxSpeed: 90
      brakes: .000007 # rate change per sec
      accel: 70

config.columnWidth = (config.width - config.introColumn) / config.columnCount

class Ship
  constructor: (columns) ->
    @columns = columns
    @item = new paper.Group([])

    @img = new paper.Raster('img/ship1.png')
    @img.scale(config.ship.imgScale)
    @item.addChild(@img)
    @item.translate(new paper.Point(0, paper.view.size.height / 2))

    @heading = new paper.Point(90, 0)
    @accel = new paper.Point(0, 0)

    @flyToward = new paper.Point(0, 0)
  
    if config.showPreviews
      @collisionCircle = new paper.Path.Circle([0,0], config.ship.collisionRadius)
      @collisionCircle.style = {strokeColor: 'white'}
      @item.addChild(@collisionCircle)
  
      @flyTowardPreview = new paper.Path.Circle(@flyToward, 9)
      @flyTowardPreview.style = {strokeColor: 'white'}

      @idealPreview = new paper.Path.Line([0,0], [0,0])
      @idealPreview.style = {strokeColor: 'green'}

      @currentPreview = new paper.Path.Line([0,0], [0,0])
      @currentPreview.style = {strokeColor: 'blue'}

  getExhaustSource: ->
    {pt: @item.matrix.translation, dir: @heading.rotate(180)}
  
  updateFlyToward: ->
#        |              ||               |
#        |              ||               |
#        +--------------+|               |
#                        +---------------+
#             gap1            gap2
#        +--------------+
#        |              |+---------------+
#                        |               |

    pos = @item.matrix.translation
    [c1, c2] = @columns.nextColumns(pos.x)
    if c1 == null
      @flyToward = pos.add([20, 0])
    else
      [gap1, gap2] = [c1.getGap(), c2.getGap()]

      @updateGapPreviews(gap1, gap2) if config.showPreviews

      topInt = paper.Point.max(gap1.topRight, gap2.topLeft)
      botInt = paper.Point.min(gap1.bottomRight, gap2.bottomLeft)

      if topInt.y >= botInt.y - config.ship.collisionRadius * 2
        # stuck; just hover
        @flyToward = gap1.center
      else
        @flyToward = topInt.add(botInt).divide(2)

    @flyTowardPreview.position = @flyToward if @flyTowardPreview?

  updateGapPreviews: (gap1, gap2) ->
    @gap1Preview.remove() if @gap1Preview?
    @gap2Preview.remove() if @gap2Preview?
    R = paper.Path.Rectangle
    (@gap1Preview = new R(gap1.expand(-2))).style = {strokeColor: '#ff0000'}
    (@gap2Preview = new R(gap2)).style = {strokeColor: '#ffff00'}
  
  updatePreviewLine: (path, pt, angle) ->
    path.firstSegment.point = pt
    path.lastSegment.point = pt.add(new paper.Point([100, 0]).rotate(angle))

  setImageAngle: (angle) ->
    @img.rotate(angle - @img.matrix.rotation)

  updateHeading: (dt) ->
    pos = @item.matrix.translation
    steer = config.ship.steer

    idealAngle = @flyToward.subtract(pos).angle

    $("#ship").text("angle "+Math.round(@heading.angle)+
                    " ideal "+Math.round(idealAngle))

    clampedIdealAngle = clamp(idealAngle, -steer.maxAbsAngle, steer.maxAbsAngle)

    requiredTurn = clampedIdealAngle - @heading.angle
    if Math.abs(requiredTurn) > steer.slowDownAngle
      if @heading.length > steer.minSpeed
        @heading = @heading.multiply(Math.pow(steer.brakes, dt))
    else
      if @heading.length < steer.maxSpeed
        @heading = @heading.multiply(Math.pow(steer.accel, dt))
  
    frameTurn = clamp(requiredTurn,
                      -steer.maxDegPerSec * dt,
                      steer.maxDegPerSec * dt)
    @heading = @heading.rotate(frameTurn, [0, 0])
    @setImageAngle(@heading.angle)

    @updatePreviewLine(@idealPreview, pos, clampedIdealAngle) if @idealPreview?
    @updatePreviewLine(@currentPreview, pos, @img.matrix.rotation) if @currentPreview?
  
  step: (dt) ->
    @updateFlyToward()
    @updateHeading(dt)

    @item.translate(@heading.multiply(dt))
    if @item.matrix.translateX > config.width
      @item.position = [0, config.height / 2]
      

  position: -> @item.matrix.translation

clamp = (x, lo, hi) -> Math.min(hi, Math.max(lo, x))

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
  constructor: (i, x1, w, gap) ->
    # i is 1-based index
    [@x1, @w] = [x1, w]
    @item = new paper.Group()
    # item's origin is at the * in the diagram

    @y = 200 + Math.random() * 200
    @gapHeight = gap

    @sliderOffset = Math.random() * .4 - .2

    @rockAreas = [
      new paper.Rectangle(new paper.Point([0,0]), new paper.Size(@w, -1000)),
      new paper.Rectangle(new paper.Point([0,@gapHeight]), new paper.Size(@w, 1000))]

    @addPreviews() if config.showPreviews

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
    @top.addChild(r.scale([config.columnWidth / rw, 1]).translate([@w / 2, -rh / 2]))
    r = new paper.Raster(img)
    @bottom.addChild(r.scale([config.columnWidth / rw, 1]).translate([@w / 2, @gapHeight + rh / 2]))

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
    @y = clamp(@y, config.minVisibleRock, config.height - config.minVisibleRock - @gapHeight)
    @item.matrix.translateY = @y

tween = (a, b, t) -> (a + (b - a) * t)

class Columns
  constructor: ->
    @item = new paper.Group()

    w = config.columnWidth
    gh1 = config.startingGap
    gh2 = config.ship.collisionRadius * 3
    @cols = [
      new Column(1, config.introColumn + 0 * w, w, tween(gh1, gh2, 0.0))
      new Column(2, config.introColumn + 1 * w, w, tween(gh1, gh2, 0.1))
      new Column(3, config.introColumn + 2 * w, w, tween(gh1, gh2, 0.2))
      new Column(4, config.introColumn + 3 * w, w, tween(gh1, gh2, 0.4))
      new Column(5, config.introColumn + 4 * w, w, tween(gh1, gh2, 0.6))
      new Column(6, config.introColumn + 5 * w, w, tween(gh1, gh2, 0.7))
      new Column(7, config.introColumn + 6 * w, w, tween(gh1, gh2, 0.8))
      new Column(8, config.introColumn + 7 * w, w, tween(gh1, gh2, 1.0))
      ]
    @introColumn =
      getGap: -> new paper.Rectangle([0, 0], [config.introColumn, config.height])


    @item.addChild(c.item) for c in @cols

  nextColumns: (x) ->
    # [null, null] if we're in or beyond the last column. Otherwise
    # [this,next] Column objects.
    for i in [0 ... @cols.length]
      if @cols[i].x1 > x + config.columnLookAhead
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

$ ->
  canvas = document.getElementById("game")
  canvas.width = config.width
  canvas.height = config.height
  setup = paper.setup(canvas)
  view = setup.view

  columns = new Columns()
  ship = new Ship(columns)
  exhaust = new Exhaust(config, ship.getExhaustSource.bind(ship))

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
  tool.onMouseDown = (ev) ->
    tool.currentCol = columns.withinColumn(ev.point.x)
  tool.onMouseDrag = (ev) ->
    if tool.currentCol
      tool.currentCol.offsetY(ev.delta.y)
