server = require('express').createServer()
util = require 'util'
checkGender = require('../lib/gendr').checkGender

server.get '/:name.json', (req, res) ->
	checkGender(req.param("name")).on 'finished', (data)->
		for gender, num of data
			if(num is 1)
				res.send {gender: gender}

server.get '/:name', (req, res) ->
	respond = (msg) ->
		res.send("<html><body><h1>#{msg}</h1></body></html>")
	name = req.param("name")
	checkGender(name).on 'finished', (data) ->
		if data["M"] is 1
			respond "I guess that #{name} is a dude."
		else if data["F"] is 1
			respond "I guess that #{name} is a dudette"
		else
			respond "I can't guess wheather #{name} is a dude or dudette. I don't know."

server.listen(3000)
