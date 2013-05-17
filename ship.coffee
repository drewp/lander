
class window.Ship
  constructor: (config, state, columns) ->
    [@config, @state, @columns] = [config, state, columns]
    @item = new paper.Group([])

    @shadow = new paper.Group()
    @item.addChild(@shadow)

    @img = new paper.Raster('img/ship/ship.012.png')
    @item.addChild(@img)

    @img.scale(@config.ship.imgScale)

    if @config.ship.enableShadow
      @img.onLoad = =>
        copy = @img.rasterize()
        console.log("shadowing", copy.width, +new Date())
        for y in [0...copy.height]
          for x in [0...copy.width]
            c = copy.getPixel(x, y)
            c.brightness = 0
            copy.setPixel(x, y, c)
        @shadow.addChild(copy)
        console.log("done", +new Date())
      @shadow.translate(10, 10)
    
    @resetPosition()

    @heading = new paper.Point(@config.ship.speed, 0)
    @flyToward = new paper.Point(40, @config.height / 2)
    @path = [ ]
    @pathIndex = 0
    @pathObj = new paper.Path([])
    @pathObj.visible = @config.showPreviews
    @forward = true
   
    if @config.showPreviews
      @collisionCircle = new paper.Path.Circle([0,0], @config.ship.collisionRadius)
      @collisionCircle.style = {} #{strokeColor: 'white'}
      @item.addChild(@collisionCircle)

      if false
        @flyTowardPreview = new paper.Path.Circle(@flyToward, 9)
        @flyTowardPreview.style = {strokeColor: 'white'}

        @idealPreview = new paper.Path.Line([0,0], [0,0])
        @idealPreview.style = {strokeColor: 'green'}

        @currentPreview = new paper.Path.Line([0,0], [0,0])
        @currentPreview.style = {strokeColor: 'blue'}

    @radar = if @config.radar.enabled then new Radar(@config) else null
    @state.onEnter("menu", @resetPosition)

  resetPosition: =>
    @item.setMatrix(new paper.Matrix().translate(50, @config.height / 2))
    @path = [ ]
    @flightStartMs = +new Date();

  flightElapsedMs: -> +new Date() - @flightStartMs

  finished: -> @item.matrix.translateX > (@config.introColumn + @config.columnCount * @config.columnWidth)

  getExhaustSource: ->
    return {pt: @item.matrix.translation, dir: @heading.rotate(180)}

  # Used by rebuildPath. Moves a point away from the column. The direction that
  # the point is moved depends on which direction the path is going.
  getOffsetPoint: (p, moveForward) ->
    dist = @config.ship.collisionRadius * .6
    point = new paper.Point(p)
    if @forward
      point.y -= dist
      if moveForward == 1
        point.x += dist
      else if moveForward == -1
        point.x -= dist
    else
      point.y += dist
      if moveForward == 1
        point.x -= dist
      else if moveForward == -1
        point.x += dist
    return point

  # Builds a path for the ship to get from the current column (colNum) to the
  # next column. The path has a maximum of 3 points. 
  rebuildPath: (colNum) ->
    @path = [ ]
    colGap = @columns.byNum(colNum).getGap()
    if @forward
      if colNum > 1
        prevGap = @columns.byNum(colNum - 1).getGap()
        if colGap.bottomLeft.y > prevGap.bottomRight.y > colGap.topLeft.y + @config.ship.collisionRadius * 1.2
          @path[@path.length] = @getOffsetPoint(prevGap.bottomRight, 1)
      @path[@path.length] = @getOffsetPoint(colGap.bottomLeft.add(colGap.bottomRight).divide(2), 0)
      if colNum < 8
        nextGap = @columns.byNum(colNum + 1).getGap()
        if colGap.bottomRight.y > nextGap.bottomLeft.y > colGap.topRight.y + @config.ship.collisionRadius * 1.2
          @path[@path.length] = @getOffsetPoint(nextGap.bottomLeft, -1)
    else
      if colNum < 8
        prevGap = @columns.byNum(colNum + 1).getGap()
        if colGap.topRight.y < prevGap.topLeft.y < colGap.bottomRight.y - @config.ship.collisionRadius * 1.2
          @path[@path.length] = @getOffsetPoint(prevGap.topLeft, 1)
      @path[@path.length] = @getOffsetPoint(colGap.topRight.add(colGap.topLeft).divide(2), 0)
      if colNum > 1
        nextGap = @columns.byNum(colNum - 1).getGap()
        if colGap.topLeft.y < nextGap.topRight.y < colGap.bottomLeft.y - @config.ship.collisionRadius * 1.2
          @path[@path.length] = @getOffsetPoint(nextGap.topRight, -1)

  # Determines the point the ship should be flying towards. The ship will fly
  # along the path until it reaches the end. At the end, if the ship can get
  # to the next column, then a new path is generated for that column.
  # Otherwise, the ship reverses direction.
  updateFlyToward: ->
    diam = @config.ship.collisionRadius * 2
    @flyTowardPreview.position = @flyToward if @flyTowardPreview?
    if @state.get() == "finish"
      @flyToward.x = @config.width + 100
      @flyToward.y = @config.height / 2
      return

    pos = @item.matrix.translation
    colNum = if @path.length > 0 then @columns.getColumnNum(@path[0].x) else -1
    if colNum == -1
      col = @columns.byNum(1)
      colGap = col.getGap()
      if colGap.topLeft.y < 0 || colGap.bottomLeft.y > @config.height
        @flyToward.x = @config.introColumn / 2
        @flyToward.y = @config.height / 2
      else if (pos.subtract(@flyToward).length > 1.5 * diam)
        @flyToward.x = col.x1
        @flyToward.y = col.y + (col.gapHeight / 2)
      else
        @rebuildPath(1)
        @pathIndex = 0
        @flyToward = @path[0]
      return
    if colNum == 8 && @state.get() == "play-unlocked"
      col = @columns.byNum(8)
      @flyToward.x = col.x1 + col.w + 1.5 * diam
      @flyToward.y = col.y + (col.gapHeight / 2)
      return

    @rebuildPath(colNum)

    #@pathObj.removeSegments()
    #@path.map((s) => @pathObj.add(s))
    #@pathObj.style = {strokeWidth: 3, strokeColor: 'red'}
    
    @pathIndex = if @pathIndex >= @path.length then @path.length - 1 else @pathIndex
    @flyToward = @path[@pathIndex]
    if pos.subtract(@flyToward).length > 1.5 * diam
      return

    if @pathIndex == @path.length - 1
      colGap = null
      nextGap = null
      isOOB = false
      if @forward && colNum < 8
        colGap = @columns.byNum(colNum).getGap()
        nextGap = @columns.byNum(colNum + 1).getGap()
        isOOB = nextGap.topLeft.y < 0 || nextGap.bottomLeft.y > @config.height
      else if !@forward && colNum > 1
        colGap = @columns.byNum(colNum - 1).getGap()
        nextGap = @columns.byNum(colNum).getGap()
        isOOB = colGap.topLeft.y < 0 || colGap.bottomLeft.y > @config.height
      if colGap != null
        topInt = paper.Point.max(colGap.topRight, nextGap.topLeft)
        botInt = paper.Point.min(colGap.bottomRight, nextGap.bottomLeft)
        if topInt.y >= botInt.y - diam || isOOB
          @forward = !@forward
        else
          colNum = if @forward then colNum + 1 else colNum - 1
      else
        @forward = !@forward
      @rebuildPath(colNum)
      @pathIndex = 0
    else
      ++@pathIndex
  
  updatePreviewLine: (path, pt, angle) ->
    path.firstSegment.point = pt
    path.lastSegment.point = pt.add(new paper.Point([100, 0]).rotate(angle))

  setImageAngle: (angle) ->
    @item.rotate(angle - @item.matrix.rotation)

  updatePermittedArea: () =>
    

  # Rotate the ship smoothly
  updateHeading: (dt) ->
    pos = @item.matrix.translation
    currentAngle = @heading.angle
    steer = @config.ship.steer

    idealAngle = @flyToward.subtract(pos).angle
    
    $("#ship").text("angle "+Math.round(currentAngle)+
                    " ideal "+Math.round(idealAngle))

    requiredTurn = idealAngle - currentAngle
    if Math.abs(requiredTurn + 360) < Math.abs(requiredTurn)
      requiredTurn += 360
    else if Math.abs(requiredTurn - 360) < Math.abs(requiredTurn)
      requiredTurn -= 360
  
    frameTurn = clamp(requiredTurn,
                      -@config.ship.maxTurnPerSec * dt,
                      @config.ship.maxTurnPerSec * dt)
    @heading = @heading.rotate(frameTurn, [0, 0])
    @setImageAngle(@heading.angle)

    @updatePreviewLine(@idealPreview, pos, idealAngle) if @idealPreview?
    @updatePreviewLine(@currentPreview, pos, @img.matrix.rotation) if @currentPreview?

  collision: () =>
    pos = @item.matrix.translation
    colNum = @columns.getColumnNum(pos.x)
    if colNum > 0
      colGap = @columns.byNum(colNum).getGap()
      collisionRadius = @config.ship.collisionRadius
      if pos.y - collisionRadius < colGap.topRight.y
        @colliding(colGap.topRight.y - (pos.y - collisionRadius))
      else if pos.y + collisionRadius > colGap.bottomRight.y
        @colliding(colGap.bottomRight.y - (pos.y + collisionRadius))

  colliding: (ty) =>
    if @config.explodeOnCollision
      if @state.get() != "explode"
        console.log("top collision")
        @state.set("explode")
    else
      @item.translate(new paper.Point(0, ty))
  
  step: (dt) =>
    @updatePermittedArea()
    @updateFlyToward()
    @updateHeading(dt)

    switch @state.get()
      when "play", "play-unlocked", "finish"
        @item.translate(@heading.multiply(dt))
        if @finished()
          @state.set("finish")

    @collision()

    if @radar != null
      @radar.draw(@radar.computePolygon(@item.matrix.translation, @heading.angle, 30,
                  @columns.allWalls()))
          
  position: -> @item.matrix.translation
