# other simple objects in the scene

blink = (item, periodMs, onTimeMs, fade) ->
  now = +(new Date())
  item.opacity = fade * item.opacity + (1 - fade) * ((now % periodMs) > onTimeMs)

class window.Enter
  constructor: (config, state) ->
    [@config, @state] = [config, state]

  makeStatic: () =>
    @align(new paper.Raster("img/enter.png"))
    
  makeLights: () =>
    @lights = new paper.Raster("img/enter-lights.png")
    @align(@lights)
    
  align: (img) =>
    img.onLoad = =>
      img.translate(@config.introColumn / 2 - 40, @config.height / 2)
      img.scale(@config.height / img.height)  

  step: (dt) =>
    if (@state.get() in ["menu", "menu-away"] ||
        (@state.get() == "play" && @state.elapsedMs() < 2000))
      @lights.visible = true
      blink(@lights, 2000, 1000, .3)
    else
      @lights.visible = false

class window.Exit
  constructor: (config, state) ->
    [@config, @state] = [config, state]

    @exitBox = new paper.Rectangle(new paper.Point(@config.width - @config.exitColumn, 0),
                                  new paper.Size(@config.exitColumn, @config.height))
    

  makeStatic: () =>
    @bottom = new paper.Raster("img/exitdoor-bottom.png")
    @top = new paper.Raster("img/exitdoor-top.png")
    ex = new paper.Raster("img/exit.png")
    @align(ex, [ex, @bottom, @top])

  makeLights: () =>
    @align(@lights = new paper.Raster("img/exit-lights.png"))

  align: (img, objs) =>
    img.onLoad = () =>
      objs = objs || [img]
      for obj in objs
        obj.translate(new paper.Point(45, 0))
        obj.scale(@config.height / img.height)
        obj.translate(@exitBox.leftCenter)

  step: (dt) =>
    if @state.get() in ["play", "play-unlocked", "finish"]
      @lights.visible = true
      blink(@lights, 800, 400, .3)
    else
      @lights.visible = false

    if @state.get() == "play-unlocked"
      @bottom.matrix.translateY = clamp(@state.elapsedMs() / 10, 0, 60)
      @top.matrix.translateY = -@bottom.matrix.translateY
    else
      @top.matrix.translateY = 0
      @bottom.matrix.translateY = 0
    