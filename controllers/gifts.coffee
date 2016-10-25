async = require 'async'
sql = require 'sql'
BaseController = require "#{__dirname}/base"
Gift = require "#{__dirname}/../models/gift"

class GiftsController extends BaseController
  gift: sql.define
    name: 'wishlist_items'
    columns: (new Gift).columns()

  create: (gift, callback)->
    if gift.validate()
      statement = @gift.insert gift.requiredObject()
                  .returning '*'
      @query statement, (err, rows)->
        if err
          callback err
        else
          gift =
            'success' : true,
            'id': rows[0].id,
            'wishlist_id': rows[0].wishlist_id,
            'name': rows[0].name,
            'description': rows[0].description,
            'avatar': rows[0].avatar,
            'price': rows[0].price,
            'message' : 'gift added successfully.'

          callback null, gift
    else
      callback new Error "Invalid parameters"

  getOne: (key, callback)->
    statement = @gift.select @gift.star().from @gift
              .where @gift.id.equals key
              .limit 1
    @query statement, (err, rows) ->
      if err
        callback err
      else
        callback err, new Gift rows[0]

  deleteOne: (key, callback)->
    statement = @gift.delete().from @gift.where @gift.id.equals key
    @query statement, (err)->
      callback err

  deleteForWishlist: (wishlist_id, callback)->
    statement = @gift.delete()
                .where @gift.wishlist_id.equals wishlist_id
    @query statement, (err) ->
      callback err

  getForWishlist: (wishlist_id, callback)->
    statement = @gift.select @gift.star()
                .from @gift
                .where @gift.wishlist_id.equals wishlist_id

    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, rows

module.exports = GiftsController.get()
