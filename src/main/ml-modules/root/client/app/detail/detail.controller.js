'use strict';

angular.module('demoApp')
  .controller('DetailCtrl', function ($state,$scope, $http, $stateParams, $sce, Detail, $window, AdhocState) {

    // Detect the back button being pushed
    $scope.$on("$locationChangeStart",function(){
      if($window.event.target.location && $window.event.target.location.pathname === '/adhoc') {
        AdhocState.setDisplayLastResults(true);
      }
    });

    // Retrieve state from local storage if state params are not passed.
    var state = $stateParams.deparams || JSON.parse($window.localStorage.getItem('deparams'));
    if (state) {
        $scope.database = state.database;
        $scope.uri = state.uri;
        $window.localStorage.setItem('deparams', JSON.stringify(state));
    } else {
      // Something happened and the state was lost. Kick the user back to the adhoc page.
      $state.go('adhoc');
      return;
    }
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

      $scope.openDetails = function(database,uri) {
          $state.go('detail',
              {deparams: {
                      database:database,
                      uri: uri}})
      };
  });
