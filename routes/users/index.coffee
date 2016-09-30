'use strict'
require("#{__dirname}/../../environment")
_ 						= require 'underscore'
express 				= require 'express'
UsersController 		= require '#{__dirname}/../../controllers/users'
User 					= require '#{__dirname}/../../models/user'
apiVersion 	        	= process.env.API_VERSION

handler = (app) ->

	app.post "/v#{apiVersion}/users/join", (req, res) ->
		user = new User req.body
		if user.validate()
			UsersController.create user, (err, result)->
				if err
					res.json 
						status: 400
						error: err

				else
					# pub_user = user.publicObject()
					res.json
						status: 200
						data: result
		else
			res.json 
				status: 400
				error: "Invalid parameters."

	app.post "/v#{apiVersion}/users/verify", (req, res) ->
		UsersController.verify req.body.code, (err, result)->
			if err
				res.json 
					status: 400
					error: err

			else
				# pub_user = user.publicObject()
				res.json
					status: 200
					data: result

module.exports = handler
