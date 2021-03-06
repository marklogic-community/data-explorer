'use strict';

angular.module('demoApp')
  .controller('LoginCtrl', function ($rootScope, $scope, $http, Auth, $location, $window) {
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
                if(data.isWizardUser) {
                  Auth.homeMessage = "<div class=\"alert alert-warning\">There are no queries to search. Please use <a href=\"/crud\">Edit Config</a> to define queries and views.</div>";
                } else {
                  Auth.homeMessage = "<div class=\"alert alert-warning\">Please contact a query maintainer who can add new queries that will show here. These users are anyone configured with the \"wizard-user\" role in MarkLogic.</div>";
                }
                $rootScope.noQueries = true;
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
