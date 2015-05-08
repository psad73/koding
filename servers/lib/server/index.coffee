process.title = 'koding-webserver'
{argv}        = require 'optimist'

Object.defineProperty global, \
  'KONFIG', value : require('koding-config-manager').load "main.#{argv.c}"

{ webserver, projectRoot, basicAuth } = KONFIG

koding                = require './bongo'
express               = require 'express'
helmet                = require 'helmet'
bodyParser            = require 'body-parser'
usertracker           = require '../../../workers/usertracker'
app                   = express()
webPort               = argv.p ? webserver.port
{ error_500 }         = require './helpers'
{ generateHumanstxt } = require "./humanstxt"

do ->
  cookieParser = require 'cookie-parser'
  session      = require 'express-session'
  compression  = require 'compression'

  app.set 'case sensitive routing', on

  headers = {}
  if webserver?.useCacheHeader
    headers.maxAge = 1000 * 60 * 60 * 24 # 1 day

  app.use express.static "#{projectRoot}/website/", headers
  app.use cookieParser()
  app.use session
    secret            : 'foo'
    resave            : yes
    saveUninitialized : true
  app.use bodyParser.urlencoded extended : yes
  app.use compression()
  # helmet:
  app.use helmet.xframe('sameorigin')
  app.use helmet.iexss()
  app.use helmet.ienoopen()
  app.use helmet.contentTypeOptions()
  app.use helmet.hidePoweredBy()


# handle basic auth
app.use express.basicAuth basicAuth.username, basicAuth.password  if basicAuth

# capture/log exceptions
process.on 'uncaughtException', require './handlers/uncaughtexception'

# this is for creating session for incoming user if it doesnt have
app.use require './setsession'

# ORDER IS IMPORTANT
# routes ordered as before no particular structure

# temp endpoints @cihangir will reorganize these - SY
app.post '/-/teams/create'                       , require './handlers/createteam'
# fetches last members of team
app.all  '/-/teams/:name/members'                , require './handlers/getteammembers'
app.all  '/-/teams/:name'                        , require './handlers/getteam'
# temp endpoints ends

app.get  '/-/google-api/authorize/drive'         , require './handlers/authorizedrive'
app.post '/-/video-chat/session'                 , require './handlers/videosession'
app.post '/-/video-chat/token'                   , require './handlers/videotoken'
app.get  '/-/subscription/check/:kiteToken?/:user?/:groupId?' , require './handlers/kitesubscription'
app.get  '/-/auth/check/:key'                    , require './handlers/authkeycheck'
app.post '/-/support/new', bodyParser.json()     , require './handlers/supportnew'
app.get  '/-/auth/register/:hostname/:key'       , require './handlers/authregister'
# should deprecate those /Validates, they don't look like api endpoints
app.post '/:name?/Validate/Username/:username?'  , require './handlers/validateusername'
app.post '/:name?/Validate/Email/:email?'        , require './handlers/validateemail'
app.post '/:name?/Validate'                      , require './handlers/validate'
app.post '/-/password-strength'                  , require './handlers/passwordstrength'
app.post '/-/validate/username'                  , require './handlers/validateusername'
app.post '/-/validate/email'                     , require './handlers/validateemail'
app.post '/-/validate'                           , require './handlers/validate'
app.get  '/Verify/:token'                        , require './handlers/verifytoken'
app.post '/:name?/Register'                      , require './handlers/register'
app.post '/:name?/Login'                         , require './handlers/login'
app.post '/Impersonate/:nickname'                , require './handlers/impersonate'
app.post '/:name?/Recover'                       , require './handlers/recover'
app.post '/:name?/Reset'                         , require './handlers/reset'
app.post '/:name?/Optout'                        , require './handlers/optout'
app.all  '/:name?/Logout'                        , require './handlers/logout'
app.get  '/humans.txt'                           , generateHumanstxt
app.get  '/members/:username?*'                  , (req, res) -> res.redirect 301, "/#{req.params.username}"
app.get  '/w/members/:username?*'                , (req, res) -> res.redirect 301, "/#{req.params.username}"
app.get  '/activity/p/?*'                        , (req, res) -> res.redirect 301, '/Activity'
app.get  '/-/healthCheck'                        , require './handlers/healthcheck'
app.get  '/-/versionCheck'                       , require './handlers/versioncheck'
app.get  '/-/version'                            , (req, res) -> res.jsonp version: KONFIG.version
app.get  '/-/jobs'                               , require './handlers/jobs'
app.post '/recaptcha'                            , require './handlers/recaptcha'
app.get  '/-/presence/:service'                  , (req, res) -> res.status(200).end()
app.get  '/-/api/user/:username/flags/:flag'     , require './handlers/flaguser'
app.get  '/-/api/app/:app'                       , require './applications'
app.get  '/-/image/cache'                        , require './image_cache'
app.get  '/-/oauth/odesk/callback'               , require './odesk_callback'
app.get  '/-/oauth/github/callback'              , require './github_callback'
app.get  '/-/oauth/facebook/callback'            , require './facebook_callback'
app.get  '/-/oauth/google/callback'              , require './google_callback'
app.get  '/-/oauth/linkedin/callback'            , require './linkedin_callback'
app.get  '/-/oauth/twitter/callback'             , require './twitter_callback'
app.post '/:name?/OAuth'                         , require './oauth'
app.get  '/:name?/OAuth/url'                     , require './oauth_url'
app.get  '/-/subscriptions'                      , require './subscriptions'
app.get  '/-/payments/paypal/return'             , require './paypal_return'
app.get  '/-/payments/paypal/cancel'             , require './paypal_cancel'
app.get  '/-/payments/customers'                 , require './customers'
app.post '/-/payments/paypal/webhook'            , require './paypal_webhook'
app.post '/-/emails/subscribe'                   , (req, res) -> res.status(501).send 'ok'
app.post '/Hackathon/Apply'                      , require './handlers/hackathonapply'
# should deprecate those /Validates, they don't look like api endpoints
app.post '/Gravatar'                             , require './handlers/gravatar'
app.post '/-/gravatar'                           , require './handlers/gravatar'
app.get  '/Hackathon/:section?'                  , require './handlers/hackathon'
app.get  '/:name?/Develop/?*'                    , (req, res) -> res.redirect 301, '/'
app.all  '/:name/:section?/:slug?'               , require './handlers/main.coffee'
app.get  '/'                                     , require './handlers/root.coffee'
app.get  '*'                                     , require './handlers/rest.coffee'

# start webserver
app.listen webPort
console.log '[WEBSERVER] running', "http://localhost:#{webPort} pid:#{process.pid}"

# start user tracking
usertracker.start()

# init rabbitmq client for Email to use to queue emails
mqClient = require './amqp'
Email    = require '../../../workers/social/lib/social/models/email.coffee'
Email.setMqClient mqClient

# NOTE: in the event of errors, send 500 to the client rather
#       than the stack trace.
app.use (err, req, res, next) ->
  console.error "request error"
  console.error err
  console.error err.stack
  res.status(500).send error_500()
