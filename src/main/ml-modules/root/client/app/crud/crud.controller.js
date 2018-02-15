'use strict';

angular.module('demoApp')
  .controller('CrudCtrl', function ($scope, $http, $sce, $interval, crudService) {

      $scope.PAGE_SIZE = 10;

      $scope.pageCount = 1;
      $scope.currentPage = 1;


      $scope.startOffset = 1;
      $scope.results = [];
      $scope.mode = "queries";
      $scope.totalCount = 0;

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
          console.log(offset);
          crudService.listQueriesViews($scope.mode,offset,$scope.PAGE_SIZE)
              .success(function(data, status) {
                  if (status == 200) {
                      console.log(data);
                      $scope.totalCount = data['result-count']
                      $scope.results = data['rows']
                      $scope.pageCount = Math.ceil( $scope.totalCount / $scope.PAGE_SIZE)
                      console.log($scope.pageCount)
                  }
              }).error(function(err){
              // TODO
              console.log(err);
          });
      }
      $scope.switchMode("queries");
    }
  );