B   = require \backbone
_   = require \underscore
C   = require \../collection
Sys = require \../model/sys .instance
E   = require \./map/edge
N   = require \./map/node

const SIZE-NEW = 500px

module.exports = B.View.extend do
  delete: ->
    delete @map
    @trigger \deleted

  get-nodes-xy: ->
    _.map @d3f.nodes!, ->
      _id: it._id
      x  : Math.round it.x
      y  : Math.round it.y
      pin: it.fixed

  get-size-x: -> @svg?attr \width
  get-size-y: -> @svg?attr \height

  initialize: ->
    n-tick = 0
    is-resized = false
    @d3f = d3.layout.force!
      ..on \start, ~>
        @trigger \pre-cool
        is-resized := false
      ..on \tick , ~>
        return unless n-tick++ % 4 is 0
        tick!
        @trigger \tick
        if @map.get-is-editable! and not is-resized and @d3f.alpha! < 0.03
          set-map-size @
          is-resized := true # resize only once during cool-down
      ..on \end  , ~>
        @trigger \cooled
    B.on 'signin signout', ~> @delete!

  refresh-entities: (node-ids) -> # !!! client-side version of server-side logic in model/maps.ls
    return unless node-ids.length isnt (@map.get \nodes)?length
    @map.set \nodes, _.map node-ids, (nid) ~>
      node = _.findWhere @d3f.nodes!, _id:nid
      _id: nid
      x  : node?x or @get-size-x!/2 # add new node to center
      y  : node?y or @get-size-y!/2
      pin: node?fixed
    @map.set \entities,
      nodes: C.Nodes.filter -> _.contains node-ids, it.id
      edges: C.Edges.filter ~>
        return false unless it.is-in-map node-ids
        return true unless edge-cutoff-date = @map.get \edge_cutoff_date
        map-create-uid   = @map.get \meta .create_user_id
        edge-create-date = it.get \meta .create_date
        edge-create-uid  = it.get \meta .create_user_id
        edge-create-date < edge-cutoff-date or edge-create-uid is map-create-uid
    true

  render: (opts) ->
    return unless @el # might be undefined for seo
    @$el.empty!
    # clone entities so the originals don't get filtered out, as they may be used elsewhere
    return unless ents = _.deepClone @map.get \entities
    return unless ents.nodes?length

    ents.nodes = _.map ents.nodes, -> it.toJSON-T!
    ents.edges = _.map ents.edges, -> it.toJSON-T!
    ents.edges = E.filter ents.nodes, ents.edges, @map.get \when
    @trigger \pre-render, ents # ents can be modified by handlers

    size-x = @map.get \size.x or @get-size-x! or SIZE-NEW
    size-y = @map.get \size.y or @get-size-y! or SIZE-NEW

    is-editable = @map.get-is-editable!
    unless @map.isNew!
      for n in @map.get \nodes when n.x?
        node = _.findWhere ents.nodes, _id:n._id
        node <<< { x:n.x, y:n.y, fixed:(not is-editable) or n.pin } if node?

    @d3f.stop!
    @d3f.nodes ents.nodes
     .links (ents.edges or [])
     .charge -2000
     .friction 0.85
     .linkDistance 100
     .linkStrength E.get-strength
     .size [size-x, size-y]
     .start!

    @svg = d3.select @el .append \svg:svg
    set-canvas-size @svg, size-x, size-y
    justify @

    # order matters: svg uses painter's algo
    E.render @svg, @d3f
    N.render @svg, @d3f
    @trigger \render, ents
    @svg.selectAll \g.node .call @d3f.drag if is-editable
    @trigger \rendered

    # determine whether to freeze immediately
    unless Sys.env is \test # no need to wait for cooldown when testing
      return if @map.isNew!
      return if opts?is-slow-to-cool

    @d3f.alpha 0 # freeze map -- must be called after start
    tick!        # single tick required to render frozen map
    @trigger \tick

  show: ->
    return unless @el # might be undefined for seo
    @scroll = @scroll or x:0, y:0
    $window = $ window
    B.once \pre-route, ~>
      @scroll.x = $window.scrollLeft!
      @scroll.y = $window.scrollTop!
    @$el.show!
    justify @
    _.defer ~> $window .scrollTop(@scroll.y) .scrollLeft(@scroll.x)

## helpers

function tick
  N.refresh-position!
  E.refresh-position!

function justify v
  return unless ($vm = $ '.view>.map').is \:visible # prevent show if it's hidden
  return unless v.svg # might be undefined e.g. new map
  # only apply flex if svg needs centering, due to bugs in flex when content exceeds container width
  if (v.svg.attr \width) < $vm.width!
    $vm.css \display, \flex
    $vm.css \align-items, \center # vert
    $vm.css \justify-content, \center # horiz
  else
    $vm.css \display, \block
    $vm.css \justify-content, \flex-start

function set-canvas-size svg, w, h
  svg.attr \width, w .attr \height, h

function set-map-size v
  const PADDING = 200px

  nodes = v.get-nodes-xy!
  xs = _.map nodes, -> it.x
  ys = _.map nodes, -> it.y
  w  = (_.max xs) - (xmin = _.min xs) + 2 * PADDING
  h  = (_.max ys) - (ymin = _.min ys) + 2 * PADDING

  size-before = x:v.get-size-x!, y:v.get-size-y!
  set-canvas-size v.svg, w, h
  justify v
  v.d3f.size [w, h]

  v.map.set \size.x, w
  v.map.set \size.y, h

  # reposition fixed nodes
  dx = (w - size-before.x) / 2
  dy = (h - size-before.y) / 2
  for n in v.d3f.nodes! when n.fixed
    n.px += dx
    n.py += dy
