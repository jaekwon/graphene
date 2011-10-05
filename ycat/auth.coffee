http = require 'http'

# wrapper to require current_user
exports.require_login = (req, res, next) ->
  if not req.current_user?
    res.writeHead 401, status: 'login_error'
    res.end 'not logged in'
    return
  else
    next(req, res)

# wrapper generator to require current_user, but also direct them to a login page with a nice message
# message: string or optional
exports.require_login_nice = (message) ->
  return (req, res, next) ->
    if not req.current_user?
      render_layout "login", {message: message or 'You need to login to do that'}, req, res
    else
      next(req, res)

exports.require_admin = (req, res, next) ->
  if not req.current_user.is_admin
    res.writeHead 401, status: 'privileges_error'
    res.end 'not authorized'
    return
  else
    next(req, res)

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
