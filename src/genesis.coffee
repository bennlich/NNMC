# Genesis: model for NNMC project
# Use this in the NNMC folder to auto compile
# coffee --watch --map --compile --output lib/ src/ &

u = ABM.util; DataSet = ABM.DataSet # aliases

class ABM.models.Genesis extends ABM.Model # ABM.models is a place models w/o globals
  
  startup: -> # one-time sync load of resources needed by setup/step
    console.log "startup"
    
    console.log "..loading elevation asc file" 
    @elevation = DataSet.importAscDataSet "data/elevation640x480.asc", =>
      console.log "..creating slope/aspect data sets"
      [@slope, @aspect, @dzdx, @dzdy] = @elevation.slopeAndAspect()
    
    console.log "..loading data/water file"
    @patches.importColors "data/waterMap.png", =>
      console.log "..creating water patch variable via diffusion"
      p.water = p.color[0]/25.5 for p in @patches
      @patches.diffuse "water", 0.5 for i in [1..20]
      console.log "..setting patch color and water"
      for p in @patches
        u.setGray p.color, p.water*25.5
        p.water = p.water/10
      #@water

  setup: ->
    console.log "setup"
    @refreshPatches = @refreshLinks = false
    
    @patches.own "water"
    @agentBreeds "drops junipers ponderosas"
    
    @vision = 2
    @speed = .25
    
    @drops.setDefault "shape", "square"    
    @drops.setDefault "color", [0, 0, 255, 30/255] 
    
    @patches.cacheRect @vision, false # cache inRadius @vision
    
    # @anim.setRate 30, true # Don't use multiStep, draw faster than step
    @anim.setRate 10, true # multiStep great if fps low
    
    console.log "..drawing elevation"
    @elevation.toDrawing true
    
    console.log "..setting patch elevation value"
    @elevation.toPatchVar("elevation")

    console.log "..creating agents"
    # p.sprout 1, @drops for p in @patches.nOf(Math.round @patches.length/50)
    for p in @patches.nOf(Math.min @patches.length, 6000)
      p.sprout 1, @drops, (drop) ->
        #drop.penDown = true # ()
        #drop.color = [0 0 255]
    
    @drops.setDefault "penDown", true # set after drops moved, avoid initial draw from 0,0
    # @resetWater()
    
    console.log "patches: #{@patches.length}, agents: #{@agents.length}"      
  
  resetWater: ->
    @drops.clear()
    @drawing.clear()
    for p in @patches.nOf(Math.min @patches.length, 6000)
      p.sprout 1, @drops, (drop) ->
        drop.penDown()
  
  flowDownhill: ->
    for drop in @drops
      drop.heading = @aspect.patchSample(drop.x, drop.y)
      drop.forward u.randomNormal(0.1, 0.1)
        
  step: -> # stop: just one tick
    moved = 0
    for drop in @drops
      n = drop.p.pRect.minOneOf "elevation" # cached vision rect
      if drop.p.elevation > n.elevation
        drop.face n
        drop.forward @speed
        moved++
    if moved is 0
      console.log "done, ticks: #{@anim.ticks}"
      @stop()
    console.log @anim.toString(), "moved: #{moved}" if @anim.ticks % 100 is 0
    null
  

  # import drawing images, useful for UI & debugging. OK to be async
  drawLandCover:  -> @patches.importDrawing "data/nlcd.png"
  drawAerial:     -> @patches.importDrawing "data/naip2.png"
  drawShaded:     -> @patches.importDrawing "data/shadedelevation.png"
  drawWater:      -> @patches.importDrawing "data/waterMap.png"
  drawElevation:  -> @elevation.toDrawing()
  drawSlope:      -> @slope.toDrawing()
  drawAspect:     -> @aspect.toDrawing()
  drawDzdx:       -> @dzdx.toDrawing()
  drawDzdy:       -> @dzdy.toDrawing()
  drawAspect:     -> @aspect.toDrawing()
  drawWaterSet:   -> DataSet.patchDataSet("water").toDrawing()
