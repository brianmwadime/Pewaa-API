'use strict'
require("#{__dirname}/../../environment")
_ 						= require 'underscore'
express 				= require 'express'
oauthServer   			= require 'oauth2-server'
Request 				= oauthServer.Request;
Response 				= oauthServer.Response;
checkForRequiredParams 	= require '#{__dirname}/../../validators/checkForRequiredParams'
AdminsController 		= require '#{__dirname}/../../controllers/admins'
Admin 					= require '#{__dirname}/../../models/admin'
WishlistsController 	= require '#{__dirname}/../../controllers/wishlists'
GiftsController 		= require '#{__dirname}/../../controllers/gifts'

Wishlist 				= require '#{__dirname}/../../models/wishlist'
Gift 					= require '#{__dirname}/../../models/gift'
authenticate 			= require '#{__dirname}/../../components/oauth/authenticate'
apiVersion 	        	= process.env.API_VERSION

handler = (app) ->

	app.post "/v#{apiVersion}/oauth/token", (req, res, next) ->
		response = new Response(res)
		request = new Request(req)
		#   new Request(req), new Response(res)
		app.oauth.token(request, response).then((token) ->
			res.json token
		).catch (err) ->
			res.status(500).json err

	app.post "/v#{apiVersion}/register", (req, res) ->
		admin = new Admin req.body
		if admin.validate()
			AdminsController.create admin, (err, admin)->
				if err
					res.json 
						status: 400
						error: 'admin already exists'

				else
					pub_admin = admin.publicObject()
					res.json
						status: 200
						data: pub_admin
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
# 		WishlistsController.getWishlistsForAdmin req.admin.id, (err, wishlists) ->
# 		if err
# 			res.status(400).send({error: 'error'})
# 		else
# 			res.send _.map wishlists, (w) -> (new Wishlist w).publicObject()
# 			return
# 	router.post '/wishlists', authenticate(), (req, res) ->
# 		wishlist = new Wishlist req.body
# 		wishlist.admin_id = req.admin.id
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
#   	# Admins
# 	router.post '/register', (req, res) ->
# 		admin = new Admin req.body
# 		if admin.validate()
# 			AdminsController.create admin, (err, admin)->
# 				if err
# 					res.json 
# 						status: 400
# 						error: 'admin already exists'
# 					return
# 				else
# 					pub_admin = admin.publicObject()
# 					res.json
# 						status: 200
# 						data: pub_admin
# 					return
# 		else
# 			res.json 
# 				status: 400
# 				error: "Invalid parameters."
# 			return
# 	router