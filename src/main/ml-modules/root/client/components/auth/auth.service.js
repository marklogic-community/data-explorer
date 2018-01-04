'use strict';

angular.module('demoApp')
  .factory('Auth', function Auth($location, $rootScope, $http, User, $cookieStore, $q) {
    var currentUser = {};
    var homeMessage;
    if($cookieStore.get('token')) {
      currentUser = User.get();
    }
    
    return {

      /**
       * Authenticate user and save token
       *
       * @param  {Object}   user     - login info
       * @param  {Function} callback - optional
       * @return {Promise}
       */
      login: function(user, callback) {
        var cb = callback || angular.noop;
        var deferred = $q.defer();
        $http({
          method:'POST',
          url: '/auth',
          data: $.param({
              userid: user.userid,
              password: user.password
            }),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'}
        }).
        success(function(data) {
          $cookieStore.put('token', 'loggedin');
          currentUser = User.get();
          deferred.resolve(data);
          return cb();
        }).
        error(function(err) {
          this.logout();
          deferred.reject(err);
          return cb(err);
        }.bind(this));

        return deferred.promise;
      },

      /**
       * Delete access token and user info
       *
       * @param  {Function}
       */
      logout: function() {
        $http({
          method:'POST',
          url: '/deauth'
        }).
        success(function(data) {
          $cookieStore.remove('token');
          currentUser = {};
        }).
        error(function(err) {
          console.log("failed to logout...");
        }.bind(this));
        
      },

      /**
       * Create a new user
       *
       * @param  {Object}   user     - user info
       * @param  {Function} callback - optional
       * @return {Promise}
       */
      createUser: function(user, callback) {
        var cb = callback || angular.noop;

        return User.save(user,
          function(data) {
            $cookieStore.put('token', data.token);
            currentUser = User.get();
            return cb(user);
          },
          function(err) {
            this.logout();
            return cb(err);
          }.bind(this)).$promise;
      },

      /**
       * Change password
       *
       * @param  {String}   newPassword
       * @param  {String}   newPasswordConfirm
       * @param  {Function} callback    - optional
       * @return {Promise}
       */
      changePassword: function(newPassword, newPasswordConfirm, callback) {
        var cb = callback || angular.noop;

        return User.changePassword({ id: 'me' }, $.param({
          newpassword: newPassword,
          newpasswordconfirm: newPasswordConfirm
        }), function(user) {
          return cb(user);
        }, function(err) {
          return cb(err);
        }).$promise;
      },

      /**
       * Gets all available info on authenticated user
       *
       * @return {Object} user
       */
      getCurrentUser: function() {
        if (currentUser.hasOwnProperty('user'))
        {
          return currentUser.user;
        }
        else
        {
          return currentUser;
        }
        
      },

      /**
       * Check if a user is logged in
       *
       * @return {Boolean}
       */
      isLoggedIn: function() {
        if (currentUser.hasOwnProperty('user') && currentUser.user.hasOwnProperty('role')){
          return true;
        }
        return false;
      },

      /**
       * Waits for currentUser to resolve before checking if user is logged in
       */
      isLoggedInAsync: function(cb) {
        if(currentUser.hasOwnProperty('$promise')) {
          currentUser.$promise.then(function() {
            cb(true);
          }).catch(function() {
            cb(false);
          });
        } else if(currentUser.hasOwnProperty('user') && currentUser.user.hasOwnProperty('role')) {
          cb(true);
        } else {
          cb(false);
        }
      },

      /**
       * Check if a user is an admin
       *
       * @return {Boolean}
       */
      isWizardUser: function() {
        return currentUser.hasOwnProperty('user') && currentUser.user.role === 'wizard-user';
      },

      isSearchUser: function() {
        return currentUser.hasOwnProperty('user') && currentUser.user.role === 'search-user';
      },

      /**
       * Get auth token
       */
      getToken: function() {
        return $cookieStore.get('token');
      }
    };
  });
