
class window.Jewel
  constructor: (config, target) ->
    @config = config
    @item = new paper.Group([])

    @img = new paper.Raster('img/jewel.png')
    @img.scale(@config.jewel.imgScale)
    @item.addChild(@img)

    @target = target
    @isExiting = false
    @exitingTimer = 0
    @dead = false

    minX = @config.introColumn + @config.jewel.collisionRadius
    maxX = @config.width - @config.exitColumn - @config.columnWidth - @config.jewel.collisionRadius
    minY = @config.jewel.collisionRadius
    maxY = @config.height - @config.jewel.collisionRadius
    @item.translate(new paper.Point(minX + Math.random() * (maxX - minX), minY + Math.random() * (maxY - minY)))

  step: (dt, ship) ->
    if @isExiting
      #@exitingTimer += dt
      #t = @exitingTimer / 1
      pos = @item.matrix.translation
      target = @target.item.matrix.translation
      if pos.subtract(target).length < 25
        @dead = true
        @item.remove()
        @target.onJewelCollected()
      target = target.subtract(pos).normalize().multiply(25)
      @item.translate(target) #new paper.Point((target.x * t * t) - pos.x, (target.y * t * t) - pos.y)
    else
      shipPos = ship.item.matrix.translation
      jewelPos = @item.matrix.translation
      if shipPos.subtract(jewelPos).length <= @config.ship.collisionRadius + @config.jewel.collisionRadius
        @isExiting = true


class window.JewelCounter
  constructor: (config, state, ship) ->
    [@config, @state, @ship] = [config, state, ship]

    @item = new paper.Group([])
    @img = new paper.Raster('img/jewel.png')
    @img.scale(@config.jewel.counterScale)
    @item.addChild(@img)
    @text = new paper.PointText(0, 64)
    @text.style = { fontSize: 24, fillColor: "white" }
    @text.getJustification = () -> "center"
    @item.addChild(@text)
    @reset()

  reset: ->
    @item.matrix.reset()
    @item.translate(@config.width - 57, 30)
    @collected = 0
    @jewels = [ ]
    for i in [0 ... @config.jewel.count]
      @jewels[i] = new Jewel(@config, this)
    @pulseTimer = -1
    @flyoutTimer = 0
    @text.content = @collected + " / " + @config.jewel.count

  onJewelCollected: ->
    ++@collected
    @text.content = @collected + " / " + @config.jewel.count
    @pulseTimer = 0

  step: (dt) ->
    if @state.get() == "play-unlocked"
      if @item.matrix.translation.x < @config.width + 100
        @flyoutTimer += dt
        @item.translate(@flyoutTimer * 20, 0)
    else
      for i in [0 ... @jewels.length]
        @jewels[i].step(dt, @ship)
        if @jewels[i].dead
          @jewels.splice(i, 1)
          break
      if @pulseTimer != -1
        @pulseTimer += dt
        @img.matrix.scaleX = @img.matrix.scaleY = @config.jewel.counterScale + (0.2 - Math.abs(0.2 - @pulseTimer))
        if @pulseTimer > 0.4
          @img.matrix.scaleX = @img.matrix.scaleY = @config.jewel.counterScale
          @pulseTimer = -1
          if @collected >= @config.jewel.count
            @state.set("play-unlocked")
