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
    $scope.tabheading = '';
    $scope.details = Detail.get({database:$scope.database,uri:$scope.uri},function(details){
      $scope.doc = details;
      if ( $scope.doc.mimetype == "application/json") {
        $scope.prettyData = vkbeautify.json($scope.doc.data)
        $scope.tabheading = "JSON View";
      } else {
        $scope.prettyData = vkbeautify.xml($scope.doc.data);
        $scope.tabheading = "XML View";
      }
    });

    $scope.to_trusted = function(html_code) {
        return $sce.trustAsHtml(html_code);
    };
  });
