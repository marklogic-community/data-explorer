'use strict';

angular.module('demoApp')
  .controller('NavbarCtrl', function($rootScope, $location, Auth, $cookieStore,$http,$state) {
    $rootScope.bookmarks=[]

    $rootScope.menu = [{
      'title': 'Home',
      'link': '/'
    }]
    $rootScope.dataExplorerMenu = [{
      'title': 'Search...',
      'link': '/adhoc////'
    }];


    $rootScope.openBookmark=function(database,queryName,docType,viewName) {
        $state.go('adhoc', {
            "database":$rootScope.tohex(database),
            "queryName":$rootScope.tohex(queryName),
            "docType" : $rootScope.tohex(docType),
            "viewName" : $rootScope.tohex(viewName)
        });
    }

    $rootScope.tohex = function(item) {
        if ( !item )
            return "";
        var r = "";
        for (var i=0; i<item.length; i++) {
            var hex = item.charCodeAt(i).toString(16);
            r += ("000"+hex).slice(-4);
        }
        return r
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