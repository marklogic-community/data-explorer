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
      service.removeView = function(queryName,docType,viewName) {
          return $http.get('/api/crud/removeView', {
              params: {
                  queryName : encodeURIComponent(queryName),
                  docType : encodeURIComponent(docType),
                  viewName : encodeURIComponent(viewName)
              }
          })
      };

      service.listViews = function(queryName,docType,startOffset,pageSize) {
          return $http.get('/api/crud/listViews', {
              params: {
                  queryName : encodeURIComponent(queryName),
                  docType : encodeURIComponent(docType),
                  startOffset : encodeURIComponent(startOffset),
                  pageSize : pageSize
              }
          })
      };

      service.removeQuery = function(queryName,docType) {
          return $http.get('/api/crud/removeQuery', {
              params: {
                  queryName : encodeURIComponent(queryName),
                  docType : encodeURIComponent(docType)
              }
          })
      };

    return service;
  }

}());
