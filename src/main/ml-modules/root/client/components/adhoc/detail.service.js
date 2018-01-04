'use strict';

angular.module('demoApp')
  .factory('Detail', function ($resource) {
    return $resource('/api/detail/:database/:uri', {
      database: '@_database',
      uri: '@_uri'
    },
    {
      get: {
        method: 'GET'
      }
	  });
  });
