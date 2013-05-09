# see http://www.redblobgames.com/articles/visibility/


class window.Radar
  constructor: (config) ->
    @config = config
    @poly = new paper.Path()
    @rays = new paper.Group()
    @poly.style = {
      fillColor: new paper.Color(255,0,0,.2)
      strokeWidth: 0
    }
    @yellow = {
      strokeWidth: 1
      strokeColor: 'red'
    }
    @longX = new paper.Point(@config.width, 0)
    @walls = new paper.Group()

  longRayAtAngle: (source, ang) ->
    end = source.add(@longX.rotate(ang))
    new paper.Line(source, end, false)

  raysToAllCorners: (wallPaths, source, angLo, angHi) ->
    longRays = []
    for wp in wallPaths
      ang1 = @longX.getDirectedAngle(wp.point.subtract(source))
      if angLo < ang1 < angHi
        longRays.push(@longRayAtAngle(source, ang1))
      ang2 = @longX.getDirectedAngle(wp.point.add(wp.vector).subtract(source))
      if angLo < ang2 < angHi
        longRays.push(@longRayAtAngle(source, ang2))
    # i think it will be useful for these to be sorted by angle
    return longRays

  clipRay: (longRayLine, wallPaths) ->
    source = longRayLine.point
    closestHit = source.add(longRayLine.vector)
    closestDist = longRayLine.vector.length
    for wp in wallPaths
      intersection = wp.intersect(longRayLine)
      if intersection != undefined && intersection != null
        newDist = intersection.getDistance(source)
        if newDist < closestDist
          closestHit = intersection
          closestDist = newDist
    closestHit    
    
  computePolygon: (source, facingAngle, coneAngle, wallPaths) ->
    top = bottom = new paper.Point(source)
    angLo = facingAngle - coneAngle / 2
    top = top.add(@longX.rotate(angLo, [0, 0]))
    angHi = facingAngle + coneAngle / 2
    bottom = bottom.add(@longX.rotate(angHi, [0, 0]))

    if @config.radar.showPoly
      @poly.removeSegments()
      @poly.moveTo(source)
      @poly.lineTo(top)
      @poly.lineTo(bottom)
      @poly.closePath()

    @rays.removeChildren()

    longRays = @raysToAllCorners(wallPaths, source, angLo, angHi)

    for r in longRays
      closestHit = @clipRay(r, wallPaths)
      @rays.addChild(new paper.Path.Line(source, closestHit))

    @rays.style = @yellow 

    if @config.showPreviews
      @walls.removeChildren()
      for wp in wallPaths
        @walls.addChild(new paper.Path.Line(wp.point, wp.point.add(wp.vector)))
      @walls.style = {strokeWidth: 3, strokeColor: "green"}


    @poly

  draw: () ->
    0