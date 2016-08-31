'use strict'
require("#{__dirname}/../../environment")
_ 						= require "underscore"
express 				= require "express"
oauthServer   			= require 'oauth2-server'
Request 				= oauthServer.Request;
Response 				= oauthServer.Response;
checkForRequiredParams 	= require "#{__dirname}/../../validators/checkForRequiredParams"
# Users
UsersController 		= require "#{__dirname}/../../controllers/users"
User 					= require "#{__dirname}/../../models/user"
WishlistsController 	= require "#{__dirname}/../../controllers/wishlists"
GiftsController 		= require "#{__dirname}/../../controllers/gifts"

Wishlist 				= require "#{__dirname}/../../models/wishlist"
Gift 					= require "#{__dirname}/../../models/gift"
authenticate 			= require "#{__dirname}/../../components/oauth/authenticate"
apiVersion 	        	= process.env.API_VERSION

handler = (app) ->

	app.post "/api/v#{apiVersion}/oauth/token", (req, res, next) ->
		response = new Response(res)
		request = new Request(req)
		#   new Request(req), new Response(res)
		app.oauth.token(request, response).then((token) ->
			res.json token
		).catch (err) ->
			res.status(500).json err

	app.post "/api/v#{apiVersion}/register", (req, res) ->
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

module.exports = handler
# module.exports = (app, router) ->
# 	# router.post '/oauth/token', app.oauth.token(), (req, res, next) ->
# 	# 	return
# 	router.post '/oauth/token', (req, res, next) ->
# 		response = new Response(res)
# 		request = new Request(req)
# 		#   new Request(req), new Response(res)
# 		app.oauth.token(request, response).then((token) ->
# 			res.json token
# 		).catch (err) ->
# 			res.status(500).json err
# 			return
# 	router.get '/', (req, res) ->
#     	res.json
#       		status: 200
#       		message: version:info.version
#     	return
# 	router.get '/wishlists', authenticate(), (req, res) ->
# 		WishlistsController.getWishlistsForUser req.user.id, (err, wishlists) ->
# 		if err
# 			res.status(400).send({error: 'error'})
# 		else
# 			res.send _.map wishlists, (w) -> (new Wishlist w).publicObject()
# 			return
# 	router.post '/wishlists', authenticate(), (req, res) ->
# 		wishlist = new Wishlist req.body
# 		wishlist.user_id = req.user.id
# 		if wishlist.validate()
# 			WishlistsController.create wishlist, (err, wishlist) ->
# 			if err
# 				res.status(400).send({error: 'error'})
# 			else
# 				res.send wishlist.publicObject()
# 		else
# 			# res.send 400, error: 'Invalid Parameters'
# 			res.status(400).send({error: 'Invalid Parameters'})
# 			return
#   	# check the status of the API system
#   	router.get '/status', authenticate(), (req, res) ->
#     	res.json status: 200
#     	return
#   	router.post '/payment/request', checkForRequiredParams, (req, res, next) ->
#     	PaymentRequest.handler req, res
#     	return
#   	router.get '/payment/confirm/:id', (req, res, next) ->
#     	ConfirmPayment.handler req, res
#     	return
#   	router.get '/payment/status/:id', (req, res, next) ->
#     	PaymentStatus.handler req, res
#     	return
#   	router.all '/payment/success', (req, res, next) ->
#     	PaymentSuccess.handler req, res
#     	return
# 	# for testing last POST response
# 	# if MERCHANT_ENDPOINT has not been provided
#   	router.all '/thumbs/up', (req, res, next) ->
#     	res.sendStatus 200
#     	return
#   	# Users
# 	router.post '/register', (req, res) ->
# 		user = new User req.body
# 		if user.validate()
# 			UsersController.create user, (err, user)->
# 				if err
# 					res.json 
# 						status: 400
# 						error: 'user already exists'
# 					return
# 				else
# 					pub_user = user.publicObject()
# 					res.json
# 						status: 200
# 						data: pub_user
# 					return
# 		else
# 			res.json 
# 				status: 400
# 				error: "Invalid parameters."
# 			return
# 	router