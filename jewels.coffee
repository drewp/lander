
class window.Jewel
  constructor: (config, sound, target) ->
    [@config, @sound] = [config, sound]
    @pos = new paper.Group([])

    @bounce = new paper.Group([])
    @pos.addChild(@bounce)
    @bouncePhase = Math.random()

    @frames = []
    for i in [1..11]
      shadowChild = new paper.Raster('img/key-jewel-shadow.'+i+'.png')
      shadowChild.scale(@config.jewel.imgScale)
      shadowChild.opacity = .7

      img = new paper.Raster('img/key-jewel.'+i+'.png')
      img.shadowChild = shadowChild
      img.scale(@config.jewel.imgScale)
      shadowChild.visible = false
      img.visible = false
      @bounce.addChild(shadowChild)
      @bounce.addChild(img)
      @frames.push(img)


    @target = target
    @isExiting = false
    @exitingTimer = 0
    @dead = false

    minY = @config.ship.collisionRadius * 3
    maxY = @config.height - minY 
    col = _.random(0, @config.columnCount-1)
    @pos.translate(new paper.Point(@config.introColumn + (col + .5) * @config.columnWidth,
                                    minY + Math.random() * (maxY - minY)))

  remove: () =>
    @pos.remove()

  step: (dt, ship) ->
    nowMs = +new Date()
    whichFrame = Math.floor(nowMs / 100) % @frames.length
    for i in [0...@frames.length]
        c = @frames[i]
        c.visible = i == whichFrame
        c.shadowChild.visible = i == whichFrame

    @bounce.matrix.reset()
    @bounce.translate(0, Math.sin(nowMs / 300 + 6.28 * @bouncePhase) * @config.jewel.bounceHeight)
        
    if @isExiting
      #@exitingTimer += dt
      #t = @exitingTimer / 1
      pos = @pos.matrix.translation
      target = @target.item.matrix.translation
      if pos.subtract(target).length < 25
        @dead = true
        @pos.remove()
        @target.onJewelCollected()
      target = target.subtract(pos).normalize().multiply(25)
      @pos.translate(target) #new paper.Point((target.x * t * t) - pos.x, (target.y * t * t) - pos.y)
    else
      shipPos = ship.item.matrix.translation
      jewelPos = @pos.matrix.translation
      if shipPos.subtract(jewelPos).length <= @config.ship.collisionRadius + @config.jewel.collisionRadius
        @sound.play("coin")
        @isExiting = true


class window.JewelCounter
  constructor: (config, sound, state, ship) ->
    [@config, @sound, @state, @ship] = [config, sound, state, ship]

    @jewels = []
    @item = new paper.Group([])
    @img = new paper.Raster('img/jewel.png')
    @img.scale(@config.jewel.counterScale)
    @item.addChild(@img)
    @text = new paper.PointText(0, 64)
    @text.style = { fontSize: 24, fillColor: "white" }
    @text.getJustification = () -> "center"
    @item.addChild(@text)
    @reset()
    @state.onEnter("menu", @reset)

  reset: =>
    @item.matrix.reset()
    @item.translate(@config.width - 57, 30)
    @collected = 0
    # failure to make these jewels within a group that was created in
    # the constructor is causing the jewels to land in the wrong
    # paperjs layer
    j.remove() for j in @jewels
    @jewels = [ ]
    for i in [0 ... @config.jewel.count]
      @jewels[i] = new Jewel(@config, @sound, this)
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
