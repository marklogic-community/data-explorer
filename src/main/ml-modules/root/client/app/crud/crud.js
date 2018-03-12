'use strict';

angular.module('demoApp')
  .config(function ($stateProvider) {
    $stateProvider
      .state('crud', {
        url: '/crud',
        templateUrl: 'app/crud/crud.html',
        controller: 'CrudCtrl',
        authenticate: true
      });
  });