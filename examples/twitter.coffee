rest = require 'restler'
util = require 'util'
gendr = require('../lib/gendr').createClient()

twitter = (username, cursor = -1, given_names = []) ->
	if parseInt(cursor,10) is 0
		start2 = new Date()
		gendr.check(given_names).on 'finished', (data) ->
			util.log "getting gender from gendr #{new Date() - start2} ms"
			util.log "#{username}:"
			util.log JSON.stringify data
	else
		uri = "http://api.twitter.com/1/statuses/friends/#{username}.json?cursor=#{cursor}"
		start2 = new Date()
		rest.get(uri, rest.parsers.json).on 'success', (data) ->
			util.log "Request to #{uri} took #{new Date() - start2} ms."
			for user in data.users
				given_names.push user.name.split(" ")[0]
			twitter(username, data.next_cursor, given_names)

twitter "david_bjorklund"
twitter "krenholm"
