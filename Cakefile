{exec, spawn} = require('child_process')

task 'dev', 'Continous compile gendr Coffeescript source and examples to javascript', ->
	coffee1 = spawn 'coffee', '-w -c -b -o lib src'.split(' ')
	coffee1.stdout.on 'data', (data) -> console.log data.toString()
	coffee1.stderr.on 'data', (data) -> console.log data.toString()
	
	coffee2 = spawn 'coffee', '-w -c -b examples'.split(' ')
	coffee2.stdout.on 'data', (data) -> console.log data.toString()
	coffee2.stderr.on 'data', (data) -> console.log data.toString()
