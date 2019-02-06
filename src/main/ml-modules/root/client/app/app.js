'use strict';

angular.module('demoApp', [
    'ngCookies',
    'ngResource',
    'ngSanitize',
    'ui.router',
    'ui.bootstrap',
    'angular-sortable-view'
  ])
  .config(function($stateProvider, $urlRouterProvider, $locationProvider, $httpProvider) {
    $urlRouterProvider
      .otherwise('/');

    $locationProvider.html5Mode(true);
    $httpProvider.interceptors.push('authInterceptor');
  })

.factory('authInterceptor', function($rootScope, $q, $cookieStore, $location) {
  return {
    // Add authorization token to headers
    request: function(config) {
      config.headers = config.headers || {};
      if ($cookieStore.get('token')) {
        config.headers.Authorization = 'Bearer ' + $cookieStore.get('token');
      }
      return config;
    },

    // Intercept 401s and redirect you to login
    responseError: function(response) {
      if (response.status === 401) {
        // remove any stale tokens
        $cookieStore.remove('token');
        $rootScope.message = "Login failure. Please log in.";
        $location.path('/login');

        return $q.reject(response);
      } else {
        return $q.reject(response);
      }
    }
  };
})

// Allow retention of the search form state to navigate back to results
.service('AdhocState', function() {
  var _formState = {};
  var _displayLastResults = false;
  var _savedFields = [
    'selectedDatabase',
    'selectedDocType',
    'selectedQuery',
    'selectedView',
    'databases',
    'doctypes',
    'queries',
    'views',
    'message',
    'searchText',
    'queryCurrentPage'
  ];

  this.setPage = function(page) {
    _formState.queryCurrentPage = page;
  };

  this.save = function($scope) {
    _formState = {};
    for(var i = 0; i < _savedFields.length; i++) {
      _formState[_savedFields[i]] = $scope[_savedFields[i]]
    }
    _formState.inputField = {};
    for(var i = 0; i <= 15; i++) {
      _formState.inputField[i] = $scope.getField(i);
    }
      _formState.textFields = _.cloneDeep($scope.textFields)
  };

  this.restore = function($scope) {
    if(!_displayLastResults) {
      // Reset the form state
      _formState = {};
      _formState.inputField = {};
      for(var i = 0; i < 15; i++) {
        _formState.inputField[i] = '';
      }
    }
    for(var i = 0; i < _savedFields.length; i++) {
      $scope[_savedFields[i]] = typeof _formState[_savedFields[i]] !== undefined ? _formState[_savedFields[i]] : '';
    }
    $scope.queryCurrentPage = _formState.queryCurrentPage ? _formState.queryCurrentPage : 1;
    $scope.inputField  = _formState.inputField
    if ( !$scope.inputField ) {
      $scope.inputField = []
      for ( var i = 0 ; i < 15 ;i++ ) {
        $scope.inputField.push("");
      }
    }
      $scope.textFields = _formState.textFields || []
    _displayLastResults = false;
  };

  this.setDisplayLastResults = function(display) {
    _displayLastResults = display;
  };

  this.getDisplayLastResults = function() {
    return _displayLastResults;
  }

})

// Activate tooltips
.directive('tooltip', function(){
  return {
    restrict: 'A',
    link: function(scope, element, attrs){
      element.tooltip({placement: attrs.placement});
      element.hover(function(){
        element.tooltip('show');
      }, function(){
        element.tooltip('hide');
      });
    }
  };
})

.run(function($rootScope, $location, Auth) {
  // Redirect to login if route requires auth and you're not logged in
  $rootScope.$on('$stateChangeStart', function(event, next) {
    Auth.isLoggedInAsync(function(loggedIn) {
      if (next.authenticate && !loggedIn) {
        $location.path('/login');
      }
    });
  });
});