BaseController  = require "#{__dirname}/base"
Contributor     = require "#{__dirname}/../models/contributor"
Gift            = require "#{__dirname}/../models/gift"
User            = require "#{__dirname}/../models/user"
Payment         = require "#{__dirname}/../models/payment"
Wishlist        = require "#{__dirname}/../models/wishlist"
Push            = require "#{__dirname}/../models/push_credential"
notifications   = require "#{__dirname}/../components/gcm/notifications"
GcmNotifications= require "#{__dirname}/../components/gcm/notifications"
sql             = require 'sql'
async           = require 'async'

class ContributorsController extends BaseController
  contributor: sql.define
    name: 'wishlist_contributors'
    columns: (new Contributor).columns()

  user: sql.define
    name: 'users'
    columns: ['id', 'avatar', 'username', 'phone', 'name']

  wishlist: sql.define
    name: 'wishlists'
    columns: (new Wishlist).columns()

  gift: sql.define
    name: 'wishlist_items'
    columns: (new Gift).columns()

  push: sql.define
    name: 'push_credentials'
    columns: (new Push).columns()

  payment: sql.define
    name: 'payments'
    columns: (new Payment).columns()

  getAll: (callback)->
    statement = @contributor.select(@contributor.star()).from(@contributor)
    @query statement, callback

  getWishlistContributors: (wishlist_id, callback) ->
    statement = @contributor
                .select @contributor.star() #, @userswishlists.star()
                .where(@contributor.wishlist_id.equals wishlist_id)
                .and(@contributor.is_deleted.equals false)
                .from(@contributor)
    # @query statement, callback
    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, rows

  updatePayment: (params, callback) ->
    self = @
    statement = (@payment.update {status:params.status})
                  .where @payment.trx_id.equals params.trx_id
    @query statement, (err)->
      if err
        error =
          'success' : false,
          'message' : 'Failed to update payment.',
          'error'   : err

        callback error
      else
        done =
          'success' : true,
          'message' : 'Payment updated successfully.'
        
        self.notifyOfPayment params

        callback null, done

  getContributors: (gift_id, callback) ->
    statement = @payment
                .select(@payment.star(), @user.name, @user.avatar, @user.phone)
                .where @payment.wishlist_item_id.equals(gift_id)
                .and(@payment.status.equals("Success"))
                .from(
                  @payment
                    .join @user
                    .on @payment.user_id.equals @user.id
                )
    # @query statement, callback
    @query statement, (err, rows)->
      if err
        callback err
      else
        callback null, rows

  getOne: (key, callback)->
    statement = @contributor.select(@contributor.star()).from(@contributor)
      .where(@contributor.id.equals key)
    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, new Contributor rows[0]

  create: (contributor, callback)->
    self = @
    sender = new GcmNotifications(process.env.GCM_KEY)
    if contributor.validate()
      statement = @contributor.insert contributor.requiredObject()
                  .returning '*'
      @query statement, (err, rows)->
        if err
          error =
            'success': false,
            'message': "Could not add Contributor to Wishlist."
          callback error
        else
          done =
            'success' : true,
            'id': rows[0].id,
            'wishlist_id': rows[0].wishlist_id,
            'user_id': rows[0].user_id,
            'permissions': rows[0].permissions,
            'message' : 'contributor added successfully.'

          self.notifyContributors done

          callback null, done
    else
      callback new Error "Invalid parameters"

  addContributors: (params, callback) ->
    results = []
    self = @
    async.each params.contributors, ((contributor, callback) ->
      # Call an asynchronous function, often a save() to DB
      statement = self.contributor.insert (new Contributor {user_id:contributor, wishlist_id: params.wishlist, permissions: "CONTRIBUTOR", is_deleted: false}).requiredObject()
                  .returning '*'

      self.query statement, (err, rows) ->
        if rows
          done =
            'success' : true,
            'id': rows[0].id,
            'wishlist_id': rows[0].wishlist_id,
            'user_id': rows[0].user_id,
            'permissions': rows[0].permissions,
            'message' : 'contributor added successfully.'

          self.notifyContributors done

          results.push done

        callback null, results

    ), (err) ->
      if err
        callback err
      else
        callback null, {success: true, id: params.wishlist}

  update: (spec, callback) ->
    contributorId = spec.contributorId
    if not contributorId
      return callback new Error 'wishlist is required'

    statement = (@contributor.update spec)
                  .where @contributor.id.equals contributorId
    @query statement, (err) ->
      if err
        error =
          'success' : false,
          'message' : 'Failed to update contributor.'

        callback error
      else
        done =
          'success' : true,
          'message' : 'contributor updated successfully.'

        callback null, done

  exists: (key, callback) ->
    findContributor = @contributor.select(@contributor.id).where(@contributor.id.equals(key)).limit(1)
    @query findContributor, (err, rows) ->
      if err or rows.length isnt 1
        callback new Error "#{key} not found"
      else
        callback null, yes

  deleteOne: (key, callback)->
    statement = (@contributor.update {is_deleted:true}).from @contributor.where @contributor.id.equals key
    @query statement, (err)->
      if err
        callback err
      else
        done =
          'success': true
          'message': 'Contributor removed successfully'
        
        callback err, done

  deleteContributor: (params, callback) ->
    statement = (@contributor.update {is_deleted:true}).
                      where(@contributor.user_id.equals params.contributor_id)
                      .and(@contributor.wishlist_id.equals params.wishlist_id)
    @query statement, (err) ->
      if err
        result =
          'success' : false
          'message' : "Could not delete account. Please try again.",
          'error'   : err
        callback result
      else
        result =
          'success' : true
          'message' : 'Your account is deleted successfully.'
        callback null, result

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

  notifyContributors: (wishlist) ->
    statement = @wishlist.select(@wishlist.star())
                  .where(@wishlist.id.equals(wishlist.wishlist_id))
                  .limit 1

    @query statement, (err, rows)->
      if err or rows.length isnt 1
        return
      else
        wishlist.wishlist = rows[0]
        self.notify wishlist.user_id, "added_contributor", wishlist
        # global.socketIO.sockets.emit "added_contributor", wishlist
        return

  notifyOfPayment: (params) ->
    self = @
    statement = @payment.select(@payment.amount, @payment.status, @gift.star(), @user.name.as('creator_name'), @user.avatar.as('creator_avatar'), @user.phone.as('creator_phone'))
                  .where(@payment.trx_id.equals(params.trx_id))
                  .from(
                    @payment
                      .join @gift
                      .on @payment.wishlist_item_id.equals @gift.id
                      .join(@user)
                      .on(@gift.user_id.equals(@user.id))
                  )
                  .limit 1

    @query statement, (err, rows)->
      if err or rows.length isnt 1
        return
      else
        payment = rows[0]
        # global.socketIO.sockets.emit "payment_completed", payment
        self.notify payment.user_id, "payment_completed", payment 
        return

module.exports = ContributorsController.get()
