###
# YCatalyst
# Copyright(c) 2011 Jae Kwon (jae@ycatalyst.com)
# MIT Licensed
###

require.paths.unshift '.'
require.paths.unshift 'lib'
require.paths.unshift 'ycat'
require.paths.unshift 'vendors'
require.paths.unshift 'vendors/node-validator'

http = require 'http'
cookie = require 'cookie-node'
ycat = require 'ycat'
auth = ycat.auth
templates = ycat.templates
config = require 'config'
_v = require 'validator'
_ = require 'underscore'

if true # TODO revisit
  process.on 'uncaughtException', (err) ->
    console.log "XXXXXXXXX"
    console.log err.message
    console.log err.stack
    console.log "XXXXXXXXX FIX THIS ASAP, http://debuggable.com/posts/node-js-dealing-with-uncaught-exceptions:4c933d54-1428-443c-928d-4e1ecbdd56cb"

server = ycat.router.Router([

  ['/static/:filepath', (req, res) ->
    switch req.method
      when 'GET'
        filepath = req.path_data.filepath
        filepath = require('path').join './static/', filepath
        if filepath.indexOf('static/') != 0
          res.writeHead 404, 'does not exist'
          res.end()
        else
          fu.staticHandler(filepath)(req, res)
  ]

  ['/', (req, res) ->
    switch req.method
      when 'GET'
        templates.render_layout "index", {}, req, res
  ]

])

server.listen config.server.port, config.server.host
console.log "Server running at http://#{config.server.host}:#{config.server.port}"
