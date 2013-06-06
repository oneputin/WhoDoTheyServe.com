_ = require \underscore
C = require \../../collection

exports
  ..data = ->
    _.map C.Nodes.models, (x) -> x.attributes

  ..init = (svg, d3-force) ~>
    @nodes = svg.selectAll \g.nodes
      .data d3-force.nodes!
      .enter!append \svg:g
        .attr \class, \nodes
        .call d3-force.drag

    @nodes.append \svg:circle
      .attr \class, \node
      .attr \r, -> 5 + it.weight

    @nodes.append \svg:a
      .attr \xlink:href, -> "#/node/#{it._id}"
      .append \svg:text
        .attr \dy, 4
        .attr \text-anchor, \middle
        .text -> it.name

  ..on-tick = ~>
    @nodes.attr \transform, ~> "translate(#{it.x},#{it.y})"
