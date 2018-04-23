'use strict';

angular.module('demoApp')
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

      $scope.editView = function(docType,queryName,viewName,event) {
              $state.go('adhoc-wizard-field-selection',
                  {deparams: {
                          docType:docType,
                          queryName: queryName,
                          viewName : viewName,
                          queryView: "view"}})
      }

      $scope.editQuery=function(docType,queryName) {
          $state.go('adhoc-wizard-field-selection',
              {deparams: {
                  docType:docType,
                  queryName: queryName,
                  queryView: "query"}})
      }

      $scope.showViews=function(queryName,docType,event) {
         $scope.displayViews = true;
         $scope.selectedQueryName = queryName
         $scope.selectedDocType = docType
         $scope.loadViews();
      }

      $scope.removeView=function(queryName,docType,viewName,ev) {
        $scope.confirmMessage = 'Are you sure you wish to remove the view: ' + viewName + '?';
        $scope.confirmType = 'view';
        $scope.confirmParams = {
          queryName: queryName,
          docType: docType,
          viewName: viewName
        }
        $("#confirmModal").modal();
      }

      $scope.confirmRemoveView=function() {
        $("#confirmModal").modal("hide");
        crudService.removeView($scope.confirmParams.queryName, $scope.confirmParams.docType, $scope.confirmParams.viewName)
          .success(function (data, status) {
            if (status == 200) {
              $scope.genericViewError = "";
              $scope.viewCurrentPage = 1;
              $scope.viewStartOffset = 1;
              $scope.loadViews()
            }
          }).error(function (err) {
            $scope.genericViewError = "Error during removing query " + $scope.confirmParams.viewName + ". An error occurred. check the log.";
        });
      }

      $scope.removeQuery=function(name,docType,ev) {
        $scope.confirmMessage = 'Are you sure you wish to remove the query: ' + name + '?';
        $scope.confirmType = 'query';
        $scope.confirmParams = {
          name: name,
          docType: docType
        }
        $("#confirmModal").modal();
      }

      $scope.confirmRemoveQuery=function() {
        $("#confirmModal").modal("hide");
        crudService.removeQuery($scope.confirmParams.name, $scope.confirmParams.docType)
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
              $scope.displayViews = false;
            }
          }).error(function (err) {
            $scope.queryGenericError = "Error removing query: " + $scope.confirmParams.name + ". Please check the log.";
        });
      }

      $scope.noConfirm = function() {
        $scope.queryGenericError = ""
        $("#confirmModal").modal("hide");
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