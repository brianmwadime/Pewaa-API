async = require 'async'
sql = require 'sql'
BaseController = require "#{__dirname}/base"
Gift = require "#{__dirname}/../models/gift"
Payment = require "#{__dirname}/../models/payment"

class GiftsController extends BaseController
  gift: sql.define
    name: 'wishlist_items'
    columns: (new Gift).columns()

  payment: sql.define
    name: 'payments'
    columns: (new Payment).columns()

  user: sql.define
    name: 'users'
    columns: ['id', 'avatar', 'username', 'phone', 'name']

  create: (gift, callback)->
    if gift.validate()
      console.info gift
      statement = (@gift.insert gift.requiredObject()).returning '*'
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
            'creator_id': rows[0].user_id,
            'message' : 'gift added successfully.'

          callback null, gift
    else
      callback new Error "Invalid parameters"

  getOne: (key, callback)->
    statement = @gift
                .select(@payment.amount.sum().as('contributed'), @gift.star())
                .where(@gift.id.equals(key))
                .and(@payment.status.equals("Success"))
                .group(@payment.wishlist_item_id, @gift.id, @user.id)
                .from(
                  @gift
                    .join @payment
                    .on(@gift.id.equals(@payment.wishlist_item_id))
                ).limit 1
    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, rows[0]


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
    statement = @gift
                .select(@payment.wishlist_item_id, @payment.status, @payment.amount.case([@payment.status.equals('Success')],[@payment.amount.sum()],0).as('contributed'), @payment.amount.sum().as('contributed'), @gift.star(), @user.name.as('creator_name'), @user.avatar.as('creator_avatar'), @user.phone.as('creator_phone'))
                .where @gift.wishlist_id.equals(wishlist_id)
                .group(@payment.wishlist_item_id, @payment.amount, @payment.status, @gift.id, @user.id)
                .from(
                  @gift
                    .leftJoin(@payment)
                    .on(@gift.id.equals(@payment.wishlist_item_id))
                    .join(@user)
                    .on(@gift.user_id.equals(@user.id))
                )

    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, rows

module.exports = GiftsController.get()
