(function() {
  'use strict';

  angular.module('demoApp')
    .factory('wizardService', WizardService);

  WizardService.$inject = ['$http', 'Auth'];

  function WizardService($http, Auth) {
    var service = {};

    service.listDocTypes = function(database) {
      return $http.get('/api/wizard/doctypes', {
        params: {
          database: database
        }
      })
      .then(function(response) {
        if (response.status === 200 && response.data.docTypes && _.isArray(response.data.docTypes)) {
          return response.data.docTypes;
        }
        else if (response.status === 401) {
          console.log('Not logged in.  Unable to list databases.');
          Auth.logout();
        }
        return [];
      });
    };

    return service;
  }

}());
