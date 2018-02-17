'use strict';

angular.module('demoApp')
  .controller('CrudCtrl', function ($window,$scope, $http, $sce, $interval, crudService) {

      $scope.PAGE_SIZE = 10;

      $scope.pageCount = 1;
      $scope.currentPage = 1;


      $scope.startOffset = 1;
      $scope.results = [];
      $scope.mode = "Queries";
      $scope.totalCount = 0;
      $scope.genericError = "";
      $scope.$watch('currentPage', function(page){
          $scope.load()
      });

      $scope.removeQueryView=function(name,ev) {
          var t = $scope.mode == "Queries" ? "query" : "view"
          if (confirm('Do you want to remove ' + t + '' + name + '?')) {
              crudService.removeQueryView($scope.mode, name)
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



      $scope.switchMode=function(mode){
          $scope.currentPage = 1;
          $scope.mode = mode;
          $scope.load()
      }

      $scope.load=function() {
          $scope.loadError = '';
          var offset = (($scope.currentPage-1) * $scope.PAGE_SIZE)+1
          crudService.listQueriesViews($scope.mode,offset,$scope.PAGE_SIZE)
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
      $scope.switchMode("Queries");
    }
  );