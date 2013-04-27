
class window.Ship
  constructor: (config, columns) ->
    [@config, @columns] = [config, columns]
    @item = new paper.Group([])

    @img = new paper.Raster('img/ship1.png')
    @img.scale(@config.ship.imgScale)
    @item.addChild(@img)
    @resetPosition()

    @heading = new paper.Point(@config.ship.speed, 0)
    @flyToward = new paper.Point(40, @config.height / 2)
    @path = [ ]
    @pathIndex = 0
    @forward = true
  
    if @config.showPreviews
      @collisionCircle = new paper.Path.Circle([0,0], @config.ship.collisionRadius)
      @collisionCircle.style = {strokeColor: 'white'}
      @item.addChild(@collisionCircle)
  
      @flyTowardPreview = new paper.Path.Circle(@flyToward, 9)
      @flyTowardPreview.style = {strokeColor: 'white'}

      @idealPreview = new paper.Path.Line([0,0], [0,0])
      @idealPreview.style = {strokeColor: 'green'}

      @currentPreview = new paper.Path.Line([0,0], [0,0])
      @currentPreview.style = {strokeColor: 'blue'}

  resetPosition: ->
    @item.setMatrix(new paper.Matrix().translate(0, @config.height / 2))
    @path = [ ]
    @flightStartMs = +new Date();

  flightElapsedMs: -> +new Date() - @flightStartMs

  finished: -> @item.matrix.translateX > @config.width

  getExhaustSource: ->
    return {pt: @item.matrix.translation, dir: @heading.rotate(180)}

  getOffsetPoint: (p, moveForward) ->
    dist = 24
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

  rebuildPath: (colNum) ->
    @path = [ ]
    colGap = @columns.byNum(colNum).getGap()
    if @forward
      if colNum > 1
        prevGap = @columns.byNum(colNum - 1).getGap()
        if prevGap.bottomRight.y < colGap.bottomLeft.y && prevGap.bottomRight.y > colGap.topLeft.y + @config.ship.collisionRadius * 2
          @path[@path.length] = @getOffsetPoint(prevGap.bottomRight, 1)
      @path[@path.length] = @getOffsetPoint(colGap.bottomLeft.add(colGap.bottomRight).divide(2), 0)
      if colNum < 8
        nextGap = @columns.byNum(colNum + 1).getGap()
        if nextGap.bottomLeft.y < colGap.bottomRight.y && nextGap.bottomLeft.y > colGap.topRight.y + @config.ship.collisionRadius * 2
          @path[@path.length] = @getOffsetPoint(nextGap.bottomLeft, -1)
    else
      if colNum < 8
        prevGap = @columns.byNum(colNum + 1).getGap()
        if prevGap.topLeft.y > colGap.topRight.y && prevGap.topLeft.y < colGap.bottomRight.y - @config.ship.collisionRadius * 2
          @path[@path.length] = @getOffsetPoint(prevGap.topLeft, 1)
      @path[@path.length] = @getOffsetPoint(colGap.topRight.add(colGap.topLeft).divide(2), 0)
      if colNum > 1
        nextGap = @columns.byNum(colNum - 1).getGap()
        if nextGap.topRight.y > colGap.topLeft.y && nextGap.topRight.y < colGap.bottomLeft.y - @config.ship.collisionRadius * 2
          @path[@path.length] = @getOffsetPoint(nextGap.topRight, -1)

  updateFlyToward: ->
#        |              ||               |
#        |              ||               |
#        +--------------+|               |
#                        +---------------+
#             gap1            gap2
#        +--------------+
#        |              |+---------------+
#                        |               |

    pos = @item.matrix.translation
    colNum = if @path.length > 0 then @columns.getColumnNum(@path[0].x) else -1
    if colNum == -1
      @rebuildPath(1)
      @pathIndex = 0
      @flyToward = @path[0]
      return
    if colNum == 8
      col = @columns.byNum(8)
      @flyToward.x = col.x1 + col.w + 20
      @flyToward.y = col.y + (col.gapHeight / 2)
      return

    @rebuildPath(colNum)
    @pathIndex = if @pathIndex >= @path.length then @path.length - 1 else @pathIndex
    @flyToward = @path[@pathIndex]
    if (pos.subtract(@flyToward).length > 15)
      return

    if @pathIndex == @path.length - 1
      colGap = null
      nextGap = null
      if @forward && colNum < 8
        colGap = @columns.byNum(colNum).getGap()
        nextGap = @columns.byNum(colNum + 1).getGap()
      else if !@forward && colNum > 1
        colGap = @columns.byNum(colNum - 1).getGap()
        nextGap = @columns.byNum(colNum).getGap()
      if colGap != null
        topInt = paper.Point.max(colGap.topRight, nextGap.topLeft)
        botInt = paper.Point.min(colGap.bottomRight, nextGap.bottomLeft)
        if topInt.y >= botInt.y - @config.ship.collisionRadius * 2
          @forward = !@forward
        else
          colNum = if @forward then colNum + 1 else colNum - 1
      else
        @forward = !@forward
      @rebuildPath(colNum)
      @pathIndex = 0
    else
      ++@pathIndex

    #@updateGapPreviews(gap1, gap2) if @config.showPreviews

    @flyTowardPreview.position = @flyToward if @flyTowardPreview?

  updateGapPreviews: (gap1, gap2) ->
    @gap1Preview.remove() if @gap1Preview?
    @gap2Preview.remove() if @gap2Preview?
    R = paper.Path.Rectangle
    (@gap1Preview = new R(gap1.expand(-2))).style = {strokeColor: '#ff0000'}
    (@gap2Preview = new R(gap2)).style = {strokeColor: '#ffff00'}
  
  updatePreviewLine: (path, pt, angle) ->
    path.firstSegment.point = pt
    path.lastSegment.point = pt.add(new paper.Point([100, 0]).rotate(angle))

  setImageAngle: (angle) ->
    @img.rotate(angle - @img.matrix.rotation)

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
    #frameTurn = requiredTurn
    @heading = @heading.rotate(frameTurn, [0, 0])
    @setImageAngle(@heading.angle)

    @updatePreviewLine(@idealPreview, pos, idealAngle) if @idealPreview?
    @updatePreviewLine(@currentPreview, pos, @img.matrix.rotation) if @currentPreview?
  
  step: (dt) ->
    @updateFlyToward()
    @updateHeading(dt)

    @item.translate(@heading.multiply(dt))
    pos = @item.matrix.translation
    colNum = @columns.getColumnNum(pos.x)
    if colNum > 0
      colGap = @columns.byNum(colNum).getGap()
      if pos.y < colGap.topRight.y
        @item.translate(new paper.Point(0, colGap.topRight.y - pos.y))
      else if pos.y > colGap.bottomRight.y
        @item.translate(new paper.Point(0, colGap.bottomRight.y - pos.y))
      
  position: -> @item.matrix.translation
