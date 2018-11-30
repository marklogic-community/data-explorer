'use strict';

angular.module('demoApp')
  .controller('AdhocWizardFieldSelectionCtrl', function ($rootScope, $state, $scope, $http, $window, $stateParams, $sce, $interval, databaseService, wizardService) {
    // Retrieve state from local storage if state params are not passed.
    var state = $stateParams.deparams || JSON.parse($window.localStorage.getItem('deparams'));
    if (state) {
      $scope.wizardForm = state.formData;
      $scope.queryView = state.queryView;
      $scope.loadDocType = state.docType;
      if ( state.formData ) {
         $scope.database = state.formData.database;
      }
      $scope.loadViewName = state.viewName;
      $scope.loadQueryName = state.queryName;
      $scope.backState = state.backState;
      // Store the state in local storage in case of refresh.
      $window.localStorage.setItem('deparams', JSON.stringify(state));
    } else {
      // Something happened and the state was lost. Kick the user back to the crud page.
      $state.go('crud');
      return;
    }
    if ( !$scope.backState) {
        $scope.backState = 'crud'
    }
    $scope.wizardResults = '';
    $scope.wizardTitle = $scope.queryView == "query" ? "Edit Query" : "Edit view for Query"
    $scope.viewTitle = $scope.queryView == "query" ? "Query search fields and default view" : "View information"

    $scope.editMode = !(!$scope.loadQueryName || !$scope.loadDocType)
    $scope.insertView = $scope.editMode && $scope.queryView == "view" && $scope.loadViewName.length == 0
    $scope.updateView = $scope.editMode && $scope.queryView == "view" && $scope.loadViewName.length > 0
    $scope.insertQuery = $scope.queryView == "query" && $scope.editMode == false
    $scope.buttonText = ($scope.insertView || $scope.insertQuery) ? "Save" : "Update";
    $scope.uploadButtonActive = false;
    $scope.message = "";
    $scope.messageClass = "form-group";
    $scope.noResultsMessage="";
    $scope.formInput = {};
    $scope.formInput.bookmarkCheck=false;
    $scope.formInput.bookmarkLabel="";
    $scope.formInput.collectionFilter = state.collectionFilter;
    $scope.formInput.queryName = '';
    $scope.format="Undefined"
    if ( state.formData && state.formData.fileType ) {
        $scope.fileType = state.formData.fileType;
        if ($scope.fileType == "0" ) {
            $scope.format = "XML"
        } else if ($scope.fileType == "1" ) {
            $scope.format = "JSON"
        }
    }
    $scope.formInput.startingDocType = '';
    $scope.displayOrder = 'alphabetical';
    $scope.inputField = {};

    $scope.isNamespaceAware = true;
    $scope.showNamespaces = false;
    $scope.filename = '';
    $scope.$watch('wizardForm.rootElement', function(value) {
    		if($scope.wizardForm && $scope.wizardForm.allFields){
    			var modifiedFields=[];        		
    			for(var index = 0; index < $scope.wizardForm.allFields.length; index++){
    				var field=$scope.wizardForm.allFields[index];
    	            if(field.xpathNormal.startsWith(value)){
    	            		modifiedFields.push(field);
    	            }
    	        }
    	    		$scope.wizardForm.fields=modifiedFields;	
    		}
    });
      databaseService.list().then(function(data) {
          var databases = [];
          for (var key in data) {
              databases.push(JSON.parse(data[key]));
          }
          $scope.availableDatabases = databases;
          $scope.formInput.selectedDatabase = $scope.database;
          if ( $scope.editMode ) {
              wizardService.getQueryView($scope.loadQueryName, $scope.loadDocType,$scope.loadViewName)
                  .success(function (data, status) {
                      if (status == 200) {
                          $scope.wizardForm={}
                          $scope.wizardForm.rootElement=data.rootElement
                          $scope.formInput.queryName=data.queryName
                          if ( !(!$scope.loadViewName && $scope.queryView == "view") && data.bookmarkLabel ) {
                              $scope.formInput.bookmarkCheck=true;
                              $scope.formInput.bookmarkLabel=data.bookmarkLabel;
                          } else {
                              $scope.formInput.bookmarkCheck=false;
                              $scope.formInput.bookmarkLabel="";
                          }
                          if ( !$scope.insertView ) {
                              $scope.formInput.viewName = data.viewName
                          }
                          if ( data.database ) {
                              $scope.formInput.selectedDatabase = data.database
                          }
                          $scope.format="Undefined"
                          $scope.fileType=data.fileType
                          if ( $scope.fileType ) {
                              if ($scope.fileType == "0" ) {
                                  $scope.format = "XML"
                              } else if ($scope.fileType == "1" ) {
                                  $scope.format = "JSON"
                              }
                          }
                          $scope.displayOrder = data.displayOrder
                          $scope.formInput.collectionFilter=data.collections;
                          $scope.wizardForm.possibleRoots=data.possibleRoots
                          $scope.wizardForm.namespaces=data.namespaces
                          $scope.wizardForm.fields=data.fields
                          for(var index = 0; index < $scope.wizardForm.fields.length; index++){
                              $scope.wizardForm.fields[index].defaultTitle = createTitle(data.fields[index].elementName);
                              if (  !$scope.loadViewName && $scope.queryView == "view" ) {
                                  $scope.wizardForm.fields[index].includeMode = 'none'
                                  $scope.wizardForm.fields[index].title = '';
                              }
                              $scope.wizardForm.fields[index].include = $scope.wizardForm.fields[index].includeMode != 'none'
                          }
                      }
                  }).error(function (err) {
                  console.log(err)
              });
          }
          else{
        	  	  if($scope.wizardForm.fields) {
        	  	   	$scope.wizardForm.allFields=$scope.wizardForm.fields.slice(0);
        	  	  }
          }
      });

    $scope.toggleNamespaces = function() {
    	$scope.showNamespaces = !$scope.showNamespaces;
    }

    $scope.to_trusted = function(html_code) {
        return $sce.trustAsHtml(html_code);
    };

    $scope.includeChanged = function(field){
    	if(field.includeMode == "none"){
    		field.include = false;
    	}else {
    		field.include = true;
    		if(field.title == undefined || field.title.trim() == ""){
    			field.title = field.defaultTitle;
    		}
    	}
    };

    $scope.validForm = function() {
        if ( $scope.formInput.bookmarkCheck &&  !$scope.formInput.bookmarkLabel ) {
            return false;
        }
        if($scope.queryView == 'view' && !$scope.formInput.viewName  ){
            return false
        }
    	if(!$scope.formInput.queryName){
    		return false;
    	}
    	if(!$scope.wizardForm.rootElement){
    		return false;
    	}
    	if(!$scope.formInput.selectedDatabase){
    		return false;
    	}
    	// make sure they've included at least one field and it is populated with a name
    	// var fieldsChosen = 0;
    	// var invalidField = false;
     //    for (var index = 0; index < $scope.wizardForm.fields.length; index++){
     //    	if($scope.wizardForm.fields[index].include){
     //    		fieldsChosen++;
     //    	}
     //    	if($scope.wizardForm.fields[index].include && ($scope.wizardForm.fields[index].title == undefined || $scope.wizardForm.fields[index].title.trim() == "")){
     //    		invalidField = true;
     //    	}
     //    }
     //    if(fieldsChosen == 0 || invalidField){
     //    	return false;
     //    }
        	
    	return true;
    };

    // Toggle all fields selected for view based on the inverse of the first field.
    $scope.toggleAllSelected = function() {
      var fieldValues = ['none', 'both', 'query', 'view'];
      var newInclude, newIncludeMode;
      if($scope.queryView !== 'query') {
        // Views are just inverse
        newInclude = !$scope.wizardForm.fields[0].include;
        newIncludeMode = newInclude ? 'view' : 'none';
      } else {
        // Set to the next field in the array, or back to the beginning
        var pos = fieldValues.indexOf($scope.wizardForm.fields[0].includeMode) + 1;
        newIncludeMode = fieldValues[(pos > 3 ? 0 : pos)];
        newInclude = newIncludeMode === 'none' ? false : true;
      }
      for (var i = 0; i < $scope.wizardForm.fields.length; i++){
        $scope.wizardForm.fields[i].include = newInclude;
        $scope.wizardForm.fields[i].includeMode = newIncludeMode;
        $scope.wizardForm.fields[i].title = newInclude ? $scope.wizardForm.fields[i].defaultTitle : '';
      }
    };
    
    $scope.back = function() {
            $state.go($scope.backState, {});
    };

    $scope.crud = function() {
            $state.go('crud', {});
    };

    $scope.submitWizard = function(){
      if(validateParameters()){
        var data = {}
        data.bookmarkLabel = $scope.formInput.bookmarkCheck ? $scope.formInput.bookmarkLabel : "";
        data.mode = $scope.queryView
        data.overwrite = $scope.editMode ? true : false
        data.queryText = '';
        data.rootElement = $scope.wizardForm.rootElement;
        data.displayOrder = $scope.displayOrder;
        data.namespaceCount = $scope.wizardForm.namespaces.length;
        data.possibleRootsCount = $scope.wizardForm.possibleRoots.length + 1;
        if ( $scope.wizardForm.possibleRoots.length > 0 ) {
            var counter = 1;
            data['possibleRoot' + counter] = $scope.wizardForm.rootElement;
            counter += 1;
            for (var i = 1; i <= $scope.wizardForm.possibleRoots.length; i++) {
                data['possibleRoot' + counter] = $scope.wizardForm.possibleRoots[i];
                counter += 1;
            }
        }
        if ( $scope.wizardForm.namespaces.length > 0 ) {
            var counter = 1;
            for (var i = 1; i <= $scope.wizardForm.namespaces.length; i++) {
                data['namespaceAbbrv' + counter] = $scope.wizardForm.namespaces[i-1].abbrv;
                data['namespaceUri' + counter] = $scope.wizardForm.namespaces[i-1].uri;
                counter += 1;
            }
        }
        data.collections=$scope.formInput.collectionFilter;
        data.database = $scope.formInput.selectedDatabase;
        data.fileType =  $scope.fileType;
        data.queryName = $scope.formInput.queryName;
        if ($scope.queryView === 'query'){
            data.viewName = '';
        } else {
            data.viewName = $scope.formInput.viewName;
        }
        var fieldNames = [];
        var dupes = [];
        var counter = 1;
        for (var i = 1; i <= $scope.wizardForm.fields.length; i++){
          var fieldName = $scope.wizardForm.fields[i-1].title;
          // Check/record duplicate field names
          if($scope.wizardForm.fields[i-1].include) {
            if(fieldNames.indexOf(fieldName) !== -1) {
              if(dupes.indexOf(fieldName) === -1) {
                dupes.push(fieldName);
              }
            } else {
              fieldNames.push(fieldName);
            }  
          }
          
          data['formLabel'+counter] = fieldName;
          data['formLabelHidden'+counter] = $scope.wizardForm.fields[i-1].xpathNormal;
          data['formLabelDataType'+counter] = $scope.wizardForm.fields[i-1].dataType;
          data['formLabelIncludeMode' + counter] = $scope.wizardForm.fields[i-1].includeMode;
          counter += 1;
        }

        // Handle duplicate field name error
        if(dupes.length) {
          var msg = 'Fields must have unique names. Please rename the following duplicate field(s): ' + dupes.join(', ') + '.';
          renderResultsModal('error', msg);
          return;
        }

        $http.get('/api/wizard/create',{
            params:data
        }).success(function(data, status, headers, config) {
            if ( data.status === 'exists') {
              renderResultsModal('error', 'A query with this query name and document type already exists.');
            } else if ( data.status == 'dataError') {
              renderResultsModal('error', 'A data error occurred.');
            } else if ( data.status == 'saved') {
                $scope.crudResultsHeader = 'Success';
                $scope.crudResultsAlertClass = 'alert-info';
                var crudType = $scope.queryView === 'query' ? 'Query' : 'View';
                var crudAction = ($scope.insertView || $scope.insertQuery) ? ' created ' : ' updated ';
                renderResultsModal('success', crudType + crudAction + 'successfully.');
                $rootScope.noQueries = false;
            }
        }).error(function(data, status){
          renderResultsModal('error', 'Server Error. Please try again later.');
        });
      }
    };

    // validate form parameters and display issues with form if any exist (right now for making sure one output field is selected)
    function validateParameters() {
      var includedField = false;
      // go through all included fields to check if at least on is an output field
      for (var index = 0; index < $scope.wizardForm.fields.length; index++){
        if($scope.wizardForm.fields[index].include && $scope.wizardForm.fields[index].title != undefined && $scope.wizardForm.fields[index].title.trim() != ""){
          if(isOutputField($scope.wizardForm.fields[index])) {
           includedField = true;
           break;
          }
        }
      }
      if(!includedField){
        var msg = "";
        if($scope.queryView === 'query'){
          msg = "A query requires at least one ouput field. Please select 'Both' or 'Results Only' for at least one field.";
        }else {
          msg = "A view requires at least one ouput field. Please select 'Yes' for at least one field.";
        }
        renderResultsModal('error', msg);
        return false;
      }
      return true;
    }

    function isOutputField(field) {
      if($scope.queryView === 'query') {
        return (field.includeMode === 'both' || field.includeMode === 'view');
      }else {
        return (field.includeMode === 'view');
      }
    }

    function renderResultsModal(type, message) {
      $scope.crudResultsAlertClass = type === 'error' ? 'alert-warning' : 'alert-info';
      $scope.crudResultsHeader = type === 'error' ? 'Error' : 'Success';
      $scope.crudResultsMessage = message;
      $("#crudResultsModal").modal();
    }
    
    function createTitle(suggestedName){
    	var namespaceDelimPos = suggestedName.indexOf(":");
    	if(namespaceDelimPos != -1){
    		return suggestedName.substr(namespaceDelimPos+1);
    	}
    	
    	return suggestedName;
    }
  });
