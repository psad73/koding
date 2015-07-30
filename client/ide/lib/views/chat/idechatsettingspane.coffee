kd                          = require 'kd'
KDButtonView                = kd.ButtonView
KDCustomHTMLView            = kd.CustomHTMLView
KDLabelView                 = kd.LabelView
KDLoaderView                = kd.LoaderView
KDSelectBox                 = kd.SelectBox
KDTabPaneView               = kd.TabPaneView
remote                      = require('app/remote').getInstance()
whoami                      = require 'app/util/whoami'
nick                        = require 'app/util/nick'
JView                       = require 'app/jview'
KodingSwitch                = require 'app/commonviews/kodingswitch'
CustomLinkView              = require 'app/customlinkview'
IDEChatParticipantView      = require './idechatparticipantview'
ButtonViewWithProgressBar   = require 'app/commonviews/buttonviewwithprogressbar'


module.exports          = class IDEChatSettingsPane extends KDTabPaneView

  JView.mixin @constructor

  constructor: (options = {}, data)->

    options.cssClass = 'chat-settings'

    super options, data

    @participantViews    = {}
    {@rtm, @isInSession} = options

    @amIHost = not @isInSession # not @isInSession means user is host, bad naming!

    @createElements()

    @on 'CollaborationNotInitialized', => @everyone.destroySubViews()
    @on 'ParticipantJoined', @bound 'addParticipant'
    @on 'ParticipantLeft',   @bound 'removeParticipant'

    @on 'CollaborationEnded', =>
      @toggleButtons 'ended'
      @everyone.destroySubViews()

    @on 'CollaborationStarted', =>
      @toggleButtons 'started'

    @bindChannelEvents()


  bindChannelEvents: ->

    return

    channel = @getData()

    channel
      .on 'RemovedFromChannel', (acc) => @removeParticipant acc.profile.nickname, yes
      .on 'AddedToChannel',     (acc) =>

        return  unless acc.profile?
        return  unless @rtm.isReady

        @addParticipant acc.profile.nickname


  createElements: ->

    channel = @getData()

    @startSession = new ButtonViewWithProgressBar
      buttonOptions   :
        title         : 'START SESSION'
        cssClass      : 'solid green start-session'
        callback      : @bound 'initiateSession'
      progressOptions :
        title         : 'STARTING SESSION'
      loaderOptions   :
        size          : width : 20
        loaderOptions :
          color       : '#FFFFFF'
          shape       : 'spiral'
          density     : 30
          speed       : 1.5


    buttonTitle = if @isInSession then 'LEAVE SESSION' else 'END SESSION'

    @endSession = new KDButtonView
      title    : buttonTitle
      disabled : yes
      cssClass : 'solid red hidden'
      callback : => if @isInSession then @leaveSession() else @stopSession()

    @back = new CustomLinkView
      title    : 'Chat'
      cssClass : 'chat-link'
      click    : => @getDelegate().showChatPane()

    @everyone  = new KDCustomHTMLView
      tagName  : 'ul'
      cssClass : 'settings everyone loading'

    @everyone.addSubView new KDLoaderView
      showLoader : yes
      size       :
        width    : 24

    @everyone.addSubView new KDCustomHTMLView
      cssClass : 'label'
      partial  : 'Fetching participants'

    @createSettingsElements()


  createSettingsElements: ->

    @settings  = new KDCustomHTMLView
      tagName  : 'div'
      cssClass : 'session-settings'

    @createReadOnlySettingElements()
    @createUnwatchSettingElements()
    @createMuteHostSettingElements()


  WATCH_MODE_GUIDE_LINK = 'http://learn.koding.com/guides/collaboration/#watch_mode'

  createUnwatchSettingElements: ->

    @unwatchWrapper = new KDCustomHTMLView cssClass: 'wrapper unwatch'

    @unwatchWrapper.addSubView toggle = new KodingSwitch
      size         : 'tiny'
      defaultValue : on
      callback     : @bound 'setUnwatch'

    @unwatchWrapper.addSubView new KDLabelView
      title     : 'Allow participants to unwatch'
      mousedown : toggle.bound 'mouseDown'

    @unwatchWrapper.addSubView new KDCustomHTMLView
      tagName    : 'a'
      attributes :
        href     : WATCH_MODE_GUIDE_LINK
        target   : '_blank'
      partial    : '(?)'

    @settings.addSubView @unwatchWrapper

    @setUnwatch on  # set default value


  setUnwatch: (state) ->

    kd.singletons.appManager.tell 'IDE', 'setInitialSessionSetting', 'unwatch', state


  createReadOnlySettingElements: ->

    @readOnlyWrapper = new KDCustomHTMLView cssClass: 'wrapper read-only'

    @readOnlyWrapper.addSubView toggle = new KodingSwitch
      size         : 'tiny'
      defaultValue : off
      callback     : @bound 'setReadOnly'

    @readOnlyWrapper.addSubView new KDLabelView
      title     : 'Read-only session'
      mousedown : toggle.bound 'mouseDown'

    @settings.addSubView @readOnlyWrapper

    @setReadOnly off  # set default value


  setReadOnly: (state) ->

    kd.singletons.appManager.tell 'IDE', 'setInitialSessionSetting', 'readOnly', state


  createMuteHostSettingElements: ->

    @muteHostWrapper = new KDCustomHTMLView cssClass: 'wrapper mute-host'

    @muteHostWrapper.addSubView toggle = new KodingSwitch
      size         : 'tiny'
      defaultValue : off
      callback     : @bound 'setMuteHost'

    @muteHostWrapper.addSubView new KDLabelView
      title     : 'Participants can mute host'
      mousedown : toggle.bound 'mouseDown'

    @settings.addSubView @muteHostWrapper

    @setMuteHost off  # set default value


  setMuteHost: (state) ->

    kd.singletons.appManager.tell 'IDE', 'setInitialSessionSetting', 'muteHost', state


  initiateSession: ->

    kd.utils.wait 500,  => @startSession.updateProgress 5
    kd.utils.wait 1500, => @startSession.updateProgress 20
    kd.utils.wait 2500, => @startSession.updateProgress 65
    kd.utils.wait 3250, => @startSession.updateProgress 75

    { appManager } = kd.singletons

    appManager.tell 'IDE', 'startCollaborationSession', (err, channel) =>

      if err
        @startSession.resetProgress()
        return

      @toggleButtons 'started'
      @emit 'SessionStarted'


  leaveSession: ->

    kd.singletons.appManager.tell 'IDE', 'handleParticipantLeaveAction', whoami()


  stopSession: ->

    {appManager} = kd.singletons

    appManager.tell 'IDE', 'showEndCollaborationModal', (err, channel) =>

      return @endSession.enable()  if err

      @toggleButtons 'ended'


  toggleButtons: (state) ->

    startButton = @startSession
    endButton   = @endSession

    if state is 'started'
      endButton.show()
      endButton.enable()
      startButton.hide()
    else
      startButton.resetProgress()
      endButton.hide()
      endButton.disable()


  createParticipantsList: (accounts) ->

    @everyone.unsetClass 'loading'
    @everyone.destroySubViews()

    myNickname      = nick()
    onlineUsers     = @rtm.getFromModel('participants').asArray()
    onlineNicknames = (user.nickname for user in onlineUsers)

    for account in accounts
      {nickname} = account.profile
      isOnline   = onlineNicknames.indexOf(nickname) > -1

      if nickname isnt myNickname
        @createParticipantView account, isOnline

    if accounts.length is 1 and @amIHost

      @everyone.addSubView @onboarding = new KDCustomHTMLView
        tagName : 'p'
        click   : @bound 'handleOnboardingViewClick'
        partial : """
          There is no collaborator in your session. <a href="#">Click here</a> to invite someone to this session.
        """


  handleOnboardingViewClick: (e) ->

    if e.target.tagName is 'A'

      @onboarding.destroy()
      @emit 'AddNewParticipantRequested'


  createParticipantView: (account, isOnline) =>

    {nickname}        = account.profile
    watchList         = @rtm.getFromModel("#{nick()}WatchMap").keys()
    isWatching        = watchList.indexOf(nickname) > -1
    channel           = @getData()
    options           = { isOnline, @isInSession, isWatching }
    data              = { account, channel }
    participantView   = new IDEChatParticipantView options, data

    @participantViews[nickname] = participantView
    @everyone.addSubView participantView, null, isOnline
    @onboarding?.destroy()


  removeParticipant: (username, unshare) ->

    @participantViews[username]?.destroy()
    delete @participantViews[username]

    if unshare and @amIHost
      @emit 'ParticipantKicked', username


  addParticipant: (nickname) ->

    return no if nickname is nick()

    participantView = @participantViews[nickname]

    return participantView.setAsOnline()  if participantView

    remote.cacheable nickname, (err, account) =>
      @createParticipantView account.first, yes


  viewAppended: JView::viewAppended

  setTemplate: JView::setTemplate


  pistachio: ->

    return """
      <header class='chat-settings'>
        {{> @back}}
      </header>
      {{> @everyone}}
      <div class="warning">
        <div class="key-icon"></div>
        <span>Have sessions with people you trust, and remember,
          <a href="#{WATCH_MODE_GUIDE_LINK}" target="_blank">
            <strong>they can view and edit all your files!</strong>
          </a>
        </span>
      </div>
      {{> @settings}}
      <div class='buttons'>
        {{> @startSession}} {{> @endSession}}
      </div>
    """
