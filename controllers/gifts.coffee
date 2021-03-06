sql             = require 'sql'
BaseController  = require "#{__dirname}/base"
async           = require('async-if-else')(require('async'))
Gift            = require "#{__dirname}/../models/gift"
Wishlist        = require "#{__dirname}/../models/wishlist"
Payment         = require "#{__dirname}/../models/payment"
Contributor     = require "#{__dirname}/../models/contributor"
Push            = require "#{__dirname}/../models/push_credential"
GcmNotifications= require "#{__dirname}/../components/gcm/notifications"
SendGrid        = require "#{__dirname}/../components/sendgrid"

class GiftsController extends BaseController

  sql.setDialect('postgres')

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
    statement = (@gift.update {is_deleted:true})
                .where @gift.id.equals key
                .returning '*'
    @query statement, (err)->
      if err
        callback err
      else
        gift =
          'success': true,
          'gift': rows[0]

        callback null, gift

  deleteForWishlist: (wishlist_id, callback)->
    statement = @gift.update({is_deleted: true})
                .where @gift.wishlist_id.equals wishlist_id
                .returning '*'
    @query statement, (err, rows) ->
      if err
        callback err
      else
        gift =
          'success': true,
          'gift': rows[0]

        callback null, gift

  cashoutRequest: (params, callback) ->
    self = @
    statement = (@gift.update {cashout_status: 'PENDING'})
                .where @gift.id.equals params.gift_id
                .and @gift.user_id.equals params.user_id
                .and @gift.is_deleted.equals false
                .returning '*'
    
    @query statement, (err, rows)->
      if err
        callback {success: false, message: "Could not complete your cashout request. Please contact Pewaa! support <info@pewaa.com>", err: api}
      else
        cashout_request =
          success : true,
          gift    : rows[0]
          message : 'Your cash out request for ' + rows[0].name + ' has been acknowledged and is pending approval.'

        self.notify params.user_id, "cashout_request", cashout_request

        gift =
          'success' : true,
          'id': rows[0].id,
          'wishlist_id': rows[0].wishlist_id,
          'name': rows[0].name,
          'description': rows[0].description,
          'avatar': rows[0].avatar,
          'price': rows[0].price,
          'creator_id': rows[0].user_id,
          'cashout_status': rows[0].cashout_status,
          'updated_on': rows[0].updated_on,
          'created_on': rows[0].created_on,
          'message' : 'Your cashout request has been acknowledged and is pending approval.'

        callback null, gift

  getForWishlist: (wishlist_id, callback)->
    # statement = @gift
    #             .select(@gift.star(), @payment.count().as('contributor_count'), @payment.amount.sum().as('total_contribution'), @user.name.as('creator_name'), @user.avatar.as('creator_avatar'), @user.phone.as('creator_phone'))
    #             .from(
    #               @gift
    #                 .join @user
    #                 .on @gift.user_id.equals(@user.id)
    #                 .leftJoin @payment
    #                 .on(@gift.id.equals(@payment.wishlist_item_id) and @payment.status.equals("Success"))
                    
    #             )
    #             .where(@gift.wishlist_id.equals wishlist_id)
    #             .and(@gift.is_deleted.equals false)
    #             .group(@payment.wishlist_item_id, @user.name, @user.avatar, @user.phone, @gift.id)

    statement = "SELECT wishlist_items.*, SUM(payments.amount) AS contribution_total, COUNT(payments.id) AS contributor_count, users.name AS creator_name, users.avatar AS creator_avatar, users.phone AS creator_phone FROM wishlist_items JOIN users ON wishlist_items.user_id = users.id LEFT JOIN payments ON wishlist_items.id = payments.wishlist_item_id AND payments.status = 'Success' WHERE wishlist_items.wishlist_id = '#{wishlist_id}' AND wishlist_items.is_deleted IS FALSE AND wishlist_items.flagged IS FALSE GROUP BY wishlist_items.id, users.name, users.avatar, users.phone, payments.wishlist_item_id;"

    @query statement, (err, rows)->
      if err
        callback err
      else
        callback null, rows

  report: (params, callback) ->
    self = @
    statement = (@gift.update params)
                  .where @gift.id.equals params.id
                  .returning '*'
    @query statement, (err, rows) ->
      if err
        error =
          'success' : false,
          'message' : 'Failed to report gift.'

        callback error
      else
        done =
          'success' : true,
          'message' : 'gift reported successfully.'
        
        self.sendEmail 'no-reply@pewaa.com', 'report@pewaa.com', 'Flagged Gift item ID: ' + rows[0].id + ' Name: '  + rows[0].name, "The following item has been flagged with description: " + if rows[0].flagged_description then rows[0].flagged_description else 'N/A'
        callback null, done

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

  sendEmail: (from, to, subject, content) ->
    sender = new SendGrid()
    sender.sendEmail from, to, subject, content
    return

module.exports = GiftsController.get()
