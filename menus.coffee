
class window.Menu
  constructor: (config, state) ->
    [@config, @state] = [config, state]

    @mask = new paper.Path.Rectangle(0, 0, @config.width, @config.height)
    @mask.style = {fillColor: 'black'}
    @mask.opacity = 0

    @item = new paper.Group()
    @overlay = {
      title: new paper.Raster("img/overlay/title.png")
      lose: new paper.Raster("img/overlay/lose.png")
      win: new paper.Raster("img/overlay/win.png")
    }
    @item.addChild(x) for _, x of @overlay
    @item.translate(@config.width / 2, @config.height / 2)
   
    @item = new paper.Group([@item])
    
  select: (name, dt) =>
    if name?
      @item.visible = true
      o.visible = (name == n) for n, o of @overlay
      @maskFade(1, dt)
    else
      @item.visible = false
      @maskFade(-1, dt)

  maskFade: (direction, dt) =>
    @mask.opacity = clamp(@mask.opacity + direction * 2 * dt, 0, .5)

  step: (dt) ->
    switch @state.get()
      when "menu"
        @item.matrix.reset()
        @select("title", dt)

      when "menu-away"
        sec = @state.elapsedMs() / 1000
        @item.setMatrix(new paper.Matrix().translate([
          @config.width * 1.3 * (sec / @config.menuAnimationTime),
          0]))
        @maskFade(-1, dt)
        if sec > @config.menuAnimationTime
          @state.set("play")
      when "finish"
        @item.matrix.reset()
        @select("win", dt)
      else
        @select(null, dt)
      
