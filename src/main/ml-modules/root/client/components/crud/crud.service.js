(function() {
  'use strict';

  angular.module('demoApp')
    .factory('crudService', CrudService);

  CrudService.$inject = ['$http', 'Auth'];

  function CrudService($http, Auth) {
    var service = {};

    service.listQueriesViews = function(mode,startOffset,pageSize) {
        return $http.get('/api/crud/listQueriesViews', {
            params: {
                mode : mode,
                startOffset : startOffset,
                pageSize : pageSize
            }
        })
    };

    return service;
  }

}());
