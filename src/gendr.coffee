cache = require('redis').createClient()
rest  = require 'restler'

class CheckGender extends process.EventEmitter
	constructor: (@names) ->
		@response = {"M": 0, "F": 0, "U":0}
		@names = [@names] unless @names instanceof Array
		@followers = @names.length

	# Remove duplicates, going from a ["a", "b", "a"] stucture to 
	# 	{"a": 2, "b": 1} structure.
	remove_duplicates: (array) ->
		array = [array] unless array instanceof Array
		map = {}
		for key in array
			map[key] = 0 unless map[key]?
			map[key]++
		map

	createEnUri: (name) ->
		"http://en.wikipedia.org/w/api.php?action=query&titles=#{name}|#{name}%20%28name%29|#{name}%20%28given%20name%29&prop=categories&cllimit=500&format=json&redirects"

	createSvUri: (name) ->
		"http://sv.wikipedia.org/w/api.php?action=query&titles=#{name}|#{name}%20%28namn%29|#{name}%20%28förnamn%29&prop=categories&cllimit=500&format=json&&redirects"

	setGender: (female, male, length, name)->
		if (male and not female)
			gender = "M"
		else if (female and not male)
			gender = "F"
		else
			gender = "U"
		cache.set name, gender
		@response[gender] += length


	finish: ->
		sum = 0
		sum += count for gender, count of @response
			
		if sum >= @followers
			@emit 'finished', @response

	checkGender: (name, length) ->
		cache.get name, (err, gender) =>
			if gender?
				@response[gender] += length
				@finish()
			else
				uri = @createEnUri name
				female = male = false
				get = rest.get uri
				get.on 'success', (data) =>
					if data.query?.pages?
						for id, data of data.query.pages
							if data.categories?
								for category in data.categories
									if /(m|M)asculine given names$/.test category.title
										male = true
									if /(f|F)eminine given names$/.test category.title
										female = true
					if (not male and not female)
						uri = @createSvUri name
						get = rest.get(uri)
						get.on 'success', (data) =>
							if data.query?.pages?
								for id, data of data.query.pages
									if data.categories?
										for category in data.categories
											if /(m|M)ansnamn$/.test category.title
												male = true
											if /(k|K)vinnonamn$/.test category.title
												female = true
							@setGender(female, male, length, name)
							@finish()
					else
						@setGender(female, male, length, name)
						@finish()
	run: () ->
		for name, length of @remove_duplicates(@names)
			@checkGender(name, length)
		return this

	
exports.check = (names) ->
	new CheckGender(names).run()
