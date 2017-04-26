sql             = require 'sql'
BaseController  = require "#{__dirname}/base"
async           = require('async-if-else')(require('async'))
Gift            = require "#{__dirname}/../models/gift"
Wishlist        = require "#{__dirname}/../models/wishlist"
Payment         = require "#{__dirname}/../models/payment"
Contributor     = require "#{__dirname}/../models/contributor"
Push            = require "#{__dirname}/../models/push_credential"
GcmNotifications= require "#{__dirname}/../components/gcm/notifications"

class GiftsController extends BaseController
  gift: sql.define
    name: 'wishlist_items'
    columns: (new Gift).columns()

  contributor: sql.define
    name: 'wishlist_contributors'
    columns: (new Contributor).columns()

  wishlist: sql.define
    name: 'wishlists'
    columns: (new Wishlist).columns()

  push: sql.define
    name: 'push_credentials'
    columns: (new Push).columns()

  payment: sql.define
    name: 'payments'
    columns: (new Payment).columns()

  user: sql.define
    name: 'users'
    columns: ['id', 'avatar', 'username', 'phone', 'name']

  create: (gift, callback)->
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
    statement = @gift.select @gift.star().from @gift
              .where @gift.id.equals key
              .limit 1
    @query statement, (err, rows) ->
      if err
        callback err
      else
        callback null, new Gift rows[0]

  deleteOne: (key, callback)->
    statement = (@gift.update {is_deleted:true}).from @gift.where @gift.id.equals key
    @query statement, (err)->
      if err
        callback err
      else
        callback null, {'success': true, 'message': 'Gift removed successfully.'}

  deleteForWishlist: (wishlist_id, callback)->
    statement = @gift.update({is_deleted: true})
                .where @gift.wishlist_id.equals wishlist_id
    @query statement, (err) ->
      callback err

  cashoutRequest: (params, callback) ->
    statement = @gift.update({cashout_status: 'PENDING'})
                .where(@gift.id.equals params.gift_id)
                .and(@gift.user_id.equals params.user_id)
                .and(@gift.is_deleted.equals false)
    @query statement, (err)->
      if err
        callback err
      else
        cashout_request =
          'success' : true,
          'gift'    : {id: params.gift_id, name: params.gift_name, amount: params.gift_amount}
          'message' : 'Your cashout request has been acknowledged and is pending approval.'

        self.notify params.user_id, "cashout_request", cashout_request
        callback null, {'success': true, 'message': 'Your cashout request has been acknowledged and is pending approval.'}

  getForWishlist: (wishlist_id, callback)->
    statement = @gift
                # .select(@payment.wishlist_item_id, @payment.status, @payment.amount.case([@payment.status.equals('Success')],[@payment.amount.sum()],0).as('contributed'), @payment.amount.sum().as('contributed'), @gift.star(), @user.name.as('creator_name'), @user.avatar.as('creator_avatar'), @user.phone.as('creator_phone'))
                .select(@gift.id, @payment.amount.sum().as('total_contribution'), @gift.name, @gift.avatar, @gift.price, @gift.description, @gift.code, @user.name.as('creator_name'), @user.avatar.as('creator_avatar'), @user.phone.as('creator_phone'))
                .where(@gift.wishlist_id.equals wishlist_id)
                .and(@gift.is_deleted.equals false)
                .and @payment.status.equals "Success"
                .group(@payment.wishlist_item_id, @user.name, @user.avatar, @user.phone, @gift.id)
                .from(
                  @gift
                    .join @user
                    .on @gift.user_id.equals @user.id
                    .leftJoin @payment
                    .on @gift.id.equals @payment.wishlist_item_id
                )

    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, rows

  notifyContributors: (gift) ->
    self = @
    statement = @contributor.select(@contributor.user_id, @wishlist.name.as('wishlist_name'), @wishlist.id.as('wishlist_id'))
                  .where(@contributor.wishlist_id.equals gift.wishlist_id)
                  .and(@contributor.is_deleted.equals false)
                  .from(
                    @contributor
                      .join @wishlist
                      .on @contributor.wishlist_id.equals @wishlist.id
                  )

    @query statement, (err, rows)->
      if err
        return
      else
        gift.wishlist_name = rows[0].wishlist_name
        gift.wishlist_id = rows[0].wishlist_id
        for own contributor, id of rows
          if id.user_id == gift.creator_id
            return
          gift.wishlist_permissions = rows[0].permissions
          self.notify id.user_id, "added_gift", gift

        return
 
  ######## Notification functions ################
  notify: (user_id, message, data) ->
    self = @
    statement = @push.select(@push.device_id)
                  .where @push.user_id.equals(user_id)

    @query statement, (err, rows)->
      if err
        console.info err
        return
      else
        deviceIds = []
        for own device, id of rows
          deviceIds.push(id.device_id)
        self.sendNotification deviceIds, message, data
        return

  sendNotification: (device_ids, message, data) ->
    sender = new GcmNotifications(process.env.GCM_KEY)
    sender.sendMessage message, data, device_ids
    return

module.exports = GiftsController.get()
