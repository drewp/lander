
class window.Menu
  constructor: (config, name) ->
    @config = config

    top = (@config.height / 2) - 128
    @item = new paper.Group([])
    @title = new paper.PointText(@config.width / 2, top)
    @title.style = { fontSize: 64, fillColor: "white" }
    @title.getJustification = () -> "center"
    @text = new paper.PointText(@config.width / 2, top + 64)
    @text.style = { fontSize: 30, fillColor: "white" }
    @text.getJustification = () -> "center"
    if name == "main"
      @title.content = "Lander"
      @text.content = "Move any slider to start"
    else
      @title.content = "You won!"
      @text.content = "Move any slider for a new game"
    @item.addChild(@title)
    @item.addChild(@text)

    @isExiting = false
    @exitingTimer = 0

  startExit: ->
    @isExiting = true

  step: (dt) ->
    if @isExiting
      @exitingTimer += dt
      t = @exitingTimer / @config.menuAnimationTime
      target = -@config.width * t * t
      pos = @item.matrix.translation
      @item.translate(new paper.Point(target - pos.x, 0))

  doneExiting: -> @exitingTimer >= @config.menuAnimationTime
