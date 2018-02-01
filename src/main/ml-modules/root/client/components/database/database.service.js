(function() {
  'use strict';

  angular.module('demoApp')
    .factory('databaseService', DatabaseService);

  DatabaseService.$inject = ['$http', 'Auth'];

  function DatabaseService($http, Auth) {
    var service = {};

    service.list = function() {
      return $http.get('/api/adhoc')
      .then(function(response) {
        if (response.status === 200 && _.isArray(response.data)) {
          return response.data;
        }
        else if (response.status === 401) {
          console.log('Not logged in.  Unable to list databases.');
          Auth.logout();
        }
        return [];
      });
    };

    return service;
  }

}());
