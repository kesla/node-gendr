rest  = require 'restler'

class Checker extends process.EventEmitter
	constructor: (names, @cache) ->
		names = if names instanceof Array then names else [names]
		# Normalize all strings, first char as uppercase and the rest lowercase
		# e.g. "dAvID" -> "David"
		names = for name in names
			# Split is needed so that names like Ann-Sofie doesn't become Ann-sofie
			(for namePart in name.split("-")
				namePart[0].toUpperCase() + namePart[1..].toLowerCase()).join("-")

		@response = {}
		for name in names
			@response[name] = {length: 0} unless @response[name]?
			@response[name].length++
		# @wiki is an object used to collect intermediate results from wikipedia
		@wiki =
			en: {}
			sv: {}
		
		#Check if any name are in the cache
		uniqueNames = (name for name, data of @response)
		if @cache
			notInCache = []
			@cache.mget uniqueNames, (err, data) =>
				for i in [0...data.length]
					if(data[i]?)
						@response[uniqueNames[i]].gender = data[i]
					else
						notInCache.push uniqueNames[i]
				if notInCache.length > 0
					for name in notInCache
						@getGenderFromWikipedia(name)
				else
					@finish()
		else
			for name in uniqueNames
				@getGenderFromWikipedia(name)

	setGender: (name)->
		en = @wiki["en"][name]
		sv = @wiki["sv"][name]
		if en? and sv?
			if en is "F" and sv is "M" or en is "M" and sv is "F"
				gender = "U"
			else if en is "F" or sv is "F"
				gender = "F"
			else if en is "M" or sv is "M"
				gender = "M"
			else
				gender = "U"
		
			if @cache
				@cache.set name, gender
				@cache.expire(name, 7 * 24 * 60 * 60) if gender is "U" # Expire unknown/unisex efter a week
			@response[name].gender = gender

	finish: ->
		for name, {gender: gender} of @response
			return unless gender?
		
		@emit 'finished', @response

	getGenderFromWikipedia: (name) ->
		
		# Check english wikipedia
		enWiki = rest.get "http://en.wikipedia.org/w/api.php?action=query&titles=#{name}|#{name}%20%28name%29|#{name}%20%28given%20name%29&prop=categories&cllimit=500&format=json&redirects"
		enWiki.on 'success', (data) =>
			male = female = false
			if data.query?.pages?
				for id, data of data.query.pages
					if data.categories?
						for category in data.categories
							male = male or /(m|M)asculine given names$/.test category.title
							female = female or /(f|F)eminine given names$/.test category.title
			if male and not female
				@wiki["en"][name] = "M"
			else if female and not male
				@wiki["en"][name] = "F"
			else
				@wiki["en"][name] = "U"
			@setGender name
			@finish()

		# Check swedish wikipedia
		svWiki = rest.get "http://sv.wikipedia.org/w/api.php?action=query&titles=#{name}|#{name}%20%28namn%29|#{name}%20%28förnamn%29&prop=categories&cllimit=500&format=json&&redirects"
		svWiki.on 'success', (data) =>
			female = male = false
			if data.query?.pages?
				for id, data of data.query.pages
					if data.categories?
						for category in data.categories
							male = male or /(m|M)ansnamn$/.test category.title
							female = female or /(k|K)vinnonamn$/.test category.title
			if male and not female
				@wiki["sv"][name] = "M"
			else if female and not male
				@wiki["sv"][name] = "F"
			else
				@wiki["sv"][name] = "U"
			@setGender name
			@finish()

class Gendr
	constructor: (@cache) ->
	
	check: (names) ->
		new Checker(names, @cache, this)

exports.createClient = (cache = require('redis').createClient()) ->
	new Gendr(cache)
