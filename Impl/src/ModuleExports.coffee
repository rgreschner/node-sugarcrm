# Create SugarCrmClient instance.
# ctorParams: Parameters to create instance with.
exports.createSugarCrmClient = (ctorParams) ->
	instance = new SugarCrmClient ctorParams
	return instance
	
# Create SugarCrmClient instance with supplied host and credentials.
# host: Host to connect to.
# servicePath: Path to service on host.
# username: Username for login.
# password: Password for login.
exports.createSugarCrmClientWithHostAndCredentials = (host,servicePath,username,password) ->
	instance = SugarCrmClient.createWithHostAndCredentials(host,servicePath,username,password)
	return instance