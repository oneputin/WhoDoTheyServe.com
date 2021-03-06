_   = require \underscore
Map = require \../../view .map

Map.on \render ->
  $svg = @$el.find \svg
  @$el.off \click, show-cursor # otherwise handler runs against old svg in closure
  @$el.on  \click, show-cursor

  ## helpers

  ~function find-nearest-node x, y
    function get-distance x0, x1, y0, y1 then Math.sqrt(((x1 - x0) ^ 2) + ((y1 - y0) ^ 2))
    dists = _.map @d3f.nodes!, ->
      it: it
      d : get-distance it.x, x, it.y, y
    (_.min dists, -> it.d).it

  function get-cursor-path
    function get-segment sign-x, sign-y
      const RADIUS = 32px
      const LENGTH = 8px
      px = RADIUS * sign-x
      py = RADIUS * sign-y
      qx = px + LENGTH * sign-x
      qy = py + LENGTH * sign-y
      "M #px #py L #px #qy L #qx #py L #px #py "
    get-segment(+1, +1) + get-segment(+1, -1) + get-segment(-1, +1) + get-segment(-1, -1)

  ~function show-cursor
    log it.offsetY, it.layerY, it.originalEvent.layerY
    log [x, y] = [it.pageX - $svg.position!left, it.offsetY or it.originalEvent.layerY ]
    nd = find-nearest-node x, y
    id = nd._id
    n = @svg.select "g.node.id_#id"
    @svg.select \.cursor .remove!
    n.append \svg:path
      .attr \class, \cursor
      .attr \d, get-cursor-path!
