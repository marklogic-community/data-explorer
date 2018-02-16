'use strict';

angular.module('demoApp')
  .controller('CrudCtrl', function ($scope, $http, $sce, $interval, crudService) {

      $scope.PAGE_SIZE = 10;

      $scope.pageCount = 1;
      $scope.currentPage = 1;


      $scope.startOffset = 1;
      $scope.results = [];
      $scope.mode = "Queries";
      $scope.totalCount = 0;
      $scope.message = "";
      $scope.$watch('currentPage', function(page){
          $scope.load()
      });

      $scope.switchMode=function(mode){
          $scope.currentPage = 1;
          $scope.mode = mode;
          $scope.load()
      }

      $scope.load=function() {
          var offset = (($scope.currentPage-1) * $scope.PAGE_SIZE)+1
          crudService.listQueriesViews($scope.mode,offset,$scope.PAGE_SIZE)
              .success(function(data, status) {
                  if (status == 200) {
                      $scope.message = '';
                      $scope.totalCount = data['result-count']
                      $scope.results = data['rows']
                      $scope.pageCount = Math.ceil( $scope.totalCount / $scope.PAGE_SIZE)
                  }
              }).error(function(err){
                  $scope.results = []
                  $scope.message = "An server error occurred. Check the log/";
          });
      }
      $scope.switchMode("Queries");
    }
  );