config =
  showPreviews: false
  introColumn: 140
  exitColumn: 100
  columnCount: 8
  columnWidth: null # computed
  columnLookAhead: 5
  startingGap: 160
  width: 1100
  height: 600
  menuAnimationTime: 1
  enableDoors: true
  enableColumnTextures: true
  exhaust:
    enabled: true
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
  radar:
    enabled: true
    showPoly: false
  jewel:
    count: 2
    collisionRadius: 15
    imgScale: .35
    counterScale: .4
  roller:
    enabled: true

config.columnWidth = (config.width - config.introColumn - config.exitColumn) / config.columnCount

class GameState
  ###
    init

    menu

    menu-away

    play

    play-unlocked

    finish

    -> menu
    
  ###
  constructor: () ->
    @listeners = {} # state : [callbacks]
    @set("init")

  set: (newState) =>
    if newState == @state
      return
    $("#state").text(newState)
    @state = newState
    @changed = +new Date()
    for cb in (@listeners[@state] || [])
      cb()

  elapsedMs: () =>
    # ms spent in this state
    now = +new Date()
    now - @changed

  get: () => @state

  onEnter: (state, cb) =>
    # register listener on transitions to this state
    @listeners[state] = [] if not @listeners[state]
    @listeners[state].push(cb)

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

  state = new GameState()
  state.set("menu")

  sound = new Sound()
  state.onEnter("explode", => sound.play("explode", () => state.set("menu")))
  
  lyr1 = new paper.Layer()
  rollers = if config.roller.enabled then new Rollers(config, state, lyr1) else null

  lyr2 = new paper.Layer()
  
  columns = new Columns(config, state)
  ship = new Ship(config, state, columns)
  if config.enableDoors
    enter = new Enter(config, state)
    exit = new Exit(config, state)
  else
    enter = exit = null
  jewelCounter = new JewelCounter(config, sound, state, ship)
  exhaust = if config.exhaust.enabled then new Exhaust(config, state, ship.getExhaustSource.bind(ship)) else null

  menu = new Menu(config, state, "main")

  animated = [
              rollers,
              columns, exhaust, 
              enter, exit,
              menu, ship, jewelCounter]
  
  setSlidersToColumns = ->
    for col in columns.cols
      msg = {name: "slider"+col.num, value: Math.floor((1 - col.getNormSlider()) * 127)}
      ws.bufferedSendJs(msg)
        
  columns.scramble()
  setSlidersToColumns()

  state.onEnter("menu", () ->
      columns.scramble()
      setSlidersToColumns()
      jewelCounter.reset()
  )    

  gameStartTimeMs = 0
  state.onEnter("play", () -> (gameStartTimeMs = +new Date()))

  view.onFrame = (ev) =>
    for obj in animated
      if obj != null
        obj.step(ev.delta)

    if state.get() in ["play", "playUnlocked"]
      sec = ((+new Date()) - gameStartTimeMs) / 1000
      $("#flight").text(sec+" seconds elapsed")

  tool = new paper.Tool()
  tool.onMouseDown = (ev) ->
    tool.currentCol = columns.withinColumn(ev.point.x)
  tool.onMouseDrag = (ev) ->
    if tool.currentCol
      tool.currentCol.offsetY(ev.delta.y)
