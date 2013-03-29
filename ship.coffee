
class window.Ship
  constructor: (config, columns) ->
    [@config, @columns] = [config, columns]
    @item = new paper.Group([])

    @img = new paper.Raster('img/ship1.png')
    @img.scale(@config.ship.imgScale)
    @item.addChild(@img)
    @resetPosition()

    @heading = new paper.Point(.1, 0)
    @accel = new paper.Point(0, 0)

    @flyToward = new paper.Point(0, 0)
  
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
    @flightStartMs = +new Date();

  flightElapsedMs: -> +new Date() - @flightStartMs

  finished: -> @item.matrix.translateX > @config.width

  getExhaustSource: ->
    {pt: @item.matrix.translation, dir: @heading.rotate(180)}
  
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
    [c1, c2] = @columns.nextColumns(pos.x)
    if c1 == null
      @flyToward = pos.add([20, 0])
    else
      [gap1, gap2] = [c1.getGap(), c2.getGap()]

      @updateGapPreviews(gap1, gap2) if @config.showPreviews

      topInt = paper.Point.max(gap1.topRight, gap2.topLeft)
      botInt = paper.Point.min(gap1.bottomRight, gap2.bottomLeft)

      if topInt.y >= botInt.y - @config.ship.collisionRadius * 2
        # stuck; just hover
        @flyToward = gap1.center
      else
        @flyToward = topInt.add(botInt).divide(2)

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
    steer = @config.ship.steer

    idealAngle = @flyToward.subtract(pos).angle

    $("#ship").text("angle "+Math.round(@heading.angle)+
                    " ideal "+Math.round(idealAngle))

    clampedIdealAngle = clamp(idealAngle, -steer.maxAbsAngle, steer.maxAbsAngle)

    requiredTurn = clampedIdealAngle - @heading.angle
    if Math.abs(requiredTurn) > steer.slowDownAngle
      if @heading.length > steer.minSpeed
        @heading = @heading.multiply(Math.pow(steer.brakes, dt))
    else
      if @heading.length < steer.maxSpeed
        @heading = @heading.multiply(Math.pow(steer.accel, dt))
  
    frameTurn = clamp(requiredTurn,
                      -steer.maxDegPerSec * dt,
                      steer.maxDegPerSec * dt)
    @heading = @heading.rotate(frameTurn, [0, 0])
    @setImageAngle(@heading.angle)

    @updatePreviewLine(@idealPreview, pos, clampedIdealAngle) if @idealPreview?
    @updatePreviewLine(@currentPreview, pos, @img.matrix.rotation) if @currentPreview?
  
  step: (dt) ->
    @updateFlyToward()
    @updateHeading(dt)

    @item.translate(@heading.multiply(dt))
      
  position: -> @item.matrix.translation
