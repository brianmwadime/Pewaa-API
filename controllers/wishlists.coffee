BaseController  = require "#{__dirname}/base"
Wishlist        = require "#{__dirname}/../models/wishlist"
Contributor     = require "#{__dirname}/../models/contributor"
sql             = require 'sql'
notifications   = require "#{__dirname}/../components/gcm/notifications"
async           = require 'async'

GiftsController = require "#{__dirname}/gifts"

class WishlistsController extends BaseController
  wishlist: sql.define
    name: 'wishlists'
    columns: (new Wishlist).columns()

  userswishlists: sql.define
    name: 'wishlist_contributors'
    columns: (new Contributor).columns()

  user: sql.define
    name: 'users'
    columns: ['username', 'avatar', 'phone', 'email', 'description']

  getAll: (callback)->
    statement = @wishlist.select(@wishlist.star()).from(@wishlist)
    @query statement, callback

  getWishlistsForUser: (user_id, callback) ->
    statement = @wishlist
                .select @wishlist.star(), @userswishlists.permissions
                .where(@userswishlists.user_id.equals user_id)
                .and(@wishlist.is_deleted.equals false)
                .from(
                  @wishlist
                    .join @userswishlists
                    .on @wishlist.id.equals @userswishlists.wishlist_id
                )
    # @query statement, callback
    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, rows

  getOne: (key, callback)->
    statement = @wishlist.select(@wishlist.star()).from(@wishlist)
      .where(@wishlist.id.equals key)
    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, new Wishlist rows[0]

  create: (spec, callback)->
    console.info spec.requiredObject()
    userId = spec.userId
    if not userId
      return callback new Error 'user is required'
    t = @transaction()
    start = =>
      statementNewWishlist = (@wishlist.insert spec.requiredObject()).returning '*'
      t.query statementNewWishlist, (results) =>
        wishlist = new Wishlist results?.rows[0]
        statementNewUsersWishlist = (@userswishlists.insert {user_id:userId, wishlist_id: wishlist.id, permissions: "ADMINISTRATOR"})
        t.query statementNewUsersWishlist, ()->
          t.commit wishlist

    t.on 'begin', start
    t.on 'error', (err)->
      error =
        'success' : false,
        'message' : 'Failed to create wishlist.'

      callback error
    t.on 'commit', (wishlist)->
      done =
        'success' : true,
        'createID': wishlist.id,
        'message' : 'wishlist added successfully.'

      callback null, done
    t.on 'rollback', ->
      callback new Error "Couldn't create new wishlist"

  update: (spec, callback) ->
    wishlistId = spec.wishlistId
    if not wishlistId
      return callback new Error 'wishlist is required'

    statement = (@wishlist.update spec)
                  .where @wishlist.id.equals wishlistId
    @query statement, (err) ->
      if err
        error =
          'success' : false,
          'message' : 'Failed to update wishlist.'

        callback error
      else
        done =
          'success' : true,
          'message' : 'wishlist updated successfully.'

        callback null, done

  # deleteOne: (key, callback)->
  #   {gift} = GiftsController
  #   deleteWishlistGift = gift.delete().where(gift.wishlist_id.equals(key))
  #   deleteWishlist = @wishlist.delete().where(@wishlist.id.equals(key))
  #   deleteUsersWishlistsRows = @userswishlists.delete().where(@userswishlists.wishlist_id.equals key)
  #   t = @transaction()
  #   start = ->
  #     async.eachSeries [deleteWishlistGift, deleteUsersWishlistsRows, deleteWishlist],
  #       (s, cb)->
  #         t.query s, ()->
  #           cb()
  #       , ->
  #         t.commit()

  #   t.on 'begin', start
  #   t.on 'error', callback
  #   t.on 'commit', ->
  #     callback()
  #   t.on 'rollback', ->
  #     callback new Error "Could not delete wishlist with id #{key}"
  deleteOne: (key, callback)->
    statement = (@wishlist.update {is_deleted:true}).from @wishlist.where @wishlist.id.equals key
    @query statement, (err)->
      if err
        callback err
      else
        callback err, {'success': true, 'message': 'Wishlist removed successfully'}

  exists: (key, callback) ->
    findWishlist = @wishlist.select(@wishlist.id).where(@wishlist.id.equals(key)).limit(1)
    @query findWishlist, (err, rows) ->
      if err or rows.length isnt 1
        callback new Error "#{key} not found"
      else
        callback null, yes


module.exports = WishlistsController.get()
