config =
  showPreviews: false
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

window.clamp = (x, lo, hi) -> Math.min(hi, Math.max(lo, x))

window.tween = (a, b, t) -> (a + (b - a) * t)

$ ->
  canvas = document.getElementById("game")
  canvas.width = config.width
  canvas.height = config.height
  setup = paper.setup(canvas)
  view = setup.view

  columns = new Columns(config)
  ship = new Ship(config, columns)
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
