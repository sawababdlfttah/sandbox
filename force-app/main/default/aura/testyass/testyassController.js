({
    handleUserChange : function(component, event, helper) {
        var selectedUserId = event.getParam("value");

        var action = component.get("c.getUserNum");
        action.setParams({ "userId" : selectedUserId });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.champ1Value", response.getReturnValue());
            } else {
                console.error("Error fetching user number:", state);
            }
        });
        $A.enqueueAction(action);
    }
})