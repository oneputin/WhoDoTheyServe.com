const PROD-URL = \http://wdts10.eu01.aws.af.cm/api

module.exports =
  init: ->
    return unless is-prod!
    # http://backbonetutorials.com/cross-domain-sessions/
    $.ajaxPrefilter (opts) ->
      opts.xhrFields = withCredentials:true

  post-coverage: -> # https://github.com/gotwarlost/istanbul-middleware
    new XMLHttpRequest!
      ..open \POST, \/coverage/client
      ..setRequestHeader 'Content-Type', 'application/json; charset=UTF-8'
      ..send JSON.stringify window.__coverage__

  ## endpoints
  edges    : get-url \edges
  evidences: get-url \evidences
  hive     : get-url \hive
  maps     : get-url \maps
  nodes    : get-url \nodes
  notes    : get-url \notes
  sessions : get-url \sessions
  sys      : get-url \sys
  users    : get-url \users

## helpers

function get-url endpoint
  "#{if is-prod! then PROD-URL else \/api}/#{endpoint}"

function is-prod
  loc = window.location
  /whodotheyserve\.com$/.test loc.hostname or /prod/.test loc.search
