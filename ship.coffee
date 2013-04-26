
class window.Ship
  constructor: (config, columns) ->
    [@config, @columns] = [config, columns]
    @item = new paper.Group([])

    @img = new paper.Raster('img/ship1.png')
    @img.scale(@config.ship.imgScale)
    @item.addChild(@img)
    @resetPosition()

    @heading = new paper.Point(@config.ship.steer.maxSpeed, 0)
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
    #@gapTarget.x = 40
    #@gapTarget.y = 0
    @flightStartMs = +new Date();

  flightElapsedMs: -> +new Date() - @flightStartMs

  finished: -> @item.matrix.translateX > @config.width

  getExhaustSource: ->
    return {pt: @item.matrix.translation, dir: @heading.rotate(180)}

  rebuildPath: (colNum) ->
    @path = [ ]
    while true
      col = @columns.byNum(colNum)
      if @forward
        colGap = col.getGap()
        @path[@path.length] = colGap.bottomLeft
        @path[@path.length] = colGap.bottomRight
        if colNum == 8
          break
        next = @columns.byNum(colNum + 1)
        nextGap = next.getGap()
        topInt = paper.Point.max(colGap.topRight, nextGap.topLeft)
        botInt = paper.Point.min(colGap.bottomRight, nextGap.bottomLeft)
        if topInt.y >= botInt.y - @config.ship.collisionRadius * 2
          break
        ++colNum
      else
        colGap = col.getGap()
        @path[@path.length] = colGap.topRight
        @path[@path.length] = colGap.topLeft
        if colNum == 1
          break
        next = @columns.byNum(colNum - 1)
        nextGap = next.getGap()
        topInt = paper.Point.max(colGap.topLeft, nextGap.topRight)
        botInt = paper.Point.min(colGap.bottomLeft, nextGap.bottomRight)
        if topInt.y >= botInt.y - @config.ship.collisionRadius * 2
          break
        --colNum

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
    #dist = @config.ship.wallDistance

    colNum = @columns.getColumnNum(pos.x)
    if colNum == -1
      @rebuildPath(1)
      @pathIndex = 0
      @flyToward = @path[@pathIndex]
      return
    if colNum == 8
      col = @columns.byNum(8)
      @flyToward.x = col.x1 + col.w + 20
      @flyToward.y = col.y + (col.gapHeight / 2)
      return

    @rebuildPath(colNum)
    if @pathIndex == 2 && @path.length > 2
      @pathIndex = 2
    else
      @pathIndex = @pathIndex % 2
    @flyToward = @path[@pathIndex]

    if (pos.subtract(@flyToward).length > 15)
      return

    if @pathIndex == @path.length - 1
      @forward = !@forward
      @rebuildPath(colNum)
      @pathIndex = 0
    else
      ++@pathIndex
    @flyToward = @path[@pathIndex]

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
  
    #frameTurn = clamp(requiredTurn,
    #                  -@config.ship.maxSteerPerSec * dt,
    #                  @config.ship.maxSteerPerSec * dt)
    frameTurn = requiredTurn
    @heading = @heading.rotate(frameTurn, [0, 0])
    @setImageAngle(@heading.angle)

    @updatePreviewLine(@idealPreview, pos, idealAngle) if @idealPreview?
    @updatePreviewLine(@currentPreview, pos, @img.matrix.rotation) if @currentPreview?
  
  step: (dt) ->
    @updateFlyToward()
    @updateHeading(dt)

    @item.translate(@heading.multiply(dt))
      
  position: -> @item.matrix.translation
