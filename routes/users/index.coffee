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
			UsersController.create user, (err, user)->
				if err
					res.json 
						status: 400
						error: 'user already exists'

				else
					pub_user = user.publicObject()
					res.json
						status: 200
						data: pub_user
		else
			res.json 
				status: 400
				error: "Invalid parameters."

	app.post "/v#{apiVersion}/users/verify/:code", (req, res) ->
		UsersController.verify req.params.id, (err, user)->
			if err
				res.json 
					status: 400
					error: 'Invalid code'

			else
				pub_user = user.publicObject()
				res.json
					status: 200
					data: pub_user

module.exports = handler
