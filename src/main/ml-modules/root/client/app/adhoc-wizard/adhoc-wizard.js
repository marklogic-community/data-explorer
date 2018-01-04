'use strict';

angular.module('demoApp')
  .config(function ($stateProvider) {
    $stateProvider
      .state('adhoc-wizard', {
        url: '/wizard',
        templateUrl: 'app/adhoc-wizard/adhoc-wizard.html',
        controller: 'AdhocWizardCtrl',
        authenticate: true
      });
  });