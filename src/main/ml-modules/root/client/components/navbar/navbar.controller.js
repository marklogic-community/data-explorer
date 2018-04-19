'use strict';

angular.module('demoApp')
  .controller('NavbarCtrl', function($rootScope, $location, Auth, $cookieStore,$http,$state) {
    $rootScope.bookmarks=[]

    $rootScope.menu = [{
      'title': 'Home',
      'state': 'main'
    }]
    $rootScope.dataExplorerMenu = [{
      'title': 'Search',
      'state': 'adhoc'
    }];

    $rootScope.goState = function(state) {
        $state.go(state)
    }

    $rootScope.openBookmark=function(database,queryName,docType,viewName) {
        $state.go('adhoc', {deparams: {
            "database":database,
            "queryName":queryName,
            "docType" : docType,
            "viewName" : viewName }
        });
    }

    $rootScope.loadBookMarks=function() {
        $rootScope.bookmarks=[]

        if ($rootScope.isWizardUser || $rootScope.isSearchUser) {
            $http.get('/api/listBookmarks', {
                params: {
                }
            }).success(function (data, status) {
                  if (status == 200) {
                      $rootScope.bookmarks=data.bookmarks
                  }
              }).error(function (err) {
                  console.log(err)
              });
        }
     }

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
        $rootScope.loadBookMarks()
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