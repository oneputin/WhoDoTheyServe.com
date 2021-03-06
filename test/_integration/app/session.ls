B = require \./_browser
S = require \../spec/session

module.exports = S.get-spec signin, signout

function signin handle, is-ok, fields = {}
  # nav away to clear previous errors
  B.click /About/, \a .wait-for /About/, \h3

  fields
    ..handle   ||= handle
    ..password ||= \Pass1!
  B.click \Login, \a
  B.fill Username:fields.handle, Password:fields.password
  B.click /Login/, \button
  B.assert.ok is-ok
  return unless is-ok
  B.wait-for /Welcome!/, \.view>.alert-info
  B.wait-for \Logout, '.nav li'

function signout
  B.click \Logout, \a
  B.assert.ok!
  B.wait-for /Goodbye!/, \.view>.alert-info
  B.wait-for \Login, '.nav li'
