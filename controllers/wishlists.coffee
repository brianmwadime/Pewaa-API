BaseController = require "#{__dirname}/base"
Wishlist = require "#{__dirname}/../models/wishlist"
sql = require 'sql'
async = require 'async'

GiftsController = require "#{__dirname}/gifts"

class WishlistsController extends BaseController
  wishlist: sql.define
    name: 'wishlists'
    columns: (new Wishlist).columns()

  userswishlists: sql.define
    name: 'wishlist_contributors'
    columns: ['user_id', 'wishlist_id', 'permissions']

  getAll: (callback)->
    statement = @wishlist.select(@wishlist.star()).from(@wishlist)
    @query statement, callback

  getWishlistsForUser: (user_id, callback) ->
    statement = @wishlist
                .select @wishlist.star() #, @userswishlists.star()
                .where(@userswishlists.user_id.equals user_id)
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
      callback err
    t.on 'commit', (wishlist)->
      callback null, wishlist
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

  deleteOne: (key, callback)->
    {gift} = GiftsController
    deleteWishlistGift = gift.delete().where(gift.wishlist_id.equals(key))
    deleteWishlist = @wishlist.delete().where(@wishlist.id.equals(key))
    deleteUsersWishlistsRows = @userswishlists.delete().where(@userswishlists.wishlist_id.equals key)
    t = @transaction()
    start = ->
      async.eachSeries [deleteWishlistGift, deleteUsersWishlistsRows, deleteWishlist],
        (s, cb)->
          t.query s, ()->
            cb()
        , ->
          t.commit()

    t.on 'begin', start
    t.on 'error', callback
    t.on 'commit', ->
      callback()
    t.on 'rollback', ->
      callback new Error "Could not delete wishlist with id #{key}"

  exists: (key, callback) ->
    findWishlist = @wishlist.select(@wishlist.id).where(@wishlist.id.equals(key)).limit(1)
    @query findWishlist, (err, rows) ->
      if err or rows.length isnt 1
        callback new Error "#{key} not found"
      else
        callback null, yes


module.exports = WishlistsController.get()
