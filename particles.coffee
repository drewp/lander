        
class window.Exhaust
  constructor: (config, state, getSource) ->
    @config = config
    @getSource = getSource

    @img = new paper.Raster('img/smoke1.png')
    @img.opacity = @config.exhaust.opacity

    @pts = []
    @moreParticles = 0

  addParticle: (source) ->
    p = @img.clone()
    p.rotation = Math.random() * 360
    p.position = source.pt

    r = paper.Point.random()
    d = @config.exhaust.drift

    # this should be rotated with ship angle
    p.vel = d.min.add(paper.Point.random().multiply(d.max.subtract(d.min))).rotate(source.dir.angle)
    @pts.push(p)

  step: (dt) ->
    source = @getSource()

    @moreParticles += @config.exhaust.bornPerSec * dt
    while @moreParticles > 1
      @addParticle(source)
      @moreParticles -= 1

    for p in @pts
      p.position = p.position.add(p.vel.multiply(dt))
      p.opacity *= Math.pow(@config.exhaust.opacityScalePerSec, dt)
    if @pts.length > @config.exhaust.maxAlive
      for p in @pts[0 ... @pts.length - @config.exhaust.maxAlive]
        p.remove()
  
      @pts[0 ... @pts.length - @config.exhaust.maxAlive] = []
