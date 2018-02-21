'use strict';

angular.module('demoApp')
    .filter('tohex', function () {
        return function (item) {
            var r = "";
            for (var i=0; i<item.length; i++) {
                var hex = item.charCodeAt(i).toString(16);
                r += ("000"+hex).slice(-4);
            }
            return r
        };
    })

  .controller('CrudCtrl', function ($window,$scope, $http, $sce, $interval, crudService) {

      $scope.PAGE_SIZE = 10;

      $scope.pageCount = 1;
      $scope.currentPage = 1;

      $scope.displayViews = false;
      $scope.views = [];

      $scope.startOffset = 1;
      $scope.results = [];
      $scope.totalCount = 0;
      $scope.genericError = "";
      $scope.selectedQueryName = ""
      $scope.selectedDocType = ""

      $scope.$watch('currentPage', function(page){
          $scope.load()
      });

      $scope.showViews=function(queryName,docType,event) {
         $scope.displayViews = true;
         $scope.selectedQueryName = queryName
         $scope.selectedDocType = docType
      }

      $scope.removeQuery=function(name,docType,ev) {
          if (confirm('Do you want to remove query '+ name + '?')) {
              crudService.removeQuery(name,docType)
                  .success(function (data, status) {
                      if (status == 200) {
                          $scope.genericError = "";
                          $scope.load()
                      }
                  }).error(function (err) {
                  $scope.load()
                  $scope.genericError = "Error during removing " + $scope.mode + ". An error occurred. check the log.";
              });
          } else {
              $scope.genericError = ""
          }
      }

      $scope.load=function() {
          $scope.loadError = '';
          var offset = (($scope.currentPage-1) * $scope.PAGE_SIZE)+1
          crudService.listQueries(offset,$scope.PAGE_SIZE)
              .success(function(data, status) {
                  if (status == 200) {
                      $scope.totalCount = data['result-count']
                      $scope.results = data['rows']
                      $scope.pageCount = Math.ceil( $scope.totalCount / $scope.PAGE_SIZE)
                  }
              }).error(function(err){
                  $scope.results = []
                  $scope.loadError = "An server error occurred. Check the log.";
          });
      }

      $scope.load()
    }
  );