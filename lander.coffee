config =
  showPreviews: true
  autoStart: true
  introColumn: 140
  columnCount: 8
  columnWidth: null # computed
  columnLookAhead: 5
  startingGap: 160
  width: 1100
  height: 600
  menuAnimationTime: 1
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
    speed: 120
    maxTurnPerSec: 360

config.columnWidth = (config.width - config.introColumn) / config.columnCount

window.clamp = (x, lo, hi) -> Math.min(hi, Math.max(lo, x))

window.tween = (a, b, t) -> (a + (b - a) * t)

$ ->
  canvas = document.getElementById("game")
  canvas.width = config.width
  canvas.height = config.height
  setup = paper.setup(canvas)
  view = setup.view

  onMessage = (d) ->
    if d.sliderEvent
      se = d.sliderEvent
      n = parseInt(se.name.replace("slider", ""))
      columns.byNum(n).setFromSlider((127 - se.value) / 127)
  ws = reconnectingWebSocket("ws://localhost:9990/sliders", onMessage)

  columns = new Columns(config)
  ship = new Ship(config, columns)
  exhaust = new Exhaust(config, ship.getExhaustSource.bind(ship))

  menu = if config.autoStart then null else new Menu(config, "main")
  
  setSlidersToColumns = ->
    for col in columns.cols
      msg = {name: "slider"+col.num, value: Math.floor((1 - col.getNormSlider()) * 127)}
      ws.bufferedSendJs(msg)
        
  columns.scramble()
  setSlidersToColumns()

  view.onFrame = (ev) ->
    columns.step(ev.delta)
    exhaust.step(ev.delta)

    if menu != null
      menu.step(ev.delta)
      if !menu.isExiting && columns.checkMovement()
        menu.startExit()
      else if menu.doneExiting()
        menu = null
    else
      ship.step(ev.delta)
      if ship.finished()
        columns.scramble()
        setSlidersToColumns()
        ship.resetPosition()
        menu = new Menu(config, "victory")

    sec = ship.flightElapsedMs() / 1000
    $("#flight").text(sec+" seconds elapsed")

  tool = new paper.Tool()
  tool.onMouseDown = (ev) ->
    tool.currentCol = columns.withinColumn(ev.point.x)
  tool.onMouseDrag = (ev) ->
    if tool.currentCol
      tool.currentCol.offsetY(ev.delta.y)
