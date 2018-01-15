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
    $scope.prettyData = '';

    $scope.details = Detail.get({database:$scope.database,uri:$scope.uri},function(details){
      $scope.doc = details;
      console.log("ADDA3");
      console.log($scope.doc.mimetype);
      if ( $scope.doc.mimetype = "application/json") {
        console.log($scope.doc.data);
        $scope.prettyData = vkbeautify.json($scope.doc.data)
      } else {
        $scope.prettyData = vkbeautify.xml($scope.doc.data);
      }
    });

    $scope.to_trusted = function(html_code) {
        return $sce.trustAsHtml(html_code);
    };
  });
