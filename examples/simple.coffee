util = require 'util'
gendr = require('../lib/gendr').createClient(false)

names = ["David", "Lisa", "Fubar", "Joakim", "Sophia", "Magdalena", "Kim", "Unkown", "Clas", "Patrick", "Elvis", "Barack", "Robyn"].sort()
gendr.check(names).on 'finished', (data) ->
	util.log util.inspect data
