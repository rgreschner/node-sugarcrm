# Begin include section.

crypto = require 'crypto'
http = require 'http'

# End include section.

# Returns whether value is null or undefined.
isNullOrUndefined = (value) ->
	return null == value || undefined == value;

# Begin SugarCrmClient class.
	
# Client for SugarCRM REST API.
class SugarCrmClient

	# Public ctor.
	# host: Host to connect to.
	# servicePath: Path to service on host.
	# username: Username for login.
	# password: Password for login.
	constructor:(@host, @servicePath, @username, @password)	->

	# Session Id issued from service.
	sessionId:
		null

	# Path to service on host.
	servicePath:
		null
	
	# Host to connect to.
	host:
		null
		
	# Username for login.
	username:
		null

	# Password for login.
	password:
		null
		
	# Create options object for HTTP request.
	createOptionsForRpcRequest: ->
		options = {  
			host: @host,   
			path: @servicePath,
			method: 'POST',
			headers: {
				'Content-Type': 'application/x-www-form-urlencoded'	 
			}
		}
		return options
		
	# Create HTTP request for RPC.
	createRequestForRpc: ->
		options = @createOptionsForRpcRequest()
		request = http.request options
		return request
		
	# Send HTTP request.
	# method: Name of remote method to use.
	# restData: Data to send.
	# cbOnResult: Callback function(error, result) for result.
	sendRequest: (method, restData, cbOnResult, cbOnError)->
		
		req = @createRequestForRpc()
	
		# Data to POST.
		postData = "method="+method+"&input_type=JSON&response_type=JSON&rest_data="+JSON.stringify(restData)
		req.write postData
		
		# Cache this instance.
		self = @
		
		# Handler for HTTP response.
		req.on 'response', (response)->self.onSendRequestResponse(response, cbOnResult)
		
		# Register error handler.
		req.on 'error', cbOnError
		
		req.end()
		return
		
	# Get hashed password for login.
	getHashedPassword: ->
		# Hash password using MD5.
		hash = crypto.createHash('md5')
		hash.update(@password);
		hashedPassword = hash.digest('hex')
		return hashedPassword
		
	# Perform login.
	# cbOnLogin: Callback function(sender,error) for login.
	login: (cbOnLogin) ->
		hashedPassword = @getHashedPassword()
		restData = 
		{
			user_auth : {
				user_name : @username,
				password : hashedPassword
			},
			name_value_list : {
				name : "notifyonsave",
				value : true,
			}
		}
		self = @
		cbOnResult = (error, result) -> self.onLoginResult(error, result, cbOnLogin)
		cbOnError = (error) -> self.onLoginResult(error, null, cbOnLogin)
		@sendRequest "login", restData, cbOnResult, cbOnError
		
		return
	
	# Handle response for sended requests.
	# response: HTTP response.
	# cbOnResult: Callback function(error, result) for result.
	onSendRequestResponse: (response, cbOnResult) ->
		self = @
		response.on 'data', (data)->self.onSendRequestReceiveChunk(data, cbOnResult)
		return
		
	# Handler for GetWithRelated.
	# sender: Sender of method.
	# error: Error data (if any).
	# result: Result data.
	# cbOnDone: Callback function(sender, error, result) when done with operation.
	onGetWithRelatedForGet: (sender, error, result, cbOnDone) ->
		records = []
		if null == result || undefined == result
			return
		for entry in result.entry_list
			record = []
			for field in entry['name_value_list']
				record[field.name] = field.value
				records.push record
		self = @
		cbOnDone self, null, records
		return
    
	# Get entries without related.
	# cbOnDone: Callback function(sender, error, result) when done with operation.
	getEntriesWithoutRelated: (module, fields, options, cbOnDone) ->

		self = @
	
		cbOnGetWithRelatedDone = (sender, error, result, cbOnDoneInCB) -> self.onGetWithRelatedForGet sender, error, result, cbOnDone
		moduleFields = []
		moduleFields[module] = fields
		self.getEntries module, moduleFields, options, cbOnGetWithRelatedDone
		return
    
	# Get entries with related.
	# module: Name of module to get entries for.
	# fields: Definition of fields to get.
	# options: Options for get.
	# cbOnDone: Callback function(sender,error,result) when done with operation.
	getEntries: (module, fields, options, cbOnDone) ->
	
		self = @
	
		
	
		# Abort if no fields set.
		if fields.length < 1
			error = "Error: No fields set."
			cbOnDone self, error, null
			
		if isNullOrUndefined options
			options = []
		
		# Set default values on options.
		if isNullOrUndefined(options.limit)
			options.limit = 20
		if isNullOrUndefined(options.offset)
			options.offset = 0
		if undefined == options.where
			options.where = null
		if undefined == options.orderBy
			options.orderBy = null
		if isNullOrUndefined(fields[module])
			error = "Error: No module set."
			cbOnDone self, error, null
		baseFields = fields[module]
		fields[module] = undefined
		
		relationships = []
		
		for relatedModule of fields
			fieldsList = fields[relatedModule]
			tmpArr = []
			tmpArr['name'] = relatedModule
			tmpArr['value'] = fieldsList
			relationships = relationships.concat tmpArr
		

		restData = 
		{
			session : @sessionId,
			module_name : module,
			query : options.where,
			order_by : options.orderBy,
			offset : options.offset,
			select_fields : baseFields,
			link_name_to_fields_array : relationships,
			max_results : options.limit,
			deleted : false
		}
		
		
		
		# Local callback definitions.
		cbOnResult = (error, result) -> cbOnDone(self, error, result)
		cbOnError = (error) -> cbOnDone(self, error, null)
		@sendRequest "get_entry_list", restData, cbOnResult, cbOnError
		
		return
   
    # Get count of entries.
	# module: Name of module to get entry count for.
	# query: Query to query entries for.
	# cbOnDone: Callback function(sender,error,resultCount) when done with operation.
	getEntriesCount: (module, query, cbOnDone) ->

		self = @

		restData =
		{
		  session : @sessionId,
		  module_name : module,
		  query : query,
		  deleted : 0
		}
		
		
		# Local callback definitions.
		cbOnResult = (error, result) -> self.onGetEntriesCountResult(error, result, cbOnDone)
		cbOnError = (error) -> self.onGetEntriesCountResult(error, null, cbOnDone)

		@sendRequest "get_entries_count", restData, cbOnResult, cbOnError


		return
	
	# Set entry data.
	# module: Name of module to set entries for.
	# values: List of key/value pairs to set on entry.
	# cbOnDone: Callback function(sender,error,result) when operation is done.
	setEntry: (module, values, cbOnDone) ->
		
		self = @

		restData = 
		{
			session : @sessionId,
			module_name : module,
			name_value_list : values
		}



		# Local callback definitions.
		cbOnResult = (error, result) -> cbOnDone(self, error, result)
		cbOnError = (error) -> cbOnDone(self, error, null)
		@sendRequest "set_entry", restData, cbOnResult, cbOnError

		return
    
	# Handler for GetEntries service result.
	# error: Error data (if any).
	# result: Result from service.
	# cbOneDone: Callback function(sender, error, resultCount) when done with operation.
	onGetEntriesCountResult: (error, result, cbOnDone) ->
		resultCount = result.result_count
		cbOnDone @, error, resultCount
		return
	
	# Handle response for sent requests.
	# response: HTTP response.
	# cbOnResult: Callback function(error, result) for result.
	onSendRequestResponse: (response, cbOnResult) ->
		self = @
		response.on 'data', (data)->self.onSendRequestReceiveChunk(data, cbOnResult)
		return
		
		
	# Handle received chunks of sent requests.
	# chunk: Received chunk.
	# cbOnResult: Callback function(error, result) for result.
	onSendRequestReceiveChunk: (chunk, cbOnResult) ->
		error = null
		result = null
		
		# Read result object from chunk.
		try
			result = JSON.parse chunk
		catch ex0
			error = ex0
		cbOnResult error, result
		return
		
	# Handle login result.
	# error: Error data (if any).
	# result: Result object from service.
	# cbOnLogin: Callback function(sender,error) for login.
	onLoginResult: (error, result, cbOnLogin) ->
	
		# Pre-check for errors on result.
		if null == error and null != result 
			# Check for invalid login.
			if "Invalid Login" == result.name
				error = "Error: Invalid Login Credentials"
				
		# Set auth-token only on success.
		if null == error
			@sessionId = result.id
			
		# Call callback.
		cbOnLogin @,error
		return

# End SugarCrmClient class.