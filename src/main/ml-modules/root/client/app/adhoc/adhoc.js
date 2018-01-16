'use strict';

angular.module('demoApp')
  .config(function ($stateProvider) {
    $stateProvider
      .state('adhoc', {
        url: '/adhoc',
        templateUrl: 'app/adhoc/adhoc.html',
        controller: 'AdhocCtrl',
        controllerAs: 'ctrl',
        authenticate: true
      });
  });