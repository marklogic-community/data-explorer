'use strict';

angular.module('demoApp')
  .controller('DetailCtrl', function ($scope, $http, $stateParams, $sce, Detail, $window, AdhocState) {

    // Detect the back button being pushed
    $scope.$on("$locationChangeStart",function(){
      if($window.event.target.location.pathname === '/adhoc') {
        AdhocState.setDisplayLastResults(true);
      }
    });

    $scope.database = $stateParams.database;
    $scope.uri      = $stateParams.uri;
    $scope.prettyXML = '';

    $scope.details = Detail.get({database:$scope.database,uri:$scope.uri},function(details){
      $scope.doc = details;
      $scope.prettyXML = vkbeautify.xml($scope.doc.xml);
    });

    $scope.to_trusted = function(html_code) {
        return $sce.trustAsHtml(html_code);
    };
  });
