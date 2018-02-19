(function() {
  'use strict';

  angular.module('demoApp')
    .factory('crudService', CrudService);

  CrudService.$inject = ['$http', 'Auth'];

  function CrudService($http, Auth) {
    var service = {};

    service.listQueries = function(startOffset,pageSize) {
        return $http.get('/api/crud/listQueries', {
            params: {
                startOffset : startOffset,
                pageSize : pageSize
            }
        })
    };


      service.removeQuery = function(name) {
          return $http.get('/api/crud/removeQuery', {
              params: {
                  name : name
              }
          })
      };

    return service;
  }

}());
