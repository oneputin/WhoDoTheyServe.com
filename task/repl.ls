global.log = console.log

Chalk   = require \chalk
Rl      = require \readline
Shell   = require \shelljs/global
WFib    = require \wait.for .launchFiber
Build   = require \./build
Dir     = require \./constants .dir
Data    = require \./data
MaintDE = require \./maint/dead-evidences
Prod    = require \./prod
Run     = require \./run
Staging = require \./staging
Seo     = require \./seo
G       = require \./growl

# for safety, set working directory to dev build
cd Dir.DEV

# shelljs doesn't seem to raise exceptions. Next best thing is for this
# process to die on error
config.fatal = true

# flags
build-tests-enabled = true

const COMMANDS =
  * cmd:'h    ' lev:0 desc:'help  - show commands'      fn:show-help
  * cmd:'b    ' lev:0 desc:'build - recycle + test'     fn:Run.run-dev-tests
  * cmd:'b.fc ' lev:0 desc:'build - files compile'      fn:Build.compile-files
  * cmd:'b.fd ' lev:0 desc:'build - files delete'       fn:Build.delete-files
  * cmd:'b.la ' lev:0 desc:'build - loop app tests'     fn:Run.loop-dev-test_2
  * cmd:'b.nd ' lev:0 desc:'build - npm delete'         fn:Build.delete-modules
  * cmd:'b.nr ' lev:0 desc:'build - npm refresh'        fn:Build.refresh-modules
  * cmd:'b.t  ' lev:0 desc:'build - toggle tests ($BT)' fn:toggle-build-tests
  * cmd:'d.mde' lev:0 desc:'dev   - maintain dead evs'  fn:MaintDE.dev
  * cmd:'s    ' lev:0 desc:'stage - recycle + test'     fn:Run.run-staging-tests
  * cmd:'s.g  ' lev:1 desc:'stage - generate + test'    fn:generate-staging
  * cmd:'s.gs ' lev:1 desc:'stage - generate seo'       fn:Seo.generate
  * cmd:'s.mde' lev:1 desc:'stage - maintain dead evs'  fn:MaintDE.staging
  * cmd:'p    ' lev:0 desc:'prod  - show config'        fn:Prod.show-config
  * cmd:'p.l  ' lev:1 desc:'prod  - login'              fn:Prod.login
  * cmd:'p.mde' lev:1 desc:'prod  - maintain dead evs'  fn:MaintDE.prod
  * cmd:'p.UPD' lev:2 desc:'prod  - update stage->PROD' fn:Prod.update
  * cmd:'p.ENV' lev:2 desc:'prod  - env vars->PROD'     fn:Prod.send-env-vars
  * cmd:'d    ' lev:0 desc:'data  - show config'        fn:Data.show-config
  * cmd:'d.ba ' lev:0 desc:'data  - PROD->bak'          fn:Data.dump-prod-to-backup
  * cmd:'d.s2b' lev:0 desc:'data  - stage->bak'         fn:Data.dump-stage-to-backup
  * cmd:'d.st ' lev:1 desc:'data  - bak->stage'         fn:Data.restore-backup-to-staging
  * cmd:'d.B2P' lev:2 desc:'data  - bak->PROD'          fn:Data.restore-backup-to-prod

const CHALKS = [Chalk.stripColor, Chalk.yellow, Chalk.red]
for c in COMMANDS
  c.disabled = (c.cmd.0 is \d and not Data.is-cfg!) or (c.cmd.0 is \p and not Prod.is-cfg!)
  c.display = "#{Chalk.bold CHALKS[c.lev] c.cmd} #{c.desc}"

rl = Rl.createInterface input:process.stdin, output:process.stdout
  ..setPrompt "wdts >"
  ..on \line, (cmd) -> WFib ->
    switch cmd
    | '' =>
      <- Run.cancel
      rl.prompt!
    | _  =>
      for c in COMMANDS when cmd is c.cmd.trim! then try-fn c.fn
      rl.prompt!

Build.on \built, Run.recycle-dev
Build.on \built-api, -> Run.run-dev-test_1! if build-tests-enabled
Build.on \built-app, -> Run.run-dev-test_2! if build-tests-enabled
Build.start!

Run.recycle-dev!
Run.recycle-staging!

setTimeout show-help, 1000ms

# helpers

function generate-staging
  Staging.generate!
  Run.recycle-staging!
  Run.run-staging-tests!

function show-help
  bt = if build-tests-enabled then Chalk.bold.green \yes else Chalk.bold.cyan \no
  for c in COMMANDS when !c.disabled then log c.display.replace \$BT, bt
  rl.prompt!

function toggle-build-tests
  build-tests-enabled := not build-tests-enabled
  show-help!

function try-fn
  try it!
  catch e then log e
