exports.createSugarCrmClient = (host,servicePath,username,password) ->
	return SugarCrmClient.create(host,servicePath,username,password)