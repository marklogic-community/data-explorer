'use strict';

angular.module('demoApp')
  .factory('User', function ($resource) {
    return $resource('/api/users/:id', {
      id: '@_id'
    },
    {
      changePassword: {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}
      },
      get: {
        method: 'GET',
        params: {
          id:'me'
        }
      }
	  });
  });
