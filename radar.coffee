# see http://www.redblobgames.com/articles/visibility/


class window.Radar
  constructor: ->
    @poly = new paper.Path()
    @rays = new paper.Group()
    @poly.style = {
      fillColor: new paper.Color(255,0,0,.5)
      strokeWidth: 0
      opacity: .5
    }
    @yellow = {
      strokeWidth: 1
      strokeColor: 'yellow'
    }
  
  computePolygon: (source, facingAngle, coneAngle, wallPaths) ->
    longX = new paper.Point(300, 0)
    @poly.removeSegments()
    @poly.moveTo(source)
    top = bottom = new paper.Point(source)
    angLo = facingAngle - coneAngle / 2
    top = top.add(longX.rotate(angLo, [0, 0]))
    angHi = facingAngle + coneAngle / 2
    bottom = bottom.add(longX.rotate(angHi, [0, 0]))

    @poly.lineTo(top)
    @poly.lineTo(bottom)
    @poly.closePath()

    @rays.removeChildren()

    for wp in wallPaths
      ang1 = longX.getDirectedAngle(wp.firstSegment.point.subtract(source))
      if angLo < ang1 < angHi
        @rays.addChild(new paper.Path.Line(source, source.add(longX.rotate(ang1))))
      ang2 = longX.getDirectedAngle(wp.lastSegment.point.subtract(source))
      if angLo < ang2 < angHi
        @rays.addChild(new paper.Path.Line(source, source.add(longX.rotate(ang2))))


    @rays.style = @yellow 


    @poly

  draw: () ->
    0