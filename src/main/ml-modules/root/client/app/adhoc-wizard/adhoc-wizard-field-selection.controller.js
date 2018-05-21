'use strict';

angular.module('demoApp')
  .controller('AdhocWizardFieldSelectionCtrl', function ($state,$scope, $http, $stateParams, $sce, $interval, databaseService, wizardService) {
    if ($stateParams.deparams) {
        $scope.wizardForm = $stateParams.deparams.formData;
        $scope.queryView = $stateParams.deparams.queryView;
        $scope.loadDocType = $stateParams.deparams.docType;
        $scope.loadViewName = $stateParams.deparams.viewName;
        $scope.loadQueryName = $stateParams.deparams.queryName;
        $scope.backState = $stateParams.deparams.backState;
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
    $scope.formInput.selectedDatabase = '';
    $scope.formInput.queryName = '';
    $scope.formInput.startingDocType = '';
    $scope.displayOrder = 'alphabetical';

    $scope.inputField = {};

    $scope.isNamespaceAware = true;
    $scope.showNamespaces = false;
    $scope.filename = '';
    $scope.fileType = 0;
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
          $scope.availableDatabases = data;
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
                          $scope.formInput.selectedDatabase=data.database
                          $scope.displayOrder = data.displayOrder
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
    	var fieldsChosen = 0;
    	var invalidField = false;
        for (var index = 0; index < $scope.wizardForm.fields.length; index++){
        	if($scope.wizardForm.fields[index].include){
        		fieldsChosen++;
        	}
        	if($scope.wizardForm.fields[index].include && ($scope.wizardForm.fields[index].title == undefined || $scope.wizardForm.fields[index].title.trim() == "")){
        		invalidField = true;
        	}
        }
        if(fieldsChosen == 0 || invalidField){
        	return false;
        }
        	
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
          if(!$scope.wizardForm.fields[i-1].include) {
            // Don't process fields that aren't included
            continue;
          }
          var fieldName = $scope.wizardForm.fields[i-1].title;
          // Check/record duplicate field names
          if(fieldNames.indexOf(fieldName) !== -1) {
            if(dupes.indexOf(fieldName) === -1) {
              dupes.push(fieldName);
            }
          } else {
            fieldNames.push(fieldName);
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
            }
        }).error(function(data, status){
          renderResultsModal('error', 'Server Error. Please try again later.');
        });
    };

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
