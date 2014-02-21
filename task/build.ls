_      = require \lodash
Assert = require \assert
Brsify = require \browserify
Brfs   = require \brfs
Cron   = require \cron
Fs     = require \fs
Gaze   = require \gaze
Md     = require \marked
Path   = require \path
Shell  = require \shelljs/global
WFib   = require \wait.for .launchFiber
WFor   = require \wait.for .for
W4m    = require \wait.for .forMethod
G      = require \./growl

const BUILD    = \_build
const BUILDOBJ = "#BUILD/obj"
const NMODULES = './node_modules'
const ROOT     = pwd!replace "/#BUILDOBJ", ''

opts   = on-built: ->
pruner = new Cron.CronJob cronTime:'*/10 * * * *', onTick:prune-empty-dirs
tasks  =
  jade:
    cmd : "#NMODULES/jade/bin/jade --out $OUT $IN"
    ixt : \jade
    oxt : \html
    mixn: \_
  livescript:
    cmd : "#NMODULES/LiveScript/bin/lsc --output $OUT $IN"
    ixt : \ls
    oxt : \js
    xsub: 'json.js->json'
  markdown:
    cmd : markdown
    ixt : \md
    oxt : \html
  static:
    cmd : 'cp $IN $OUT'
    ixt : '+(css|gif|html|jpg|js|json|pem|png|svg|ttf|txt|woff)'
  stylus:
    cmd : "#NMODULES/stylus/bin/stylus -u nib --out $OUT $IN"
    ixt : \styl
    oxt : \css
    mixn: \_

module.exports =
  compile-files: ->
    try
      for tid of tasks then compile-batch tid
      finalise!
    catch e then G.err e

  delete-files: ->
    log "delete-files #{pwd!}"
    Assert _.contains pwd!, BUILDOBJ
    WFor exec, "bash -O extglob -O dotglob -c 'rm -rf !(node_modules|task)'"

  delete-modules: ->
    log "delete-modules #{pwd!}"
    Assert _.contains pwd!, BUILDOBJ
    rm '-rf' "./node_modules"

  refresh-modules: ->
    WFor exec, 'npm prune'
    WFor exec, 'npm install'

  start: ->
    G.say 'build started'
    opts <<< it
    try
      pushd ROOT
      for tid of tasks then start-watching tid
    finally
      popd!
    pruner.start!

  stop: ->
    pruner.stop!
    for , t of tasks then t.gaze?close!
    G.say 'build stopped'

## helpers

function bundle
  const LIBS =
    # execution order is random
    # https://github.com/substack/node-browserify/issues/355
    \./lib-3p/underscore.mixin.deepExtend
    \./lib-3p/backbone-deep-model
    \./lib-3p/backbone.routefilter
    \./lib-3p/backbone-validation-bootstrap
    \./lib-3p/bootstrap-combobox
    \./lib-3p/insert-css
    \./lib-3p/transparency
    \./lib-3p-ext/jquery
  try
    pushd "./app"
    ba = Brsify \./boot.js
    for l in LIBS then ba.external l
    ba.transform Brfs
      ..require \./lib-3p/transparency   , expose:\transparency
      ..require \./lib-3p-shim/backbone  , expose:\backbone
      ..require \./lib-3p-shim/underscore, expose:\underscore
      ..bundle detectGlobals:false, insertGlobals:false
        ..on \end, -> G.say 'Bundled app.js'
        ..pipe Fs.createWriteStream \app.js

    bl = Brsify LIBS
    for l in LIBS then bl.require l
    bl.bundle detectGlobals:false, insertGlobals:false
      ..on \end, -> G.say 'Bundled lib.js'
      ..pipe Fs.createWriteStream \lib.js
  finally
    popd!

function compile t, ipath, cb
  odir = Path.dirname opath = get-opath t, ipath
  mkdir '-p', odir # stylus fails if outdir doesn't exist
  switch typeof t.cmd
  | \string =>
    cmd = t.cmd.replace(\$IN, "'#ipath'").replace \$OUT, "'#odir'"
    code, res <- exec cmd
    log code, res if code
    cb (if code then res else void), opath
  | \function =>
    e <- t.cmd ipath, opath
    cb e, opath

function compile-batch tid
  t = tasks[tid]
  # https://github.com/shama/gaze/issues/74
  files = [ f for dir, paths of t.gaze.watched! for f in paths
    when '/' isnt f.slice -1 and (Path.basename f).0 isnt t.mixn ]
  info = "#{files.length} #tid files"
  G.say "compiling #info..."
  for f in files then WFor compile, t, f
  G.ok "...done #info!"

function get-opath t, ipath
  p = ipath.replace("#ROOT/", '').replace t.ixt, t.oxt
  return p unless (xsub = t.xsub?split '->')?
  p.replace xsub.0, xsub.1

function markdown ipath, opath, cb
  e, obj <- Md cat ipath
  obj.to opath unless e?
  cb e

function finalise ipath
  return if /\/task\//.test ipath
  rx = new RegExp "^#ROOT/(app|lib)"
  bundle! if not ipath? or rx.test ipath
  opts.on-built!

function prune-empty-dirs
  Assert _.contains pwd!, BUILDOBJ
  code, out <- exec "find . -type d -empty -delete"
  G.err "prune failed: #code #out" if code

function start-watching tid
  log "start watching #tid"
  Assert.equal pwd!, ROOT
  t = tasks[tid]
  t.gaze = Gaze [ "**/*.#{t.ixt}", "!#BUILD/**" ], ->
    act, ipath <- t.gaze.on \all
    return if '/' is ipath.slice -1 # BUG: Gaze might fire when dir added
    WFib ->
      if t.mixn? and (Path.basename ipath).0 is t.mixn then
        try
          compile-batch tid
          finalise ipath
        catch e then G.err e
      else switch act
        | \added, \changed, \renamed
          try opath = WFor compile, t, ipath
          catch e then return G.err e
          G.ok opath
          finalise ipath
        | \deleted
          try W4m Fs, \unlink, opath = get-opath t, ipath
          catch e then throw e unless e.code is \ENOENT # not found i.e. already deleted
          G.ok "Delete #opath"
          finalise ipath