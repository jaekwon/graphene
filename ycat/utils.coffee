###
# YCatalyst
# Copyright(c) 2011 Jae Kwon (jae@ycatalyst.com)
# MIT Licensed
###

fs = require 'fs'

exports.ipRE = (() ->
  octet = '(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])'
  ip    = '(?:' + octet + '\\.){3}' + octet
  quad  = '(?:\\[' + ip + '\\])|(?:' + ip + ')'
  ipRE  = new RegExp( '^(' + quad + ')$' )
  return ipRE
)()

exports.dir = (object) ->
    methods = []
    for z in object
      if (typeof(z) != 'number')
        methods.push(z)
    return methods.join(', ')

SERVER_LOG = fs.createWriteStream('./log/server.log', flags: 'a', encoding: 'utf8')

# get current user
# sorry, node doesn't actually have a ServerRequest class?? TODO fix
Object.defineProperty(http.IncomingMessage.prototype, 'current_user', {
  get: () ->
    if not @_current_user?
      user_c = this.getSecureCookie('user')
      if user_c? and user_c.length > 0
        @_current_user = JSON.parse(user_c)
    return @_current_user
})

# set current user
Object.defineProperty(http.ServerResponse.prototype, 'current_user', {
  set: (user_object) ->
    @_current_user = user_object
    this.setSecureCookie 'user', JSON.stringify(user_object)
})

# respond with JSON
http.ServerResponse.prototype.simpleJSON = (code, obj) ->
  body = new Buffer(JSON.stringify(obj))
  this.writeHead(code, { "Content-Type": "text/json", "Content-Length": body.length })
  this.end(body)

# redirect
http.ServerResponse.prototype.redirect = (url) ->
  this.writeHead(302, Location: url)
  this.end()

# emit an event so we can log w/ req below in Rowt
_o_writeHead = http.ServerResponse.prototype.writeHead
http.ServerResponse.prototype.writeHead = (statusCode) ->
  this.emit('writeHead', statusCode)
  _o_writeHead.apply(this, arguments)

# other utility stuff
exports.randid = () ->
    text = ""
    possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    for i in [1..12]
        text += possible.charAt(Math.floor(Math.random() * possible.length))
    return text

# a function to add a digest nonce parameter to a static file to help with client cache busting
_static_file_cache = {}
exports.static_file = (filepath) ->
  if not _static_file_cache[filepath]
    fullfilepath = "static/#{filepath}"
    nonce = require('hashlib').md5(require('fs').statSync(fullfilepath).mtime)[1..10]
    console.log("SYNC CALL: static_file, nonce = #{nonce}")
    _static_file_cache[filepath] = "/#{fullfilepath}?v=#{nonce}"
  return _static_file_cache[filepath]

crypto = require('crypto')
exports.passhash = (password, salt, times) ->
  hashed = crypto.createHash('md5').update(password).digest('base64')
  for i in [1..times]
    hashed = crypto.createHash('md5').update(hashed).digest('base64')
  return hashed

# clone nested objects, though
# it gets tricky with special objects like Date...
# add extensions here.
exports.deep_clone = deep_clone = (obj) ->
  if obj == null
    return null
  newObj = if (obj instanceof Array) then (new Array()) else {}
  for own key, value of obj
    if value instanceof Date
      newObj[key] = value
    else if typeof value == 'object'
      newObj[key] = deep_clone(value)
    else
      newObj[key] = value
  return newObj

# for displaying the hostname in parentheses
exports.url_hostname = (url) ->
  try
    host = require('url').parse(url).hostname
    if host.substr(0, 4) == 'www.' and host.length > 7
      host = host.substr(4)
  catch e
    throw 'invalid url?'
  return host

# sometimes you want to call a second block of code synchronously or asynchronously depending
# on the first block of code. In this case, use the 'compose' method.
#
# compose (next) ->
#   if(synchronous?)
#     next("some_arg")
#   else
#     db.asynchronous_call (err, values) ->
#       next("other_arg")
# , (arg) ->
#   console.log arg
# 
# You can chain many functions together.
#
# compose (next) ->
#   console.log "this is the first line"
#   next("this is the second line")
#
# , (next, line) ->
#   console.log line
#   next("this is", "the third line")
#
# , (part1, part2) ->
#   console.log "#{part1} {part2}"

compose = (fns...) ->
  _this = if (typeof(fns[0]) == 'function') then null else fns.shift()
  # return a function that calls the index'th function in fns
  next_gen = (index) ->
    () ->
      if not (0 <= index < fns.length)
        throw new Error "should not happen: 0 <= #{index} < #{fns.length}"
      next_block = fns[index]
      if index < fns.length - 1
        Array::unshift.call(arguments, next_gen(index+1))
      return next_block.apply(_this, arguments)
  return next_gen(0)()
