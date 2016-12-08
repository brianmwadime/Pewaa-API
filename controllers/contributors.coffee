BaseController  = require "#{__dirname}/base"
Contributor     = require "#{__dirname}/../models/contributor"
Gift            = require "#{__dirname}/../models/gift"
User            = require "#{__dirname}/../models/user"
Payment         = require "#{__dirname}/../models/payment"
gcm             = require('node-gcm')
sql             = require 'sql'
async           = require 'async'

class ContributorsController extends BaseController
  contributor: sql.define
    name: 'wishlist_contributors'
    columns: (new Contributor).columns()

  user: sql.define
    name: 'users'
    columns: ['id', 'avatar', 'username', 'phone', 'name']

  gift: sql.define
    name: 'wishlist_items'
    columns: (new Gift).columns()

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
                .from(@contributor)
    # @query statement, callback
    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, rows

  updatePayment: (params, callback) ->
    console.log params
    statement = (@payment.update {status:params.status})
                  .where @payment.trx_id.equals params.trx_id
    @query statement, (err)->
      console.log "update error", err
      if err
        error =
          'success' : false,
          'message' : 'Failed to update payment.'

        callback error
      else
        done =
          'success' : true,
          'message' : 'Payment updated successfully.'

        callback null, done

  getContributors: (gift_id, callback) ->
    statement = @payment
                .select(@payment.star(), @user.name, @user.avatar, @user.phone)
                .where @payment.wishlist_item_id.equals gift_id
                .where @payment.status.equals "Success"
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
        callback err, rows

  getOne: (key, callback)->
    statement = @contributor.select(@contributor.star()).from(@contributor)
      .where(@contributor.id.equals key)
    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, new Contributor rows[0]

  create: (contributor, callback)->
    sender = new (gcm.Sender)(process.env.GCM_KEY)
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

          callback null, done
    else
      callback new Error "Invalid parameters"

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


module.exports = ContributorsController.get()
