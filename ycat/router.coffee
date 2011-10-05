XRegExp = require('xregexp').XRegExp
qs = require 'querystring'
url = require 'url'
www_forms = require 'www-forms'
http = require 'http'
config = require 'config'

SERVER_LOG = require('fs').createWriteStream(config.log_dir+'/server.log', flags: 'a', encoding: 'utf8')

# Sets some sensible defaults,
# and also sets req.path_data / req.query_data / req.post_data
# routes: an array of ['/route', fn(req, res)] pairs
exports.Router = (routes) ->
  # convert [route, fn] to [xregex, fn]
  # or, [options, route, fn] to [xregex, fn, options]
  parsed = []
  for route_fn in routes
    if route_fn.length > 2
      [options, route, fn] = route_fn
    else
      [route, fn] = route_fn
      options = undefined
    xregex = new XRegExp("^"+route.replace(/:([^\/]+)/g, "(?<$1>[^\/]+)")+"$")
    parsed.push([xregex, fn, options])

  # create a giant function that takes a (req, res) pair and finds the right fn to call.
  # we need a giant function for each server because that's how node.js works.
  giant_function = (req, res) ->
    # find matching route
    for [xregex, fn, options] in parsed
      matched = xregex.exec(req.url.split("?", 1))
      #console.log "/#{xregex}/ matched #{req.url.split("?", 1)} to get #{matched}"
      if not matched?
        continue
      # otherwise, we found our match.
      # construct the req.path_data object
      req.path_data = matched
      chain = if options and options.wrappers then options.wrappers.slice(0) else []
      chain.push(default_wrapper(fn))
      # This function will get passed through the wrapper chain like a hot potato.
      # all wrappers (except the last one) will receive this function as the third parameter,
      # and the wrapper is responsible for calling next(req, res) (or not).
      # I love closures.
      next = (req, res) ->
        next_wrapper = chain.shift()
        next_wrapper(req, res, next)
      # and finally
      next(req, res)
      return
    # if we're here, we failed to find a matching route.
    console.log("TODO request to unknown path #{req.url}")
    return

  server = http.createServer(giant_function)
  server.routes = parsed # you can dynamically alter this array if you want.
  return server
      
# a default decorator that handles logging and stuff
default_wrapper = (fn) ->
  return (req, res) ->
    SERVER_LOG.write("#{(''+new Date()).substr(0,24)} #{req.headers['x-real-ip'] or req.connection.remoteAddress} #{req.httpVersion} #{req.method} #{req.url} #{req.headers.referer} \n")
    SERVER_LOG.flush()
    res.addListener 'writeHead', (statusCode) ->
      SERVER_LOG.write("#{(''+new Date()).substr(0,24)} #{req.headers['x-real-ip'] or req.connection.remoteAddress} #{req.httpVersion} #{req.method} #{req.url} --> #{statusCode} \n")
      SERVER_LOG.flush()
    try
      if req.url.indexOf('?') != -1
        req.query_data = qs.parse(url.parse(req.url).query)
      else
        req.query_data = {}
      if (req.method == 'POST')
        body = ''
        req.setEncoding 'utf8'
        req.addListener 'data', (chunk) ->
          body += chunk
        req.addListener 'end', ->
          if body
            try
              if req.headers['content-type'].toLowerCase().indexOf('application/x-www-form-urlencoded') != -1
                req.post_data = www_forms.decodeForm(body)
                # SCRUB CARRIAGE RETURNS
                for key, value of req.post_data
                  req.post_data[key] = value.replace(/\r\n/g, "\n")
              else
                req.post_data = body
            catch e
              console.log e.message
              console.log e.stack
              console.log "Exception in parsing post data #{body}. Ignoring exception."
              req.post_data = body
          return fn(req, res)
      else
        return fn(req, res)
    catch e
      console.log("error in Router: " + e)
      console.log(e.stack)
      try
        res.writeHead(500, status: 'woops')
      catch _
        # pass
      res.end()
