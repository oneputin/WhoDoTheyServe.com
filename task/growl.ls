Chalk = require \chalk
Gntp  = require \gntp
Util  = require \util

const APP     = \wdts
const DEFAULT = create-note \Default, Chalk.stripColor
const ERROR   = create-note \Error  , Chalk.red
const SUCCESS = create-note \Success, Chalk.green

module.exports =
  alert: (e, opts = {}) -> send ERROR, e, opts <<< sticky:true
  err  : (e, opts)      -> send ERROR, e, opts
  ok   : (text, opts)   -> send SUCCESS, text, opts
  say  : (text, opts)   -> send DEFAULT, text, opts

if enabled = (growl-at = process.env.growl-at)?
  log "growl at #growl-at"
  client = new Gntp.Client! <<< host:growl-at
  register!
else
  log "growl disabled"

## helpers

function create-note name, chalk
  new Gntp.Notification! <<< name:name, displayName:name, chalk:chalk

function register
  req = (new Gntp.Application APP).toRequest!
  for note in [DEFAULT, ERROR, SUCCESS] then req.addNotification note
  client.sendMessage req.toRequest!

function send note, text, opts = {}
  if text instanceof Error then text .= message
  Util.log note.chalk text unless opts.nolog
  return unless enabled
  req = note.toRequest! <<< (applicationName:APP, text:text) <<< opts
  client.sendMessage req.toRequest!
