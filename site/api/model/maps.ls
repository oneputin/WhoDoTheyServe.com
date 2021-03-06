_           = require \lodash
M           = require \mongoose
Cons        = require \../../lib/model-constraints
Crud        = require \../crud
M-Edges     = require \./edges
M-Evidences = require \./evidences
M-Nodes     = require \./nodes
M-Notes     = require \./notes
P-Id        = require \./plugin-id
P-Meta      = require \./plugin-meta

s-node = new M.Schema do
  _id: type:String , required:yes
  x  : type:Number , required:no # optional since node may be filtered out of d3
  y  : type:Number , required:no # optional since node may be filtered out of d3
  pin: type:Boolean, required:no # optional since most nodes won't be pinned

s-size =
  x: type:Number, required:yes
  y: type:Number, required:yes

schema = new M.Schema do
  name            : type:String, required:yes, match:Cons.map.name.regex
  description     : type:String, required:no , match:Cons.map.description.regex
  when            : type:String, required:no , match:Cons.map.when.regex
  edge_cutoff_date: type:Date  , default:Date.now # exclude edges created after this cutoff
  nodes           : [s-node]
  size            : s-size

schema
  ..plugin P-Id
  ..plugin P-Meta

module.exports = me = Crud.set-fns (M.model \maps, schema)
  ..crud-fns
    ..read = read
    ..list = Crud.get-invoker me, Crud.list, return-fields:<[ name meta ]>

# helpers

# return all entities required to render just this map
# to improve performance when hitting the site for the first time
function read req, res, next
  err, map <- me.findById req.id .lean!exec
  return next err if err
  return res.json {} unless map
  map.entities = {}
  # nodes
  map-node-ids = _.pluck map.nodes, \_id
  err, nodes <- M-Nodes.find!lean!exec
  return next err if err

  ## !!! server-side version of client-side view/map/refresh-entities
  map.entities.nodes = _.filter nodes, -> _.contains map-node-ids, it._id
  # edges excluding those created by other users after the cutoff
  err, edges <- M-Edges.find!lean!exec
  return next err if err
  map.entities.edges = _.filter edges, ->
    return false unless (_.contains map-node-ids, it.a_node_id) and (_.contains map-node-ids, it.b_node_id)
    return true unless edge-cutoff-date = map.edge_cutoff_date
    it.meta.create_date < edge-cutoff-date or it.meta.create_user_id is map.meta.create_user_id

  # evidences
  err, evs <- M-Evidences.find!lean!exec
  return next err if err
  map-entity-ids = map-node-ids ++ _.pluck map.entities.edges, \_id
  map.entities.evidences = _.filter evs, -> _.contains map-entity-ids, it.entity_id
  # notes
  err, notes <- M-Notes.find!lean!exec
  return next err if err
  map.entities.notes = _.filter notes, -> _.contains map-entity-ids, it.entity_id
  res.json map
