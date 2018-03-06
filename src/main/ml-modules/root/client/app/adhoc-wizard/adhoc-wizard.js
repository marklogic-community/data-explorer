'use strict';

angular.module('demoApp')
  .config(function ($stateProvider) {
    $stateProvider
      .state('adhoc-wizard-field-selection', {
        url: '/wizard-field-selection/',
          params: {
              deparams: null
          },
        templateUrl: 'app/adhoc-wizard/adhoc-wizard-field-selection.html',
        controller: 'AdhocWizardFieldSelectionCtrl',
        authenticate: true
      }).state('adhoc-wizard', {
        url: '/wizard-type-query',
        templateUrl: 'app/adhoc-wizard/adhoc-wizard-type-query.html',
        controller: 'AdhocWizardTypeQueryCtrl',
        authenticate: true
    });
});