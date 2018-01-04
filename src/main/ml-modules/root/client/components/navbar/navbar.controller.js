'use strict';

angular.module('demoApp')
  .controller('NavbarCtrl', function($rootScope, $location, Auth, $cookieStore) {
    $rootScope.menu = [{
      'title': 'Home',
      'link': '/'
    }]
    $rootScope.dataExplorerMenu = [{
      'title': 'Search',
      'link': '/adhoc'
    }];

    $rootScope.isCollapsed = true;

    $rootScope.$watch(function() {
      return $cookieStore.token;
    }, function(newValue) {
      if ($cookieStore.get('token') == null) {
        Auth.currentUser = {};
        $rootScope.isLoggedIn = false;
        $rootScope.isWizardUser = false;
        $rootScope.isSearchUser = false;
        $rootScope.getCurrentUser = false;
        $rootScope.dataExplorerMenu = [];
      } else {
        $rootScope.isLoggedIn = Auth.isLoggedIn;
        $rootScope.isWizardUser = Auth.isWizardUser;
        $rootScope.isSearchUser = Auth.isSearchUser;
        $rootScope.getCurrentUser = Auth.getCurrentUser;
      }
    });

    $rootScope.logout = function() {
      Auth.logout();
      $location.path('/login');
    };

    $rootScope.isActive = function(route) {
      return route === $location.path();
    };
  });