({
    doInit : function(component, event, helper) {
        // Initialization logic if needed
    },

    handleFileUpload : function(component, event, helper) {
        var uploadedFiles = event.getParam("files");
        if (uploadedFiles.length > 0) {
            component.set("v.fileId", uploadedFiles[0].documentId);
            var customUrl = 'https://emsi-2d-dev-ed.develop.lightning.force.com/lightning/r/ContentDocument';
            component.set("v.fileURL", customUrl + '/' + component.get("v.fileId") + '/view');
            
            helper.showToast(component, 'Succès', 'Fichier téléchargé avec succès. Veuillez soumettre votre candidature.', 'success');
        }
    },

    submitApplication : function(component, event, helper) {
        // Validate inputs
        if (helper.validateInputs(component)) {
            var action = component.get("c.createJobApplication");
            action.setParams({
                "lastName": component.get("v.lastName"),
                "firstName": component.get("v.firstName"),
                "email": component.get("v.email"),
                "phone": component.get("v.phone"),
                "coverLetter": component.get("v.coverLetter"),
                "jobOfferId": component.get("v.jobOfferId")
            });

            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var recordId = response.getReturnValue().Id;
                    component.set("v.recordId", recordId);

                    // Optional: Set file link if file was uploaded
                    if (component.get("v.fileId")) {
                        helper.setFileLink(component, recordId);
                    }

                    helper.showToast(component, 'Succès', 'Candidature soumise avec succès!', 'success');
                    helper.resetForm(component);
                } else {
                    var errors = response.getError();
                    helper.showToast(component, 'Erreur', 
                        errors[0] ? errors[0].message : 'Erreur inconnue. Veuillez réessayer.', 
                        'error');
                }
            });

            $A.enqueueAction(action);
        }
    },

    loginWithFacebook : function(component, event, helper) {
        // Implement Facebook login logic
        helper.showToast(component, 'Information', 'Fonctionnalité Facebook non implémentée', 'info');
    },

    loginWithLinkedIn : function(component, event, helper) {
        // Implement LinkedIn login logic
        helper.showToast(component, 'Information', 'Fonctionnalité LinkedIn non implémentée', 'info');
    }
})