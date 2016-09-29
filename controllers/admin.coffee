BaseController = require "#{__dirname}/base"
sql = require 'sql'
async = require 'async'
Admin = require "#{__dirname}/../models/admin"

class AdminsController extends BaseController

  admin: sql.define
    name: 'admins'
    columns: (new Admin).columns()

  getAll: (callback)->
    statement = @admin.select(@admin.star()).from(@admin)
    @query statement, callback

  getOne: (key, callback)->
    statement = @admin.select(@admin.star()).from(@admin)
      .where(@admin.id.equals key)
    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, new Admin rows[0]

  create: (adminParam, callback)->
    statement = (@admin.insert adminParam.requiredObject()).returning '*'
    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, new Admin rows[0]

#   deleteOne: (key, callback)->
#     t = @transaction()
#     deleteAdmin = @admin.delete()
#       .where @admin.id.equals key
#     deleteAdminCredentials = AdminCredentialsController.deleteSql key
#     start = ->
#       async.eachSeries [deleteAdminCredentials, deleteAdmin],
#         (s, cb)->
#           t.query s, () ->
#             cb()
#         , ->
#           t.commit()

#     t.on 'begin', start
#     t.on 'error', console.log
#     t.on 'commit', ->
#       callback()
#     t.on 'rollback', ->
#       callback new Error "Could not delete admin with id #{key}"


module.exports = AdminsController.get()