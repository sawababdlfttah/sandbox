({
    fetchParentCaseDetails: function(component, parentId) {
        var action = component.get("c.getParentCaseDetails");
        action.setParams({ "parentId": parentId });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var parentCase = response.getReturnValue();
                if (parentCase) {
                    component.set("v.parentCaseNumber", parentCase.CaseNumber);
                    var newCase = component.get("v.newCase");
                    newCase.ParentId = parentId;
                    component.set("v.newCase", newCase);
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    createCaseHelper: function(component) {
        var newCase = component.get("v.newCase");
        
        var action = component.get("c.saveCase");
        action.setParams({
            "newCase": newCase
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The case has been created successfully.",
                    "type": "success"
                });
                toastEvent.fire();
                
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": response.getReturnValue(),
                    "slideDevName": "detail"
                });
                navEvt.fire();
            } else if (state === "ERROR") {
                var errors = response.getError();
                var message = "Unknown error";
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": message,
                    "type": "error"
                });
                toastEvent.fire();
            }
        });
        
        $A.enqueueAction(action);
    }
})