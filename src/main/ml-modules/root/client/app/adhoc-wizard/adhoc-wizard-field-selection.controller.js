'use strict';

angular.module('demoApp')
  .controller('AdhocWizardFieldSelectionCtrl', function ($state,$scope, $http, $stateParams, $sce, $interval, databaseService, wizardService) {
    console.log($stateParams)
    $scope.wizardForm;
    $scope.wizardResults = '';
    $scope.queryView =  $stateParams.deparams.queryView;
    console.log("QueryView "+$scope.queryView);
    $scope.wizardTitle = $scope.queryView == "query" ? "Edit Query" : "Edit view for Query"
    $scope.viewTitle = $scope.queryView == "query" ? "Query search fields and default view" : "View information"
    $scope.loadDocType = $stateParams.deparams.docType;
    $scope.loadViewName = $stateParams.deparams.viewName;
    $scope.loadQueryName = $stateParams.deparams.queryName;
    console.log("QueryName "+$scope.loadQueryName);
    console.log("DocType "+$scope.loadDocType);
    $scope.editMode = $scope.loadQueryName && $scope.loadDocType
    $scope.insertView = $scope.editMode && $scope.queryView == "view" && $scope.loadViewName.length == 0
    $scope.updateView = $scope.editMode && $scope.queryView == "view" && $scope.loadViewName.length > 0
    $scope.insertQuery = $scope.queryView == "query" && $scope.editMode == false
    $scope.buttonText = ($scope.insertView || $scope.insertQuery) ? "Save..." : "Update...";
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

      databaseService.list().then(function(data) {
          $scope.availableDatabases = data;
          if ( $scope.editMode ) {
              wizardService.getQueryView($scope.loadQueryName, $scope.loadDocType,$scope.loadViewName)
                  .success(function (data, status) {
                      if (status == 200) {
                          $scope.wizardForm={}
                          $scope.wizardForm.rootElement=data.rootElement
                          $scope.formInput.queryName=data.queryName
                          if ( data.bookmarkLabel != undefined && data.bookmarkLabel.length>0) {
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
                              $scope.wizardForm.fields[index].include = $scope.wizardForm.fields[index].includeMode != 'none'
                          }
                      }
                  }).error(function (err) {
                  console.log(err)
              });
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
    	console.log("DATABASE |"+$scope.formInput.selectedDatabase+"|")
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
    
    $scope.back = function() {
            $state.go('crud', {});
    };

    $scope.submitWizard = function(){
        var data = {}
        data.bookmarkLabel = $scope.formInput.bookmarkCheck ? $scope.formInput.bookmarkLabel : "";
        data.overwrite = $scope.editMode ? "OVERWRITE" : "INSERT"
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
        var counter = 1;
        for (var i = 1; i <= $scope.wizardForm.fields.length; i++){
                data['formLabel'+counter] = $scope.wizardForm.fields[i-1].title;
                data['formLabelHidden'+counter] = $scope.wizardForm.fields[i-1].xpathNormal;
                data['formLabelDataType'+counter] = $scope.wizardForm.fields[i-1].dataType;
                data['formLabelIncludeMode' + counter] = $scope.wizardForm.fields[i-1].includeMode;
                counter += 1;
        }
        $http.get('/api/wizard/create',{
            params:data
        }).success(function(data, status, headers, config) {
            if ( data.status === 'exists') {
               alert("A query with this query name and document type already exists.");
            } else if ( data.status == 'dataError') {
               alert("A data error occurred.");
            } else if ( data.status == 'saved') {
                if ( $scope.insertView || $scope.insertQuery ) {
                    alert("Insert successful");
                } else {
                    alert("Update successful");
                }
                $state.go('crud', {});
            }
        }).error(function(data, status){
              alert("Server Error, please make changes and try again");
        });
    };
    
    function createTitle(suggestedName){
    	var namespaceDelimPos = suggestedName.indexOf(":");
    	if(namespaceDelimPos != -1){
    		return suggestedName.substr(namespaceDelimPos+1);
    	}
    	
    	return suggestedName;
    }

  });

function getFileType(mimeType) {
    if ( mimeType === "text/xml" || mimeType == "application/xml" ) {
       return 0;
    } else if ( mimeType == "application/json" ) {
           return 1;
    }
    return -1;
}
function isNamespaceAwareMimeType(mimeType) {
    return getFileType(mimeType) == 0;
}

function isSupportedFileType(mimeType) {
    return getFileType(mimeType) >= 0;
};