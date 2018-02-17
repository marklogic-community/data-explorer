'use strict';

angular.module('demoApp')
  .config(function ($stateProvider) {
    $stateProvider
      .state('adhoc-wizard', {
        url: '/wizard/:queryView/:name',
        templateUrl: 'app/adhoc-wizard/adhoc-wizard.html',
        controller: 'AdhocWizardCtrl',
        authenticate: true
      });
  });