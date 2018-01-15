'use strict';

angular.module('demoApp')
  .controller('AdhocWizardCtrl', function ($scope, $http, $sce, $interval) {

    $scope.step = 1;
    $scope.wizardForm;
    $scope.wizardResults = '';
    $scope.queryView = 'query';
    $scope.uploadButtonActive = false;
    $scope.message = "Choose a file and mode and press submit.";
    $scope.messageClass = "form-group";

    $scope.formInput = {};
    $scope.formInput.selectedDatabase = '';
    $scope.formInput.queryViewName = '';

    $scope.inputField = {};

    $scope.isNamespaceAware = true;
    $scope.showNamespaces = false;
    $scope.filename = '';
    $scope.fileType = 0;

    $scope.toggleNamespaces = function() {
    	$scope.showNamespaces = !$scope.showNamespaces;
    }

    $scope.to_trusted = function(html_code) {
        return $sce.trustAsHtml(html_code);
    };

    // $http.get('/api/wizard/upload-form').success(function(data, status, headers, config) {
    //   if (status == 200){
    //     $scope.uploadForm = data;
    //   }
    // });

    $scope.wizardUploadFormData = null;

    $scope.changeFile = function(files) {
        if (files.length > 0){
        	// kind of hacky, but the event wasn't triggering a digest cycle so the 
        	// screen wasn't updated with the file name
        	$interval(function() {
            	$scope.filename = files[0].name;
        	},300, 1);
            $scope.wizardUploadFormData = new FormData();
            //Take the first selected file
            var fileMimeType = files[0]['type'];
            if ( !isSupportedFileType(fileMimeType) ) {
                $scope.message = "This file-type is not supported. Choose a different file.";
                $scope.uploadButtonActive = false;
                $scope.messageClass = "form-group has-error";
            } else {
                $scope.message = "Select the desired mode and press the create button";
                $scope.wizardUploadFormData.append("uploadedDoc", files[0]);
                $scope.wizardUploadFormData.append("mimeType", files[0]['type']);
                $scope.messageClass = "form-group"
                $scope.uploadButtonActive = true;
            }
        }
        else
        {
            $scope.wizardUploadFormData = null;
            $scope.uploadButtonActive = false;
        }

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

    $scope.upload = function(){
        if ($scope.wizardUploadFormData == null){
            $scope.message = 'Please choose a file using the browse button.';
            return;
        }
        $scope.wizardUploadFormData.append('type',$scope.queryView);
        var fileMimeType = $scope.wizardUploadFormData.get('mimeType');
        $scope.isNamespaceAware = isNamespaceAwareMimeType(fileMimeType)
        $scope.fileType = getFileType(fileMimeType)
        if ( !isSupportedFileType(fileMimeType) ) {
              $scope.message = "This file-type is not supported. Choose a different file";
              $scope.uploadButtonActive = false;
        } else {
            $http.post('/api/wizard/upload', $scope.wizardUploadFormData, {
                withCredentials: true,
                headers: {'Content-Type': undefined },
                transformRequest: angular.identity
            }).success(function(data, status){
                if (status == 200){
                    $scope.step = 2; 
                    $scope.wizardForm = data;
                    for(var index = 0; index < data.fields.length; index++){
                    	data.fields[index].include = false;
                    	data.fields[index].includeMode = "none";
                    	data.fields[index].defaultTitle = createTitle(data.fields[index].elementName);
                    }                    
                }
            }).error(function(err){
               console.log(err);
               $scope.message = "An error occurred. Check the browser console log for details.";
               $scope.messageClass = "form-group has-error";
             });
        }
    };

    
    $scope.validForm = function() {
    	if($scope.formInput.queryViewName == ''){
    		return false;
    	}
    	if($scope.wizardForm.rootElement == ''){
    		return false;
    	}
    	if($scope.formInput.selectedDatabase == ''){
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
    

    $scope.submitWizard = function(){
        var data = {};
        data.queryText = '';
        data.prefix = $scope.wizardForm.prefix;
        data.rootElement = $scope.wizardForm.rootElement;

        data.database = $scope.formInput.selectedDatabase;
        data.fileType =  $scope.fileType;
        if ($scope.wizardForm.type.toLowerCase() === 'query'){
            data.queryName = $scope.formInput.queryViewName;

            var counter = 1;
            for (var i = 1; i <= $scope.wizardForm.fields.length; i++){
            	if($scope.wizardForm.fields[i-1].include){
            		data['formLabel'+counter] = $scope.wizardForm.fields[i-1].title;
            		data['formLabelHidden'+counter] = $scope.wizardForm.fields[i-1].xpathNormal;
            		data['formLabelDataType'+counter] = $scope.wizardForm.fields[i-1].dataType;
            		data['formLabelIncludeMode' + counter] = $scope.wizardForm.fields[i-1].includeMode;
            		counter += 1;
            	}
            }
        }
        else
        {
            data.viewName = $scope.formInput.queryViewName;

            var counter = 1;
            for (var i = 1; i <= $scope.wizardForm.fields.length; i++){
            	if($scope.wizardForm.fields[i-1].include){
	                data['columnName'+counter] = $scope.wizardForm.fields[i-1].title;
	                data['columnExpr'+counter] = $scope.wizardForm.fields[i-1].xpathNormal;
            		data['columnDataType'+counter] = $scope.wizardForm.fields[i-1].dataType;
	        		data['columnIncludeMode' + counter] = $scope.wizardForm.fields[i-1].includeMode;
	        		counter += 1;
            	}
            }
        }
        console.log('sending...');
        console.dir(data);
        $http.get('/api/wizard/create',{
            params:data
        }).success(function(data, status, headers, config) {
            $scope.wizardResults = data;
            $scope.step = 3;
        }).error(function(data, status){
            if (status == 500){
              $scope.wizardResults = "Server Error, please make changes and try again";
            }
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
