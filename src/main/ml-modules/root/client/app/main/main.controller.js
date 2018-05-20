'use strict';

angular.module('demoApp')
  .controller('MainCtrl', function ($scope, $http, Auth) {
    $http.get('assets/version.js').then(function(response) {
      $scope.versionNumber = 'v' + response.data.version;
    });
  	$scope.homeMessage = Auth.homeMessage;
  });
