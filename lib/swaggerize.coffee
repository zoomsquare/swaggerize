_     = require 'lodash'

spec  = require './utils'

module.exports = (_options) ->

  clean_type = (type_string) ->
    type_string = type_string.toLowerCase()
    type_map =
      'date': 'date'
      'datetime': 'date-time'
      'timestamp': 'date-time'
      'varchar': 'string'
    _.each type_map, (val, key) ->
      if type_string.indexOf(key) > -1
        type_string = val

    type_string

  type = (format) ->
    switch format
      when 'int32'
        'integer'
      when 'int64'
        'integer'
      when 'float'
        'number'
      when 'double'
        'number'
      when 'byte'
        'string'
      when 'date'
        'string'
      when 'date-time'
        'string'

  defaults =
    gen_yaml: false
    swagger:
      info:
        'title': 'User Service'
        'version': '1.0.0'
        'description': 'User Service'
        'contact':
          'name': 'Moritz'
          'email': 'moritz@zoomsquare.com'
      version: '1.0.0'
      host: 'api.example.com'
      basePath: '/v1'
      schemes: [
        'http'
      ]
      consumes: ['application/json']
      produces: ['application/json']

  generate = (sequelize, options) ->
    # default reconciliation
    options = _.defaults options or {}, _options, defaults

    # error handling incase people pass in some wack object
    sequelize = sequelize or {}
    dfm = sequelize.modelManager or {}
    daos = dfm.models or []

    swg =
      REQUIRED: 'REQUIRED'
      HIDDEN: 'HIDDEN'
      _VISIBLE: 'VISIBLE'

    spec.generate_header options.swagger

    _.each daos, (dao) ->
      dao_obj =
        post:
          required: []
          properties: {}
        get:
          required: []
          properties: {}
        put:
          required: []
          properties: {}
        delete:
          required: []
          properties: {}

      attrs = Object.keys(dao.rawAttributes).sort()


      _.each attrs, (key) ->

        val = dao.rawAttributes[key]
        format = clean_type(_.isString(val.type) and val.type or _.isObject(val.type) and val.type.toString())
        prop_visibility =
          post: swg._VISIBLE
          get: swg._VISIBLE
          put: swg._VISIBLE
          delete: swg._VISIBLE
        spec2 = Object.keys(dao.attributes[key].swaggerize or {}).reduce(((acc, k, o) ->
          acc[k.toLowerCase()] = o[k]
          acc
        ), {})

        spec2 = _.merge(prop_visibility, spec2)

        _.each Object.keys(spec2), (op) ->

          switch prop_visibility[op]
            when swg.REQUIRED
              dao_obj[op].required.push key
              dao_obj[op].properties[key] =
                type: type(format)
                format: format
            when swg._VISIBLE
              dao_obj[op].properties[key] =
                type: type(format)
                format: format
          # it's hidden. no-op
          unless dao_obj[op].properties[key].type?
            delete dao_obj[op].properties[key].type

          if dao_obj[op].required and not dao_obj[op].required.length
            delete dao_obj[op].required

      spec.generate_definition dao.name, dao_obj
      spec.generate_parameter dao.name, dao_obj
      spec.generate_path dao.name, dao.name, dao.primaryKeyField
      console.log JSON.stringify dao_obj, false, 4

    spec.get options.gen_yaml

  {generate}
