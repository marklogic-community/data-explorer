'use strict';

angular.module('demoApp')
  .controller('SettingsCtrl', function ($scope, User, Auth) {
    $scope.errors = {};

    $scope.changePassword = function(form) {
      $scope.submitted = true;
      if(form.$valid) {
        Auth.changePassword( $scope.user.newPassword, $scope.user.newPasswordConfirm )
        .then( function() {
          $scope.message = 'Password successfully changed.';
        })
        .catch( function() {
          form.password.$setValidity('othererror', false);
          $scope.errors.other = 'Password failed to change';
          $scope.message = '';
        });
      }
		};
  });
