'use strict';

angular.module('demoApp')
  .controller('MainCtrl', function ($scope, $http, Auth) {
  	$scope.homeMessage = Auth.homeMessage;
  });
