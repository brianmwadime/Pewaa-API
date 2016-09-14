# 'use strict'
cheerio     = require "cheerio"
statusCodes = require "#{__dirname}/../../config/statusCodes"
json        = {}

module.exports = class ParseResponse
  constructor: (@bodyTagName) ->

  parse: (soapResponse) ->
    XMLHeader = /<\?[\w\s=.\-'"]+\?>/gi
    soapHeaderPrefixes = /(<([\w\-]+:[\w\-]+\s)([\w=\-:"'\\\/\.]+\s?)+?>)/gi
    # Remove the XML header tag
    soapResponse = soapResponse.replace(XMLHeader, '')
    # Get the element PREFIXES from the soap wrapper
    soapInstance = soapResponse.match(soapHeaderPrefixes)
    soapPrefixes = soapInstance[0].match(/((xmlns):[\w\-]+)+/gi)

    soapPrefixes = soapPrefixes.map((prefix) -> prefix.split(':')[1].replace(/\s+/gi, ''))
    # Now clean the SOAP elements in the response
    soapPrefixes.forEach (prefix) ->
      xmlPrefixes = new RegExp(prefix + ':', 'gmi')
      soapResponse = soapResponse.replace xmlPrefixes, ''
      return

    soapResponse = soapResponse.replace /(xmlns):/gmi, ''
    # lowercase and trim before returning it
    @response = soapResponse.toLowerCase().trim()
    this

  toJSON: () ->
    # @json = {}
    $ = cheerio.load(@response, xmlMode: true)
    # Get the children tagName and its values
    $(@bodyTagName).children().each (i, el) ->
      if el.children.length == 1
        value = el.children[0].data.replace(/\s{2,}/gi, ' ')
        value = value.replace(/\n/gi, '').trim()
        # @json[el.name] = {}
        json[el.name] = value
      return
    # delete the enc_params value
    delete json.enc_params
    # Get the equivalent HTTP CODE to respond with
    
    json = Object.assign({}, @extractCode(), json)
    json

  extractCode: () ->
    statusCodes.find (sts) -> sts.return_code == parseInt(json.return_code, 10)
    return