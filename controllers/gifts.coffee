sql             = require 'sql'
notifications   = require "#{__dirname}/../components/gcm/notifications"
BaseController  = require "#{__dirname}/base"
async           = require('async-if-else')(require('async'))
Gift            = require "#{__dirname}/../models/gift"
Wishlist        = require "#{__dirname}/../models/wishlist"
Payment         = require "#{__dirname}/../models/payment"
Contributor     = require "#{__dirname}/../models/contributor"
Push            = require "#{__dirname}/../models/push_credential"

class GiftsController extends BaseController
  gift: sql.define
    name: 'wishlist_items'
    columns: (new Gift).columns()

  wishlist: sql.define
    name: 'wishlists'
    columns: (new Wishlist).columns()

  payment: sql.define
    name: 'payments'
    columns: (new Payment).columns()

  user: sql.define
    name: 'users'
    columns: ['id', 'avatar', 'username', 'phone', 'name']

  push: sql.define
    name: 'push_credentials'
    columns: ['device_id']

  contributor: sql.define
    name: 'wishlist_contributors'
    columns: (new Contributor).columns()

  create: (gift, callback)->
    console.info gift.requiredObject()
    self = @
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
        
        self.notifyContributors gift

        callback null, gift

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
    statement = (@gift.update {is_deleted:true}).from @gift.where @gift.id.equals key
    @query statement, (err)->
      if err
        callback err
      else
        callback err, {'success': true, 'message': 'Gift removed successfully'}

  deleteForWishlist: (wishlist_id, callback)->
    statement = @gift.update({is_deleted: true})
                .where @gift.wishlist_id.equals wishlist_id
    @query statement, (err) ->
      callback err

  getForWishlist: (wishlist_id, callback)->
    statement = @gift
                # .select(@payment.wishlist_item_id, @payment.status, @payment.amount.case([@payment.status.equals('Success')],[@payment.amount.sum()],0).as('contributed'), @payment.amount.sum().as('contributed'), @gift.star(), @user.name.as('creator_name'), @user.avatar.as('creator_avatar'), @user.phone.as('creator_phone'))
                .select(@gift.star(), @user.name.as('creator_name'), @user.avatar.as('creator_avatar'), @user.phone.as('creator_phone'))
                .where(@gift.wishlist_id.equals wishlist_id)
                .and(@gift.is_deleted.equals false)
                # .group(@payment.wishlist_item_id, @payment.amount, @payment.status, @gift.id, @user.id)
                .from(
                  @gift
                    # .leftJoin(@payment)
                    # .on(@gift.id.equals(@payment.wishlist_item_id))
                    .join(@user)
                    .on(@gift.user_id.equals(@user.id))
                )

    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, rows

  notifyContributors: (gift) ->
    statement = @contributor.select(@contributor.user_id, @wishlist.name.as('wishlist_name'))
                  .where(@contributor.wishlist_id.equals(gift.wishlist_id))
                  .from(
                    @contributor
                      .join @wishlist
                      .on @contributor.wishlist_id.equals @wishlist.id
                  )

    @query statement, (err, rows)->
      console.log err, rows
      if err
        return
      else
        #callback null, rows[0].device_id
        contributorIds = []
        for own contributor, id of rows
          # if id.user_id == gift.creator_id
          #   return

          contributorIds.push(id.user_id)

        gift.contributors = contributorIds
        gift.wishlist_name = rows[0].wishlist_name
        console.log gift
        global.socketIO.sockets.emit "added_gift", gift
        return

module.exports = GiftsController.get()
