sugarcrm = require "node-sugarcrm"

class DemoController
	host:
		"localhost"
	servicePath:
		"/sugarcrm/service/v2/rest.php"
	username:
		"admin"
	password:
		"sugar123"
	onGetResult: (sender, err, result) ->
		console.log "Result of Get:"
		console.log result
		self = controller
		console.log self
		cbOnGetWithRelatedDone = (sender, error, result) -> self.onGetWithRelatedResult sender, error, result
		sender.getEntries "Accounts", {"Accounts":['id','name'], "Cases":['id','status']}, null, cbOnGetWithRelatedDone
	onGetWithRelatedResult: (sender, err, result) ->
		console.log "Result of getEntries:"
		console.log result
	onGetEntriesCount: (sender, err, resultCount) ->
		console.log "Entries count is "+resultCount
		self = @
		sender.getEntriesWithoutRelated "Accounts", ['id'], null, self.onGetResult
    
	onLogin: (sender, err) ->
		self = @
		if null != err
			console.log err
		else
			sessionId = sender.sessionId
			console.log "Session Id is "+sessionId
			cbOnGetEntriesCount = (sender, err, resultCount) -> self.onGetEntriesCount(sender, err, resultCount)
			sender.getEntriesCount "Accounts", null, cbOnGetEntriesCount
		return
	run: ->
		self = @
		cbOnLogin = (sender, err) -> self.onLogin(sender, err)
		client = new sugarcrm.SugarCrmClient(@host,@servicePath,@username,@password);
		client.login(cbOnLogin)
		return

controller = new DemoController()
controller.run()


