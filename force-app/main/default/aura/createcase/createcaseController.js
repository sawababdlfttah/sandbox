({
    initComponent: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var pageReference = component.get("v.pageReference");
        
        if (pageReference) {
            var state = pageReference.state;
            var parentId = state.c__parentId;
            if (parentId) {
                recordId = parentId;
            }
        }
        
        if (recordId) {
            component.set("v.parentCaseId", recordId);
            component.set("v.isRelatedCase", true);
            helper.fetchParentCaseDetails(component, recordId);
        }
    },
    
    createCase: function(component, event, helper) {
        helper.createCaseHelper(component);
    }
})