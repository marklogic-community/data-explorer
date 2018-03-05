'use strict';

angular.module('demoApp')
    .filter('tohex', function () {
        return function (item) {
            if ( !item )
                return "";
            var r = "";
            for (var i=0; i<item.length; i++) {
                var hex = item.charCodeAt(i).toString(16);
                r += ("000"+hex).slice(-4);
            }
            return r
        };
    })

  .controller('CrudCtrl', function ($state,$window,$scope, $http, $sce, $interval, crudService) {

      // how big are the pages?
      $scope.PAGE_SIZE = 10;

      // List query parameters
      $scope.queryCurrentPage = 1;
      $scope.queryStartOffset = 1;
      $scope.queryTotalCount = 0;
      $scope.queryResults = [];
      $scope.queryPageCount = 1;
      $scope.genericQueryError = "";
      $scope.queryLoadError = "";

      // List view parameters
      $scope.viewCurrentPage = 1;
      $scope.viewStartOffset = 1;
      $scope.viewTotalCount = 0;
      $scope.viewResults = [];
      $scope.viewPageCount = 1;
      $scope.viewQueryError = "";
      $scope.viewGenericError = "";
      $scope.viewLoadError = "";

      $scope.displayViews = false;
      $scope.views = [];

      $scope.startOffset = 1;
      $scope.results = [];
      $scope.totalCount = 0;
      $scope.selectedQueryName = ""
      $scope.selectedDocType = ""

      $scope.$watch('queryCurrentPage', function(page){
          if ( page == $scope.queryCurrentPage ) {
              return
          }
          $scope.loadQueries()
      });

      $scope.$watch('viewCurrentPage', function(page){
          if ( page == $scope.viewCurrentPage ) {
              return
          }
          if ( $scope.selectedQueryName.length() == 0 || $scope.selectedQueryName.selectedDocType.length == 0) {
              return
          }
          $scope.loadViews()
      });

      $scope.createNewQuery = function() {
          $state.go('adhoc-wizard');
      }

      $scope.editQuery=function(docType,queryName) {
          $state.go('adhoc-wizard-field-selection', {deparams: {docType:docType,queryName: queryName,queryView: "query"}})
      }

      $scope.showViews=function(queryName,docType,event) {
         $scope.displayViews = true;
         $scope.selectedQueryName = queryName
         $scope.selectedDocType = docType
         $scope.loadViews();
      }

      $scope.removeView=function(queryName,docType,viewName,ev) {
          if (confirm('Do you want to remove view '+ viewName + '?')) {
              crudService.removeView(queryName,docType,viewName)
                  .success(function (data, status) {
                      if (status == 200) {
                          $scope.genericViewError = "";
                          $scope.viewCurrentPage = 1;
                          $scope.viewStartOffset = 1;
                          $scope.loadViews()
                      }
                  }).error(function (err) {
                  $scope.genericViewError = "Error during removing query "+name+". An error occurred. check the log.";
              });
          } else {
              $scope.genericViewError = ""
          }
      }

      $scope.removeQuery=function(name,docType,ev) {
          if (confirm('Do you want to remove query '+ name + '?')) {
              crudService.removeQuery(name,docType)
                  .success(function (data, status) {
                      if (status == 200) {
                          $scope.queryGenericError = "";
                          $scope.queryCurrentPage = 1;
                          $scope.queryStartOffset = 1;
                          $scope.viewCurrentPage = 1;
                          $scope.viewStartOffset = 1;
                          $scope.viewTotalCount = 0;
                          $scope.viewResults = [];
                          $scope.viewPageCount = 1;
                          $scope.loadQueries()
                      }
                  }).error(function (err) {
                  $scope.queryGenericError = "Error during removing query "+name+". An error occurred. check the log.";
              });
          } else {
              $scope.queryGenericError = ""
          }
      }

      $scope.loadQueries=function() {
          $scope.queryLoadError = '';
          var offset = (($scope.queryCurrentPage-1) * $scope.PAGE_SIZE)+1
          crudService.listQueries(offset,$scope.PAGE_SIZE)
              .success(function(data, status) {
                  if (status == 200) {
                      $scope.queryTotalCount = data['result-count']
                      $scope.queryResults = data['queries']
                      $scope.queryPageCount = Math.ceil( $scope.queryTotalCount / $scope.PAGE_SIZE)
                  }
              }).error(function(err){
                  $scope.queryResults = []
                  $scope.queryLoadError = "An server error occurred. Check the log.";
          });
      }

      $scope.loadViews=function() {
          var offset = (($scope.viewCurrentPage-1) * $scope.PAGE_SIZE)+1
          crudService.listViews($scope.selectedQueryName,$scope.selectedDocType,offset,$scope.PAGE_SIZE)
              .success(function (data, status) {
                  if (status == 200) {
                      $scope.genericQueryError = "";
                      $scope.viewResults = data.views
                      $scope.viewTotalCount = data['result-count']
                      $scope.viewPageCount = Math.ceil( $scope.viewTotalCount / $scope.PAGE_SIZE)
                  }
              }).error(function (err) {
              $scope.genericViewError = "Error during loading views for query "+$scope.selectedQueryName+". An error occurred. check the log.";
          });
      }

      $scope.loadQueries()
    }
  );