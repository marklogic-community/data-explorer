'use strict';

angular.module('demoApp')
  .controller('LoginCtrl', function ($scope, $http, Auth, $location, $window) {
    $scope.user = {};
    $scope.errors = {};
    Auth.homeMessage = "";
    
    $scope.login = function(form) {
      $scope.submitted = true;

      if(form.$valid) {
        Auth.login({
          userid: $scope.user.userid,
          password: $scope.user.password
        })
        .then( function() {
          $http.get('/api/checkTemplates').success(function(data, status, headers, config) {
            if (status == 200) {
              if(!data.queryTemplateExists) {
                if(data.isSearchUser) {
                  Auth.homeMessage = "<span class=\"alert alert-warning\">There are no queries to search. Please contact the Data Explorer admin (Wizard User) to create queries.</span>";
                } else if(data.isWizardUser) {
                  Auth.homeMessage = "<span class=\"alert alert-warning\">There are no queries to search. Please use <a href=\"/crud\">Edit Config</a> to define queries and views.</span>";
                }
                Auth.noQueries = true;
                $location.path('/');
              }
              else if(data.queryTemplateExists && data.isSearchUser)
                $location.path('/adhoc');
              else 
                $location.path('/');
            }
          });
        })
        .catch( function(err) {
          var errorMessage = 'Error please try again. -- ' + err.message + ' -- ' + err.response.message;
          if (typeof(err) === 'undefined' || err.message === ''){
            errorMessage = err.message;
          }
          $scope.errors.other = errorMessage;
          if($scope.message) {
           $scope.errors.message = $scope.message;
        }
        });
      }
    };
  });
