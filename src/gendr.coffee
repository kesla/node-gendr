rest  = require 'restler'

class Checker extends process.EventEmitter
	constructor: (names, @cache) ->
		names = [names] unless names instanceof Array
		@response =
			"M": 0
			"F": 0
			"U": 0
		@followers = names.length
		
		#Check if names are in cache
		notInCache = []

		if @cache
			@cache.mget names, (err, data) =>
				for i in [0...data.length]
					if(data[i]?)
						@response[data[i]]++
					else
						notInCache.push names[i]
				if notInCache.length > 0
					for name, length of @remove_duplicates(notInCache)
						@getGenderFromWikipedia(name, length)
				else
					@finish()
		else
			for name, length of @remove_duplicates(names)
				@getGenderFromWikipedia(name, length)

	remove_duplicates: (array) ->
		array = [array] unless array instanceof Array
		map = {}
		for key in array
			map[key] = 0 unless map[key]?
			map[key]++
		map


	setGender: (female, male, length, name)->
		if (male and not female)
			gender = "M"
		else if (female and not male)
			gender = "F"
		else
			gender = "U"
		if @cache
			@cache.set name, gender
			@cache.expire(name, 7 * 24 * 60 * 60) if gender is "U" # Expire unknown/unisex efter a week
		@response[gender] += length


	finish: ->
		sum = 0
		sum += count for gender, count of @response
		
		if sum >= @followers
			@emit 'finished', @response

	getGenderFromWikipedia: (name, length) ->
		# Check english wikipedia
		uri = "http://en.wikipedia.org/w/api.php?action=query&titles=#{name}|#{name}%20%28name%29|#{name}%20%28given%20name%29&prop=categories&cllimit=500&format=json&redirects"
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
				# Check swedish wikipedia
				uri = "http://sv.wikipedia.org/w/api.php?action=query&titles=#{name}|#{name}%20%28namn%29|#{name}%20%28förnamn%29&prop=categories&cllimit=500&format=json&&redirects"
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

class Gendr
	constructor: (@cache) ->
	
	check: (names) ->
		new Checker(names, @cache, this)

exports.createClient = (cache = require('redis').createClient()) ->
	new Gendr(cache)
