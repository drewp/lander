
class window.Menu
  constructor: (config, state) ->
    [@config, @state] = [config, state]

    top = (@config.height / 2) - 128
    @item = new paper.Group([])
    @title = new paper.PointText(@config.width / 2, top)
    @title.style = { fontSize: 64, fillColor: "white" }
    @title.getJustification = () -> "center"
    @text = new paper.PointText(@config.width / 2, top + 64)
    @text.style = { fontSize: 30, fillColor: "white" }
    @text.getJustification = () -> "center"
    @item.addChild(@title)
    @item.addChild(@text)

  step: (dt) ->
    switch @state.get()
      when "menu"
        @item.visible = true
        @title.content = "Lander"
        @text.content = "Move any slider to start"
        
        @item.setMatrix(new paper.Matrix().translate([0, 0]))
      when "menu-away"
        @item.visible = true
        @title.content = "Lander"
        @text.content = "Move any slider to start"

        sec = @state.elapsedMs() / 1000
        
        @item.setMatrix(new paper.Matrix().translate([
          @config.width * 1.3 * (sec / @config.menuAnimationTime),
          0]))
        if sec > @config.menuAnimationTime
          @state.set("play")
      when "finish"
        @item.visible = true
        @title.content = "You won!"
        @text.content = "Move any slider for a new game"
        @item.setMatrix(new paper.Matrix().translate([0, 0]))
      else
        @item.visible = false        
      
