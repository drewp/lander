config =
  showPreviews: true
  debugStart: false
  introColumn: 240
  exitColumn: 150
  columnCount: 8
  columnWidth: null # computed
  columnLookAhead: 5
  startingGap: null # computed
  column:
    startGapShips: 8
    endGapShips: 3
  width: 1920
  height: 1200
  menuAnimationTime: 1
  enableColumnTextures: true
  explodeOnCollision: false
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
    enableShadow: false
    collisionRadius: 50
    imgScale: .18
    speed: 200
    maxTurnPerSec: 200
  radar:
    enabled: true
    showPoly: false
  jewel:
    count: 2
    collisionRadius: 50
    imgScale: .45
    counterScale: .4
    bounceHeight: 10
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

setupPaperJs = (gameCanvasId) ->
  canvas = document.getElementById(gameCanvasId)
  canvas.width = config.width
  canvas.height = config.height
  setup = paper.setup(canvas)
  view = setup.view
  view

setupSliderNetworking = (websocketUrl, onSlider) ->
  onMessage = (d) ->
    if d.sliderEvent
      se = d.sliderEvent
      n = parseInt(se.name.replace("slider", ""))
      onSlider(n, (127 - se.value) / 127)
  ws = reconnectingWebSocket(websocketUrl, onMessage)

$ ->

  stats = new Stats()
  stats.setMode(0)
  $(document.body).append($(stats.domElement).css({position: 'absolute', top: 0, right: 0}))

  view = setupPaperJs("game")

  ws = setupSliderNetworking("ws://localhost:9990/sliders", (n, frac) =>
    columns.byNum(n).setFromSlider(frac)
  )
      
  state = new GameState()
  state.set("menu")

  sound = new Sound()
  state.onEnter("explode", => sound.play("explode", () => state.set("menu")))

  namedLayer = (name) -> (l = new paper.Layer(); l.name = name; l)
  layers = {
    staticBg:       namedLayer('staticBg')       #
    rollers:        namedLayer('rollers')        #
    cargoShadow:    namedLayer('cargoShadow')    #
    cargo:          namedLayer('cargo')          #
    ship:           namedLayer('ship')           # (with exhaust & lasers)
    staticFg:       namedLayer('staticFg')       # (doors, not quite static)
    mechanicLights: namedLayer('mechanicLights') #
    jewels:         namedLayer('jewels')         #
    menu:           namedLayer('menu')           #
  }

  for name, lyr of layers
    button = $("<button>").addClass("vis").text(name)
    toggle = ((button,lyr) -> (() ->
      lyr.visible = not lyr.visible
      button[0].className = if lyr.visible then "vis" else ""
    ))(button, lyr)
    $("#layerSwitches").append(button.click(toggle))

  # Note! We call layer.activate() out here, so you have to create all
  # your "toplevel" (i.e. layer-based) things during the call that
  # builds your layer. In async callbacks you can rasterize things
  # down or whatever, but do it within groups that are correctly
  # associated with the right layer.

  layers.staticBg.activate()
  layers.staticBg.visible = true
  makeStaticBg(config)

  layers.rollers.activate()
  layers.rollers.visible = true
  rollers = if config.roller.enabled then new Rollers(config, state) else null

  columns = new Columns(config, state)
  layers.cargoShadow.activate()
  columns.createCargoShadows()
  layers.cargo.activate()
  columns.createCargo()

  layers.ship.activate()
  ship = new Ship(config, state, columns)
  exhaust = if config.exhaust.enabled then new Exhaust(config, state, ship.getExhaustSource.bind(ship)) else null

  enter = new Enter(config, state)
  exit = new Exit(config, state)
  layers.staticFg.activate()
  enter.makeStatic()
  exit.makeStatic()
  
  layers.mechanicLights.activate()
  enter.makeLights()
  exit.makeLights()

  layers.jewels.activate()
  jewelCounter = new JewelCounter(config, sound, state, ship)

  layers.menu.activate()
  menu = new Menu(config, state, "main")

  animated = [
    rollers
    columns
    ship
    enter
    exit
    menu
    jewelCounter
    ]  
  setSlidersToColumns = ->
    for col in columns.cols
      msg = {name: "slider"+col.sliderNum, value: Math.floor((1 - col.getNormSlider()) * 127)}
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
    stats.begin()
    for obj in animated
      if obj != null
        obj.step(ev.delta)

    if state.get() in ["play", "playUnlocked"]
      sec = ((+new Date()) - gameStartTimeMs) / 1000
      $("#flight").text(sec+" seconds elapsed")
    stats.end()

  tool = new paper.Tool()
  tool.onMouseDown = (ev) ->
    tool.currentCol = columns.withinColumn(ev.point.x)
  tool.onMouseDrag = (ev) ->
    if tool.currentCol
      tool.currentCol.offsetY(ev.delta.y)
  if config.debugStart
    state.set('finish')
    window.columns = columns
    columns.setDebug([377.58, 307.24, 555.66, 280.19, 200, 200, 200, 200])
    
